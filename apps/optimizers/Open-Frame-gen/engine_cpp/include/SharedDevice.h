#pragma once
#include <d3d11.h>
#include <wrl/client.h>

using Microsoft::WRL::ComPtr;

class SharedDevice {
public:
    static SharedDevice& Get() { static SharedDevice instance; return instance; }
    bool Init();
    ID3D11Device* Device() { return m_Device.Get(); }
    ID3D11DeviceContext* Context() { return m_Context.Get(); }
    bool IsInitialized() const { return m_Device != nullptr; }
private:
    ComPtr<ID3D11Device> m_Device;
    ComPtr<ID3D11DeviceContext> m_Context;
};
