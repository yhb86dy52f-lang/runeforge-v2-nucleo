/*
 * OverlayWindow.cpp
 * 
 * Transparent fullscreen overlay that displays AI-generated frames.
 * The overlay is click-through and excluded from screen capture to
 * avoid feedback loops when capturing the desktop.
 */

#include "OverlayWindow.h"
#include "SharedDevice.h"
#include <stdio.h>
#include <algorithm>

#pragma comment(lib, "d3d11.lib")
#pragma comment(lib, "dxgi.lib")
#pragma comment(lib, "cudart.lib")


// Simple window proc - just let Windows handle everything
LRESULT CALLBACK OverlayWindow::WndProc(HWND h, UINT msg, WPARAM w, LPARAM l) {
    return DefWindowProcW(h, msg, w, l);
}

// Stats window needs custom colors (green text on dark background)
LRESULT CALLBACK OverlayWindow::StatsWndProc(HWND h, UINT msg, WPARAM w, LPARAM l) {
    if (msg == WM_CTLCOLORSTATIC) {
        HDC hdc = (HDC)w;
        SetTextColor(hdc, RGB(0, 255, 0));
        SetBkColor(hdc, RGB(20, 20, 30));
        static HBRUSH brush = CreateSolidBrush(RGB(20, 20, 30));
        return (LRESULT)brush;
    }
    if (msg == WM_ERASEBKGND) {
        RECT rc;
        GetClientRect(h, &rc);
        HBRUSH br = CreateSolidBrush(RGB(20, 20, 30));
        FillRect((HDC)w, &rc, br);
        DeleteObject(br);
        return 1;
    }
    return DefWindowProcW(h, msg, w, l);
}

// Preview window - hide instead of close so user can re-enable it
LRESULT CALLBACK OverlayWindow::PreviewWndProc(HWND h, UINT msg, WPARAM w, LPARAM l) {
    if (msg == WM_CLOSE) {
        ShowWindow(h, SW_HIDE);
        return 0;
    }
    return DefWindowProcW(h, msg, w, l);
}


OverlayWindow::~OverlayWindow() {
    if (cudaBackBuffer) cudaGraphicsUnregisterResource(cudaBackBuffer);
    if (cudaBuffer) cudaFree(cudaBuffer);
    if (previewWnd) DestroyWindow(previewWnd);
    if (statsWnd) DestroyWindow(statsWnd);
    if (hwnd) DestroyWindow(hwnd);
}


bool OverlayWindow::Init(HMONITOR monitor) {
    if (hwnd) return true;
    
    // Get monitor size
    MONITORINFO mi = { sizeof(mi) };
    if (!GetMonitorInfoW(monitor, &mi)) return false;
    
    width = mi.rcMonitor.right - mi.rcMonitor.left;
    height = mi.rcMonitor.bottom - mi.rcMonitor.top;
    int x = mi.rcMonitor.left;
    int y = mi.rcMonitor.top;
    
    HINSTANCE inst = GetModuleHandleW(nullptr);
    
    // Register window classes once
    static bool registered = false;
    if (!registered) {
        WNDCLASSW wc = {};
        wc.hInstance = inst;
        wc.hbrBackground = (HBRUSH)GetStockObject(BLACK_BRUSH);
        
        wc.lpfnWndProc = WndProc;
        wc.lpszClassName = L"NANO";
        RegisterClassW(&wc);
        
        wc.lpfnWndProc = StatsWndProc;
        wc.lpszClassName = L"NANOStats";
        wc.hbrBackground = CreateSolidBrush(RGB(20, 20, 30));
        RegisterClassW(&wc);
        
        wc.lpfnWndProc = PreviewWndProc;
        wc.lpszClassName = L"NANOPreview";
        wc.hbrBackground = (HBRUSH)GetStockObject(BLACK_BRUSH);
        RegisterClassW(&wc);
        
        registered = true;
    }
    
    // Main overlay - fullscreen, topmost, click-through
    hwnd = CreateWindowExW(
        WS_EX_TOPMOST | WS_EX_LAYERED | WS_EX_TRANSPARENT | WS_EX_TOOLWINDOW,
        L"NANO", L"NANO",
        WS_POPUP,
        x, y, width, height,
        nullptr, nullptr, inst, nullptr
    );
    if (!hwnd) return false;
    
    SetLayeredWindowAttributes(hwnd, 0, 255, LWA_ALPHA);
    
    // Exclude from capture so we don't create feedback when capturing the screen
    SetWindowDisplayAffinity(hwnd, WDA_EXCLUDEFROMCAPTURE);
    
    // Stats overlay in top-left corner
    statsWnd = CreateWindowExW(
        WS_EX_TOPMOST | WS_EX_TOOLWINDOW | WS_EX_LAYERED,
        L"NANOStats", L"",
        WS_POPUP,
        x + 10, y + 10, 180, 80,
        nullptr, nullptr, inst, nullptr
    );
    
    if (statsWnd) {
        SetLayeredWindowAttributes(statsWnd, 0, 230, LWA_ALPHA);
        
        statsLabel = CreateWindowW(
            L"STATIC", L" NANO AI\n Starting...",
            WS_CHILD | WS_VISIBLE | SS_LEFT,
            5, 5, 170, 70,
            statsWnd, nullptr, inst, nullptr
        );
        
        // Monospace font for clean stats display
        HFONT font = CreateFontW(
            15, 0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE,
            DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
            CLEARTYPE_QUALITY, FIXED_PITCH | FF_MODERN, L"Consolas"
        );
        if (font && statsLabel) {
            SendMessageW(statsLabel, WM_SETFONT, (WPARAM)font, TRUE);
        }
        ShowWindow(statsWnd, SW_SHOW);
    }
    
    if (!CreateSwapChain()) return false;
    SetupCudaInterop();
    
    ShowWindow(hwnd, SW_SHOW);
    
    // If preview was requested before init, create it now
    if (previewEnabled && !previewWnd) {
        previewEnabled = false;
        EnablePreviewWindow(true);
    }
    
    return true;
}


bool OverlayWindow::CreateSwapChain() {
    DXGI_SWAP_CHAIN_DESC desc = {};
    desc.BufferCount = 1;
    desc.BufferDesc.Width = width;
    desc.BufferDesc.Height = height;
    desc.BufferDesc.Format = DXGI_FORMAT_B8G8R8A8_UNORM;
    desc.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
    desc.OutputWindow = hwnd;
    desc.SampleDesc.Count = 1;
    desc.Windowed = TRUE;
    desc.SwapEffect = DXGI_SWAP_EFFECT_DISCARD;
    
    ComPtr<IDXGIDevice> dxgiDev;
    SharedDevice::Get().Device()->QueryInterface(IID_PPV_ARGS(&dxgiDev));
    
    ComPtr<IDXGIAdapter> adapter;
    dxgiDev->GetAdapter(&adapter);
    
    ComPtr<IDXGIFactory> factory;
    adapter->GetParent(IID_PPV_ARGS(&factory));
    
    HRESULT hr = factory->CreateSwapChain(SharedDevice::Get().Device(), &desc, &swapChain);
    if (FAILED(hr)) return false;
    
    hr = swapChain->GetBuffer(0, IID_PPV_ARGS(&backBuffer));
    if (FAILED(hr)) return false;
    
    hr = SharedDevice::Get().Device()->CreateRenderTargetView(backBuffer.Get(), nullptr, &rtv);
    return SUCCEEDED(hr);
}


void OverlayWindow::SetupCudaInterop() {
    // Try to register backbuffer directly with CUDA
    cudaError_t err = cudaGraphicsD3D11RegisterResource(
        &cudaBackBuffer, backBuffer.Get(), cudaGraphicsRegisterFlagsNone
    );
    if (err != cudaSuccess) {
        cudaBackBuffer = nullptr;
    }
    
    // Allocate linear CUDA buffer for kernel output
    size_t size = (size_t)width * height * 4;
    cudaMalloc(&cudaBuffer, size);
}


bool OverlayWindow::BeginDirectRender(void** ptr, size_t* pitch, cudaStream_t stream) {
    if (!cudaBuffer || !ptr || !pitch) return false;
    *ptr = cudaBuffer;
    *pitch = (size_t)width * 4;
    return true;
}


void OverlayWindow::EndDirectRender(cudaStream_t stream) {
    if (!cudaBuffer || !backBuffer) return;
    
    cudaStreamSynchronize(stream);
    
    if (cudaBackBuffer) {
        // Fast path: direct CUDA to D3D copy
        cudaGraphicsMapResources(1, &cudaBackBuffer, stream);
        
        cudaArray_t arr;
        cudaGraphicsSubResourceGetMappedArray(&arr, cudaBackBuffer, 0, 0);
        
        size_t pitch = (size_t)width * 4;
        cudaMemcpy2DToArrayAsync(arr, 0, 0, cudaBuffer, pitch, pitch, height, 
                                  cudaMemcpyDeviceToDevice, stream);
        
        cudaGraphicsUnmapResources(1, &cudaBackBuffer, stream);
        cudaStreamSynchronize(stream);
    } else {
        // Fallback for systems where direct interop fails
        CopyThroughStaging(stream);
    }
}


void OverlayWindow::CopyThroughStaging(cudaStream_t stream) {
    // Use a staging texture when direct CUDA-D3D interop isn't available
    static ComPtr<ID3D11Texture2D> staging;
    static cudaGraphicsResource* stagingRes = nullptr;
    static UINT stagingW = 0, stagingH = 0;
    
    // Recreate if size changed
    if (!staging || stagingW != (UINT)width || stagingH != (UINT)height) {
        if (stagingRes) {
            cudaGraphicsUnregisterResource(stagingRes);
            stagingRes = nullptr;
        }
        staging.Reset();
        
        D3D11_TEXTURE2D_DESC desc = {};
        desc.Width = width;
        desc.Height = height;
        desc.MipLevels = 1;
        desc.ArraySize = 1;
        desc.Format = DXGI_FORMAT_B8G8R8A8_UNORM;
        desc.SampleDesc.Count = 1;
        desc.Usage = D3D11_USAGE_DEFAULT;
        desc.MiscFlags = D3D11_RESOURCE_MISC_SHARED;
        
        SharedDevice::Get().Device()->CreateTexture2D(&desc, nullptr, &staging);
        if (staging) {
            cudaGraphicsD3D11RegisterResource(&stagingRes, staging.Get(), 
                                               cudaGraphicsRegisterFlagsNone);
        }
        stagingW = width;
        stagingH = height;
    }
    
    if (staging && stagingRes) {
        cudaGraphicsMapResources(1, &stagingRes, stream);
        
        cudaArray_t arr;
        cudaGraphicsSubResourceGetMappedArray(&arr, stagingRes, 0, 0);
        
        size_t pitch = (size_t)width * 4;
        cudaMemcpy2DToArrayAsync(arr, 0, 0, cudaBuffer, pitch, pitch, height,
                                  cudaMemcpyDeviceToDevice, stream);
        
        cudaGraphicsUnmapResources(1, &stagingRes, stream);
        cudaStreamSynchronize(stream);
        
        SharedDevice::Get().Context()->CopyResource(backBuffer.Get(), staging.Get());
    }
}


void OverlayWindow::Render(ID3D11Texture2D* tex) {
    if (!swapChain || !tex) return;
    
    D3D11_TEXTURE2D_DESC srcDesc, dstDesc;
    tex->GetDesc(&srcDesc);
    backBuffer->GetDesc(&dstDesc);
    
    UINT w = std::min(srcDesc.Width, dstDesc.Width);
    UINT h = std::min(srcDesc.Height, dstDesc.Height);
    
    D3D11_BOX box = { 0, 0, 0, w, h, 1 };
    SharedDevice::Get().Context()->CopySubresourceRegion(backBuffer.Get(), 0, 0, 0, 0, tex, 0, &box);
}


void OverlayWindow::RenderSplit(ID3D11Texture2D* left, ID3D11Texture2D* right) {
    if (!swapChain || !left || !right) return;
    
    D3D11_TEXTURE2D_DESC srcDesc, dstDesc;
    left->GetDesc(&srcDesc);
    backBuffer->GetDesc(&dstDesc);
    
    UINT halfW = std::min(srcDesc.Width, dstDesc.Width) / 2;
    UINT h = std::min(srcDesc.Height, dstDesc.Height);
    
    auto ctx = SharedDevice::Get().Context();
    
    // Left half: original frame
    D3D11_BOX leftBox = { 0, 0, 0, halfW, h, 1 };
    ctx->CopySubresourceRegion(backBuffer.Get(), 0, 0, 0, 0, left, 0, &leftBox);
    
    // Right half: AI frame
    D3D11_BOX rightBox = { halfW, 0, 0, halfW * 2, h, 1 };
    ctx->CopySubresourceRegion(backBuffer.Get(), 0, halfW, 0, 0, right, 0, &rightBox);
}


void OverlayWindow::Present() {
    if (swapChain) {
        swapChain->Present(0, 0);
    }
    
    // Copy to preview window if enabled
    if (previewEnabled && previewSwapChain && previewBackBuffer && backBuffer) {
        D3D11_TEXTURE2D_DESC srcDesc, dstDesc;
        backBuffer->GetDesc(&srcDesc);
        previewBackBuffer->GetDesc(&dstDesc);
        
        UINT w = std::min(srcDesc.Width, dstDesc.Width);
        UINT h = std::min(srcDesc.Height, dstDesc.Height);
        D3D11_BOX box = { 0, 0, 0, w, h, 1 };
        
        SharedDevice::Get().Context()->CopySubresourceRegion(
            previewBackBuffer.Get(), 0, 0, 0, 0,
            backBuffer.Get(), 0, &box
        );
        previewSwapChain->Present(0, 0);
    }
}


void OverlayWindow::SetVisible(bool show) {
    if (hwnd) ShowWindow(hwnd, show ? SW_SHOW : SW_HIDE);
    if (statsWnd) ShowWindow(statsWnd, show ? SW_SHOW : SW_HIDE);
}


void OverlayWindow::UpdateStats(float outFps, float inFps, bool splitMode) {
    if (!statsLabel) return;
    
    wchar_t buf[128];
    if (splitMode) {
        swprintf_s(buf, L" NANO [SPLIT]\n OUT: %.0f FPS\n IN:  %.0f FPS", outFps, inFps);
    } else {
        float boost = (inFps > 0) ? (outFps / inFps) : 0;
        swprintf_s(buf, L" NANO AI\n OUT: %.0f FPS\n IN:  %.0f FPS\n Boost: %.1fx", 
                   outFps, inFps, boost);
    }
    SetWindowTextW(statsLabel, buf);
}


void OverlayWindow::ProcessMessages() {
    MSG msg;
    while (PeekMessageW(&msg, nullptr, 0, 0, PM_REMOVE)) {
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
    }
}


void OverlayWindow::EnablePreviewWindow(bool enable) {
    if (enable == previewEnabled) return;
    previewEnabled = enable;
    
    if (!enable) {
        if (previewWnd) ShowWindow(previewWnd, SW_HIDE);
        return;
    }
    
    // Need valid dimensions
    if (width == 0 || height == 0) return;
    
    if (!previewWnd) {
        HINSTANCE inst = GetModuleHandleW(nullptr);
        
        // 720p preview for OBS capture
        int pw = 1280, ph = 720;
        
        previewWnd = CreateWindowExW(
            0, L"NANOPreview",
            L"NANO Preview (Capture this in OBS)",
            WS_OVERLAPPEDWINDOW,
            100, 100, pw + 16, ph + 39,
            nullptr, nullptr, inst, nullptr
        );
        
        if (previewWnd) {
            DXGI_SWAP_CHAIN_DESC desc = {};
            desc.BufferCount = 2;
            desc.BufferDesc.Width = pw;
            desc.BufferDesc.Height = ph;
            desc.BufferDesc.Format = DXGI_FORMAT_B8G8R8A8_UNORM;
            desc.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
            desc.OutputWindow = previewWnd;
            desc.SampleDesc.Count = 1;
            desc.Windowed = TRUE;
            desc.SwapEffect = DXGI_SWAP_EFFECT_FLIP_SEQUENTIAL;
            
            ComPtr<IDXGIDevice> dxgiDev;
            SharedDevice::Get().Device()->QueryInterface(IID_PPV_ARGS(&dxgiDev));
            ComPtr<IDXGIAdapter> adapter;
            dxgiDev->GetAdapter(&adapter);
            ComPtr<IDXGIFactory> factory;
            adapter->GetParent(IID_PPV_ARGS(&factory));
            
            if (SUCCEEDED(factory->CreateSwapChain(SharedDevice::Get().Device(), &desc, &previewSwapChain))) {
                previewSwapChain->GetBuffer(0, IID_PPV_ARGS(&previewBackBuffer));
            }
        }
    }
    
    if (previewWnd) ShowWindow(previewWnd, SW_SHOW);
}
