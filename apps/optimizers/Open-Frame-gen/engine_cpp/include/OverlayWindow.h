#pragma once
#include <windows.h>
#include <d3d11.h>
#include <dxgi.h>
#include <wrl/client.h>
#include <cuda_runtime.h>
#include <cuda_d3d11_interop.h>

using Microsoft::WRL::ComPtr;

/*
 * Fullscreen transparent overlay for displaying AI-interpolated frames.
 * Uses D3D11 with CUDA interop for zero-copy GPU rendering.
 */
class OverlayWindow {
public:
    OverlayWindow() = default;
    ~OverlayWindow();
    
    bool Init(HMONITOR monitor);
    
    // Texture copy rendering
    void Render(ID3D11Texture2D* texture);
    void RenderSplit(ID3D11Texture2D* left, ID3D11Texture2D* right);
    
    // Direct CUDA rendering (zero-copy path)
    bool BeginDirectRender(void** cudaPtr, size_t* pitch, cudaStream_t stream);
    void EndDirectRender(cudaStream_t stream);
    
    void Present();
    void SetVisible(bool show);
    void UpdateStats(float outFps, float inFps, bool splitMode);
    void ProcessMessages();
    
    // Preview window for OBS capture
    void EnablePreviewWindow(bool enable);
    bool IsPreviewEnabled() const { return previewEnabled; }
    
    HWND GetHwnd() const { return hwnd; }
    int GetWidth() const { return width; }
    int GetHeight() const { return height; }

private:
    // Windows
    HWND hwnd = nullptr;
    HWND statsWnd = nullptr;
    HWND statsLabel = nullptr;
    HWND previewWnd = nullptr;
    
    int width = 0;
    int height = 0;
    
    // D3D11 resources
    ComPtr<IDXGISwapChain> swapChain;
    ComPtr<ID3D11Texture2D> backBuffer;
    ComPtr<ID3D11RenderTargetView> rtv;
    
    // Preview window resources
    ComPtr<IDXGISwapChain> previewSwapChain;
    ComPtr<ID3D11Texture2D> previewBackBuffer;
    bool previewEnabled = false;
    
    // CUDA interop
    cudaGraphicsResource* cudaBackBuffer = nullptr;
    void* cudaBuffer = nullptr;
    
    // Helpers
    bool CreateSwapChain();
    void SetupCudaInterop();
    void CopyThroughStaging(cudaStream_t stream);
    
    static LRESULT CALLBACK WndProc(HWND, UINT, WPARAM, LPARAM);
    static LRESULT CALLBACK StatsWndProc(HWND, UINT, WPARAM, LPARAM);
    static LRESULT CALLBACK PreviewWndProc(HWND, UINT, WPARAM, LPARAM);
};
