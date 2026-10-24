#include "SharedDevice.h"

bool SharedDevice::Init() {
    if (m_Device) return true;
    UINT flags = 0;
    D3D_FEATURE_LEVEL levels[] = { D3D_FEATURE_LEVEL_11_0 };
    return SUCCEEDED(D3D11CreateDevice(nullptr, D3D_DRIVER_TYPE_HARDWARE, nullptr, flags, levels, 1, D3D11_SDK_VERSION, &m_Device, nullptr, &m_Context));
}
