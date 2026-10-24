#include "CaptureEngine.h"
#include "SharedDevice.h"
#include <iostream>
#include <algorithm>

bool CaptureEngine::Init(HWND target, int monitorIdx) {
    m_Target = target;
    m_HasFrame = false;
    ComPtr<IDXGIDevice> dxgiDev; 
    SharedDevice::Get().Device()->QueryInterface(IID_PPV_ARGS(&dxgiDev));
    ComPtr<IDXGIAdapter> adapter; 
    dxgiDev->GetAdapter(&adapter);
    ComPtr<IDXGIOutput> output;
    
    if (FAILED(adapter->EnumOutputs(monitorIdx, &output))) return false;
    output->GetDesc(&m_MonitorDesc);
    
    ComPtr<IDXGIOutput1> output1; 
    output.As(&output1);
    
    if (m_Dupl) m_Dupl.Reset();
    return SUCCEEDED(output1->DuplicateOutput(SharedDevice::Get().Device(), &m_Dupl));
}

bool CaptureEngine::CaptureNextFrame(ID3D11Texture2D** outTexture) {
    if (!m_Dupl) return false;
    ComPtr<IDXGIResource> res; 
    DXGI_OUTDUPL_FRAME_INFO info;
    
    // Increased timeout to 16ms (60fps) for better capture rate
    HRESULT hr = m_Dupl->AcquireNextFrame(16, &info, &res);
    if (hr == DXGI_ERROR_WAIT_TIMEOUT) {
        // No new frame - return last frame if available
        if (m_HasFrame && m_LastFrame) {
            *outTexture = m_LastFrame.Get();
            (*outTexture)->AddRef();
            return true;
        }
        return false;
    }
    if (FAILED(hr)) { 
        m_Dupl.Reset(); 
        return false; 
    }
    
    ComPtr<ID3D11Texture2D> desktopTex; 
    res.As(&desktopTex);
    D3D11_TEXTURE2D_DESC desc; 
    desktopTex->GetDesc(&desc);
    
    D3D11_BOX box; 
    bool hasBox = false;
    if (m_Target && IsWindow(m_Target)) {
        RECT r; GetWindowRect(m_Target, &r);
        LONG left = std::max(0L, r.left - m_MonitorDesc.DesktopCoordinates.left);
        LONG top = std::max(0L, r.top - m_MonitorDesc.DesktopCoordinates.top);
        LONG right = std::min((LONG)desc.Width, r.right - m_MonitorDesc.DesktopCoordinates.left);
        LONG bottom = std::min((LONG)desc.Height, r.bottom - m_MonitorDesc.DesktopCoordinates.top);
        
        if (right > left && bottom > top) {
            box = { (UINT)left, (UINT)top, 0, (UINT)right, (UINT)bottom, 1 };
            desc.Width = right - left; 
            desc.Height = bottom - top; 
            hasBox = true;
        }
    }
    
    // Create or recreate texture if needed
    auto createTexture = [&](ComPtr<ID3D11Texture2D>& tex) {
        D3D11_TEXTURE2D_DESC copyDesc = {};
        copyDesc.Width = desc.Width;
        copyDesc.Height = desc.Height;
        copyDesc.MipLevels = 1;
        copyDesc.ArraySize = 1;
        copyDesc.Format = DXGI_FORMAT_B8G8R8A8_UNORM;
        copyDesc.SampleDesc.Count = 1;
        copyDesc.Usage = D3D11_USAGE_DEFAULT;
        copyDesc.BindFlags = 0;
        SharedDevice::Get().Device()->CreateTexture2D(&copyDesc, nullptr, &tex);
    };
    
    if (!m_SharedTex) {
        createTexture(m_SharedTex);
        createTexture(m_LastFrame);
    } else {
        D3D11_TEXTURE2D_DESC cur; m_SharedTex->GetDesc(&cur);
        if (cur.Width != desc.Width || cur.Height != desc.Height) {
            m_SharedTex.Reset();
            m_LastFrame.Reset();
            createTexture(m_SharedTex);
            createTexture(m_LastFrame);
        }
    }
    
    // Copy captured frame
    if (hasBox) {
        SharedDevice::Get().Context()->CopySubresourceRegion(m_SharedTex.Get(), 0, 0, 0, 0, desktopTex.Get(), 0, &box);
    } else {
        SharedDevice::Get().Context()->CopyResource(m_SharedTex.Get(), desktopTex.Get());
    }
    
    // Cache this frame as last frame
    SharedDevice::Get().Context()->CopyResource(m_LastFrame.Get(), m_SharedTex.Get());
    m_HasFrame = true;
    
    m_Dupl->ReleaseFrame();
    *outTexture = m_SharedTex.Get();
    (*outTexture)->AddRef();
    return true;
}

bool CaptureEngine::GetLastFrame(ID3D11Texture2D** outTexture) {
    if (!m_HasFrame || !m_LastFrame) return false;
    *outTexture = m_LastFrame.Get();
    (*outTexture)->AddRef();
    return true;
}

void CaptureEngine::Reset() {
    if (m_Dupl) m_Dupl.Reset();
    m_SharedTex.Reset();
    m_LastFrame.Reset();
    m_Target = nullptr;
    m_HasFrame = false;
}
