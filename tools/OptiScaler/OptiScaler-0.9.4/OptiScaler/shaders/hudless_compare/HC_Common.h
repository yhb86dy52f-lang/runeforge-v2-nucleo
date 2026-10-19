#pragma once

#include "SysUtils.h"
#include <d3dcompiler.h>

struct CompareParams
{
    float DiffThreshold = 0.02f;
    float PinkAmount = 0.6f;
    float InvOutputSize[2] = { 0, 0 };
};

static std::string hcCode = R"(
Texture2D gRefTex : register(t0); 
Texture2D gBackCopyTex : register(t1);

SamplerState gPointClamp : register(s0); 

cbuffer Params : register(b0)
{
    float DiffThreshold; 
    float PinkAmount; 
    float2 InvOutputSize; 
};

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
    float4 refC = gRefTex.Sample(gPointClamp, i.uv);
    float4 backC = gBackCopyTex.Sample(gPointClamp, i.uv);

    float3 diff = abs(refC.rgb - backC.rgb);
    float d = max(max(diff.r, diff.g), diff.b);

    // soft threshold
    float m = smoothstep(DiffThreshold, DiffThreshold * 2.0, d);

    const float3 pink = float3(1.0, 0.4, 0.6);
    float3 outRgb = lerp(backC.rgb, pink, m * PinkAmount);
    return float4(outRgb, backC.a);
}
)";

static ID3DBlob* HC_CompileShader(const char* shaderCode, const char* entryPoint, const char* target)
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
