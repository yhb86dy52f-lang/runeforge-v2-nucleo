#pragma once
#include <NvInfer.h>
#include <NvOnnxParser.h>
#include <cuda_runtime_api.h>
#include <d3d11.h>
#include <wrl/client.h>
#include <string>
#include <memory>

using Microsoft::WRL::ComPtr;

enum class AIBackend { AUTO, NVIDIA_TRT, UNIVERSAL_DML };
enum class AIQuality { QUALITY_80, QUALITY_100 };  // 80% of original for performance and 100 for quality 
class Logger : public nvinfer1::ILogger {
public: 
    void log(Severity s, const char* msg) noexcept override;
};

class InferenceEngine {
public:
    InferenceEngine() noexcept; 
    ~InferenceEngine() noexcept;

    bool LoadModel(const std::string& path, ID3D11Device* dev);
    bool RunInference(ID3D11Texture2D* in, ID3D11Texture2D** out);
    void Reset();  // Clean up for restart
    
    // ZERO-COPY: Run inference and write directly to provided CUDA buffer
    bool RunInferenceDirect(ID3D11Texture2D* in, void* outputBgra, int outWidth, int outHeight, int outPitch);
    
    void SetEnable4K(bool v) { m_Enable4K = v; }
    void SetSharpness(float v) { m_Sharpness = v; }
    void SetQuality(AIQuality q) { m_Quality = q; }
    void SetAutoQuality(bool v) { m_AutoQuality = v; }
    void SetTargetFPS(float fps) { m_TargetFPS = fps; }
    AIBackend GetBackend() { return m_Backend; }
    AIQuality GetQuality() { return m_Quality; }
    float GetLastInferenceMs() { return m_LastInferenceMs; }
    cudaStream_t GetStream() { return m_Stream; }

private:
    AIBackend m_Backend; 
    AIQuality m_Quality;
    bool m_Enable4K; 
    float m_Sharpness; 
    bool m_FirstFrame;
    bool m_AutoQuality;
    float m_TargetFPS;
    float m_LastInferenceMs;
    UINT m_Lw, m_Lh; 
    ID3D11Device* m_Dev;
    
    std::unique_ptr<nvinfer1::IRuntime> m_Runtime;
    std::unique_ptr<nvinfer1::ICudaEngine> m_Engine;
    std::unique_ptr<nvinfer1::IExecutionContext> m_Ctx;
    Logger m_Log; 
    cudaStream_t m_Stream;
    
    void* m_DBufs[3]; 
    void* m_Prev; 
    void* m_GBgraIn;
    void* m_GBgraOut;
    
    cudaGraphicsResource* m_CudaInRes;
    cudaGraphicsResource* m_CudaOutRes;
    ComPtr<ID3D11Texture2D> m_SharedIn, m_SharedOut;
    
    bool BuildEngine(const std::string& p);
    void GetAIResolution(size_t& w, size_t& h);
    
    // Internal helper for common inference logic
    bool RunInferenceCore(ID3D11Texture2D* in, void* outputBgra, int outWidth, int outHeight, int outPitch);
};
