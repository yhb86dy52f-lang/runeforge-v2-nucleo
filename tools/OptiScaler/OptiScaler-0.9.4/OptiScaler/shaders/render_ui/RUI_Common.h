#pragma once

#include "SysUtils.h"
#include <d3dcompiler.h>

struct CompareParams
{
    float DiffThreshold = 0.02f;
    float PinkAmount = 0.6f;
    float InvOutputSize[2] = { 0, 0 };
};

static std::string ruiCode = R"(
Texture2D<float4> UI : register(t0); 
Texture2D<float4> BackBuffer : register(t1); 
SamplerState Sampler : register(s0);

struct VSOut
{
    float4 pos : SV_Position;
    float2 uv : TEXCOORD0;
};

VSOut VSMain(uint vid : SV_VertexID)
{
    float2 uv = float2((vid << 1) & 2, vid & 2);
    VSOut o;
    o.pos = float4(uv * float2(2, -2) + float2(-1, 1), 0, 1);
    o.uv = uv;
    return o;
}


float4 PSMain(VSOut i) : SV_Target
{
    float4 dst = BackBuffer.Sample(Sampler, i.uv);
    float4 src = UI.Sample(Sampler, i.uv);

    float a = saturate(src.a);
    float3 outRgb = src.rgb + dst.rgb * (1.0 - a);
    return float4(outRgb, 1.0);
}
)";

static std::string ruipmCode = R"(
Texture2D<float4> UI : register(t0); 
Texture2D<float4> BackBuffer : register(t1); 
SamplerState Sampler : register(s0);

struct VSOut
{
    float4 pos : SV_Position;
    float2 uv : TEXCOORD0;
};

VSOut VSMain(uint vid : SV_VertexID)
{
    float2 uv = float2((vid << 1) & 2, vid & 2);
    VSOut o;
    o.pos = float4(uv * float2(2, -2) + float2(-1, 1), 0, 1);
    o.uv = uv;
    return o;
}


float4 PSMain(VSOut i) : SV_Target
{
    float4 dst = BackBuffer.Sample(Sampler, i.uv); // dst = current swapchain color
    float4 src = UI.Sample(Sampler, i.uv); // src = UI color

    // Straight-alpha "source over":
    float a = saturate(src.a);
    float3 outRgb = src.rgb * a + dst.rgb * (1.0 - a);
    return float4(outRgb, 1.0);
}
)";

static ID3DBlob* RUI_CompileShader(const char* shaderCode, const char* entryPoint, const char* target)
{
    ID3DBlob* shaderBlob = nullptr;
    ID3DBlob* errorBlob = nullptr;

    HRESULT hr = D3DCompile(shaderCode, strlen(shaderCode), nullptr, nullptr, nullptr, entryPoint, target,
                            D3DCOMPILE_OPTIMIZATION_LEVEL3, 0, &shaderBlob, &errorBlob);

    if (FAILED(hr))
    {
        LOG_ERROR("error while compiling shader");

        if (errorBlob)
        {
            LOG_ERROR("error while compiling shader : {0}", (char*) errorBlob->GetBufferPointer());
            errorBlob->Release();
        }

        if (shaderBlob)
            shaderBlob->Release();

        return nullptr;
    }

    if (errorBlob)
        errorBlob->Release();

    return shaderBlob;
}
