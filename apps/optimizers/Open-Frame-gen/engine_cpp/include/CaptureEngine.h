#pragma once
#include <d3d11.h>
#include <dxgi1_2.h>
#include <wrl/client.h>

using Microsoft::WRL::ComPtr;

class CaptureEngine {
public:
    bool Init(HWND target = nullptr, int monitorIdx = 0);
    bool CaptureNextFrame(ID3D11Texture2D** outTexture);
    void Reset();  // Clean up for restart
    
    // Get last captured frame (for when no new frame is available)
    bool GetLastFrame(ID3D11Texture2D** outTexture);
    
private:
    HWND m_Target = nullptr;
    ComPtr<IDXGIOutputDuplication> m_Dupl;
    ComPtr<ID3D11Texture2D> m_SharedTex;
    ComPtr<ID3D11Texture2D> m_LastFrame;  // Cache last frame
    DXGI_OUTPUT_DESC m_MonitorDesc = {};
    bool m_HasFrame = false;
};
