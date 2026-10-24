#include "InferenceEngine.h"
#include <fstream>
#include <filesystem>
#include <iostream>
#include <cuda_d3d11_interop.h>
#include <cuda_fp16.h>
#include <chrono>

extern "C" void LaunchBGRAToPlanarFP16(const unsigned char* bgra, void* output, int sw, int sh, int dw, int dh, int pitch, cudaStream_t stream);
extern "C" void LaunchPlanarFP16ToBGRA(const void* input, unsigned char* bgra, int sw, int sh, int dw, int dh, int pitch, float sharpness, cudaStream_t stream);

void Logger::log(Severity s, const char* msg) noexcept {
    // Only log warnings and errors — suppress INFO/VERBOSE to avoid massive trt_log.txt
    if (s == Severity::kVERBOSE || s == Severity::kINFO) return;
    static std::ofstream logFile("trt_log.txt", std::ios::app);
    const char* prefix = "[INFO] ";
    switch (s) {
        case Severity::kINTERNAL_ERROR: prefix = "[INTERNAL_ERROR] "; break;
        case Severity::kERROR:          prefix = "[ERROR] "; break;
        case Severity::kWARNING:        prefix = "[WARNING] "; break;
        default: break;
    }
    logFile << prefix << msg << std::endl;
}

InferenceEngine::InferenceEngine() noexcept : 
    m_Backend(AIBackend::AUTO), m_Quality(AIQuality::QUALITY_80), m_Enable4K(false), 
    m_Sharpness(0.6f), m_FirstFrame(true), m_AutoQuality(false), m_TargetFPS(60.0f),
    m_LastInferenceMs(10.0f), m_Lw(0), m_Lh(0), m_Dev(nullptr) {
    m_DBufs[0]=0; m_DBufs[1]=0; m_DBufs[2]=0; 
    m_Prev=0; m_GBgraIn=0; m_GBgraOut=0;
    m_CudaInRes = nullptr; m_CudaOutRes = nullptr;
    m_Stream = nullptr;
    
    std::ofstream logFile("trt_log.txt", std::ios::trunc); // Clear log on start
    logFile << "InferenceEngine initialized" << std::endl;

    // Try to create CUDA stream, but don't fail if it doesn't work
    cudaError_t err = cudaStreamCreate(&m_Stream);
    if (err != cudaSuccess) {
        m_Stream = nullptr; // Will use default stream
    }
}

InferenceEngine::~InferenceEngine() noexcept {
    // IMPORTANT: Destroy execution context BEFORE engine (TensorRT requirement)
    m_Ctx.reset();
    m_Engine.reset();
    m_Runtime.reset();
    
    // Now clean up CUDA resources
    if(m_CudaInRes) cudaGraphicsUnregisterResource(m_CudaInRes);
    if(m_CudaOutRes) cudaGraphicsUnregisterResource(m_CudaOutRes);
    for(int i=0;i<3;i++) if(m_DBufs[i]) cudaFree(m_DBufs[i]);
    if(m_Prev) cudaFree(m_Prev); 
    if(m_GBgraIn) cudaFree(m_GBgraIn); 
    if(m_GBgraOut) cudaFree(m_GBgraOut);
    if(m_Stream) cudaStreamDestroy(m_Stream);
}

bool InferenceEngine::LoadModel(const std::string& path, ID3D11Device* dev) {
    // Clean up any previous model state first (proper order!)
    m_Ctx.reset();
    m_Engine.reset();
    m_Runtime.reset();
    
    m_Dev = dev; 
    bool isNv = false;
    
    std::ofstream logFile("trt_log.txt", std::ios::app);
    logFile << "Loading model from: " << path << std::endl;
    if (!std::filesystem::exists(path)) {
        logFile << "ERROR: File does not exist at " << path << std::endl;
        return false;
    }

    ComPtr<IDXGIDevice> dxgi; 
    if(SUCCEEDED(dev->QueryInterface(IID_PPV_ARGS(&dxgi)))) {
        ComPtr<IDXGIAdapter> ad; 
        dxgi->GetAdapter(&ad); 
        DXGI_ADAPTER_DESC d;
        if(SUCCEEDED(ad->GetDesc(&d)) && d.VendorId == 0x10DE) isNv = true;
        if(isNv) { 
            int cdev; 
            if (cudaD3D11GetDevice(&cdev, ad.Get()) == cudaSuccess) cudaSetDevice(cdev); 
        }
    }
    
    m_Backend = isNv ? AIBackend::NVIDIA_TRT : AIBackend::UNIVERSAL_DML;
    if(m_Backend == AIBackend::UNIVERSAL_DML) {
        logFile << "Backend is Universal DML (Fallback/Mock)" << std::endl;
        return true; 
    }

    m_Runtime.reset(nvinfer1::createInferRuntime(m_Log));
    if(!m_Runtime) {
        logFile << "ERROR: Failed to create TensorRT runtime" << std::endl;
        return false;
    }
    
    std::string ep = path + ".engine";
    std::string stampPath = path + ".engine.trtver";

    // Check TRT version stamp — if stale, delete engine so it rebuilds cleanly
    {
        int trtMajor = NV_TENSORRT_MAJOR, trtMinor = NV_TENSORRT_MINOR, trtPatch = NV_TENSORRT_PATCH;
        std::string currentVer = std::to_string(trtMajor) + "." + std::to_string(trtMinor) + "." + std::to_string(trtPatch);
        std::string cachedVer;
        if (std::filesystem::exists(stampPath)) {
            std::ifstream sf(stampPath); sf >> cachedVer;
        }
        if (cachedVer != currentVer && std::filesystem::exists(ep)) {
            logFile << "TRT version changed (" << cachedVer << " -> " << currentVer << "), deleting stale engine cache" << std::endl;
            std::filesystem::remove(ep);
            std::filesystem::remove(stampPath);
        }
    }

    // Try to load existing engine from cache
    if(std::filesystem::exists(ep)) {
        logFile << "Loading cached engine: " << ep << std::endl;
        std::ifstream f(ep, std::ios::binary);
        std::vector<char> data((std::istreambuf_iterator<char>(f)), {});
        f.close();
        if(!data.empty()) {
            m_Engine.reset(m_Runtime->deserializeCudaEngine(data.data(), data.size()));
            if(m_Engine) {
                logFile << "Engine loaded from cache successfully (skipping rebuild)" << std::endl;
            } else {
                logFile << "WARNING: Failed to deserialize cached engine, will rebuild" << std::endl;
                std::filesystem::remove(ep); // delete corrupt cache
            }
        }
    }

    // Build engine only if cache load failed or no cache existed
    if(!m_Engine) {
        logFile << "Building new TensorRT engine from ONNX (one-time, will be cached): " << path << std::endl;
        if(!BuildEngine(path)) {
            logFile << "ERROR: BuildEngine failed" << std::endl;
            return false;
        }
        // Write version stamp alongside the engine
        if(m_Engine) {
            std::string ver = std::to_string(NV_TENSORRT_MAJOR) + "." + std::to_string(NV_TENSORRT_MINOR) + "." + std::to_string(NV_TENSORRT_PATCH);
            std::ofstream sf(stampPath); sf << ver;
            logFile << "Engine built and cached. TRT version stamp: " << ver << std::endl;
        }
    }
    
    if(!m_Engine) {
        logFile << "ERROR: m_Engine is null after load/build" << std::endl;
        return false;
    }
    m_Ctx.reset(m_Engine->createExecutionContext());
    if(!m_Ctx) {
        logFile << "ERROR: Failed to create execution context" << std::endl;
        return false;
    }
    
    // Get AI resolution based on quality setting
    size_t w, h;
    GetAIResolution(w, h);
    
    // Find and set input tensor dimensions
    for(int i = 0; i < m_Engine->getNbIOTensors(); i++) {
        const char* name = m_Engine->getIOTensorName(i);
        if(m_Engine->getTensorIOMode(name) == nvinfer1::TensorIOMode::kINPUT) {
            nvinfer1::Dims4 inputDims{1, 6, (int)h, (int)w};
            if(!m_Ctx->setInputShape(name, inputDims)) {
                logFile << "WARNING: Could not set input shape for " << name << std::endl;
            } else {
                logFile << "Set input shape: 1x6x" << h << "x" << w << " (quality=" << (int)m_Quality << ")" << std::endl;
            }
        }
    }
    
    logFile << "Execution context created successfully" << std::endl;

    // Allocate buffers for inference at selected quality level
    size_t pSize = w * h * sizeof(half);
    
    cudaMalloc(&m_DBufs[0], 6 * pSize);   // Input: prev(3) + curr(3) channels
    cudaMalloc(&m_DBufs[2], 3 * pSize);   // Output: 3 channels
    cudaMalloc(&m_Prev, 3 * pSize);       // Previous frame storage
    
    // BGRA buffers will be allocated dynamically in RunInference when we know the actual resolution
    m_GBgraIn = nullptr;
    m_GBgraOut = nullptr;
    m_FirstFrame = true; 
    
    return true;
}

bool InferenceEngine::BuildEngine(const std::string& p) {
    std::ofstream logFile("trt_log.txt", std::ios::app);
    logFile << "BuildEngine: Starting..." << std::endl;
    
    auto b = std::unique_ptr<nvinfer1::IBuilder>(nvinfer1::createInferBuilder(m_Log));
    if(!b) { logFile << "ERROR: createInferBuilder failed" << std::endl; return false; }
    
    // TRT10: explicit batch is now the default, createNetworkV2(0) is correct
    auto n = std::unique_ptr<nvinfer1::INetworkDefinition>(b->createNetworkV2(0));
    if(!n) { logFile << "ERROR: createNetworkV2 failed" << std::endl; return false; }
    
    auto pa = std::unique_ptr<nvonnxparser::IParser>(nvonnxparser::createParser(*n, m_Log));
    if(!pa) { logFile << "ERROR: createParser failed" << std::endl; return false; }
    
    if(!pa->parseFromFile(p.c_str(), 3)) {
        logFile << "ERROR: parseFromFile failed" << std::endl;
        return false;
    }
    
    auto c = std::unique_ptr<nvinfer1::IBuilderConfig>(b->createBuilderConfig());
    if(!c) { logFile << "ERROR: createBuilderConfig failed" << std::endl; return false; }
    
    c->setMemoryPoolLimit(nvinfer1::MemoryPoolType::kWORKSPACE, 1024ULL<<20);  // 1GB workspace for full res
    // TRT10: kFP16 BuilderFlag was removed — TRT10 automatically uses FP16/INT8 when available.
    // FP16 precision is now always supported on modern NVIDIA GPUs without an explicit flag.
    
    // Create optimization profile supporting 75% to 100% resolutions
    // 75% = 1440x800, 85% = 1632x928, 90% = 1728x960, 100% = 1920x1080
    auto profile = b->createOptimizationProfile();
    profile->setDimensions("input", nvinfer1::OptProfileSelector::kMIN, nvinfer1::Dims4{1, 6, 800, 1440});   // 75%
    profile->setDimensions("input", nvinfer1::OptProfileSelector::kOPT, nvinfer1::Dims4{1, 6, 928, 1632});   // 85%
    profile->setDimensions("input", nvinfer1::OptProfileSelector::kMAX, nvinfer1::Dims4{1, 6, 1088, 1920}); // 100% (rounded to 32)
    c->addOptimizationProfile(profile);
    
    logFile << "BuildEngine: Building network (this may take a minute)..." << std::endl;
    auto plan = std::unique_ptr<nvinfer1::IHostMemory>(b->buildSerializedNetwork(*n, *c));
    if(!plan || plan->size() == 0) {
        logFile << "ERROR: buildSerializedNetwork failed" << std::endl;
        return false;
    }
    
    logFile << "BuildEngine: Deserializing engine (" << plan->size() << " bytes)..." << std::endl;
    m_Engine.reset(m_Runtime->deserializeCudaEngine(plan->data(), plan->size()));
    if(!m_Engine) {
        logFile << "ERROR: deserializeCudaEngine failed" << std::endl;
        return false;
    }
    
    std::ofstream f(p+".engine", std::ios::binary); 
    f.write(static_cast<const char*>(plan->data()), static_cast<std::streamsize>(plan->size()));
    logFile << "BuildEngine: SUCCESS - saved engine to " << p << ".engine" << std::endl;
    return true;
}

bool InferenceEngine::RunInference(ID3D11Texture2D* inTex, ID3D11Texture2D** outTex) {
    if(!inTex || !outTex) return false;
    if(m_Backend == AIBackend::UNIVERSAL_DML) { 
        *outTex = inTex; 
        (*outTex)->AddRef(); 
        return true; 
    }
    
    // Safety checks for TensorRT objects
    if(!m_Engine || !m_Ctx || !m_Runtime) {
        return false;
    }

    D3D11_TEXTURE2D_DESC d; 
    inTex->GetDesc(&d);
    
    if(d.Width != m_Lw || d.Height != m_Lh) {
        if(m_CudaInRes) { cudaGraphicsUnregisterResource(m_CudaInRes); m_CudaInRes = nullptr; }
        if(m_CudaOutRes) { cudaGraphicsUnregisterResource(m_CudaOutRes); m_CudaOutRes = nullptr; }
        m_SharedIn.Reset(); 
        m_SharedOut.Reset();
        
        // Reallocate BGRA buffers for new resolution
        if(m_GBgraIn) { cudaFree(m_GBgraIn); m_GBgraIn = nullptr; }
        if(m_GBgraOut) { cudaFree(m_GBgraOut); m_GBgraOut = nullptr; }
        size_t bgraSize = d.Width * d.Height * 4;
        cudaMalloc(&m_GBgraIn, bgraSize);
        cudaMalloc(&m_GBgraOut, bgraSize);
        
        m_Lw = d.Width; 
        m_Lh = d.Height;
        
        D3D11_TEXTURE2D_DESC shared = {};
        shared.Width = d.Width;
        shared.Height = d.Height;
        shared.MipLevels = 1;
        shared.ArraySize = 1;
        shared.Format = DXGI_FORMAT_B8G8R8A8_UNORM;
        shared.SampleDesc.Count = 1;
        shared.Usage = D3D11_USAGE_DEFAULT;
        shared.BindFlags = D3D11_BIND_RENDER_TARGET | D3D11_BIND_SHADER_RESOURCE;
        shared.MiscFlags = D3D11_RESOURCE_MISC_SHARED;
        
        if(FAILED(m_Dev->CreateTexture2D(&shared, 0, &m_SharedIn))) return false;
        if(FAILED(m_Dev->CreateTexture2D(&shared, 0, &m_SharedOut))) return false;
        
        if(cudaGraphicsD3D11RegisterResource(&m_CudaInRes, m_SharedIn.Get(), cudaGraphicsRegisterFlagsNone) != cudaSuccess) return false;
        if(cudaGraphicsD3D11RegisterResource(&m_CudaOutRes, m_SharedOut.Get(), cudaGraphicsRegisterFlagsNone) != cudaSuccess) return false;
    }

    ComPtr<ID3D11DeviceContext> ctx; 
    m_Dev->GetImmediateContext(&ctx);
    ctx->CopyResource(m_SharedIn.Get(), inTex);
    
    cudaGraphicsMapResources(1, &m_CudaInRes, m_Stream);
    cudaArray_t inArray;
    cudaGraphicsSubResourceGetMappedArray(&inArray, m_CudaInRes, 0, 0);
    // Copy from D3D texture array to linear GPU buffer (pitch = width * 4 bytes for BGRA)
    size_t linearPitch = d.Width * 4;
    cudaMemcpy2DFromArrayAsync(m_GBgraIn, linearPitch, inArray, 0, 0, linearPitch, d.Height, cudaMemcpyDeviceToDevice, m_Stream);
    cudaGraphicsUnmapResources(1, &m_CudaInRes, m_Stream);

    // Get AI resolution based on quality setting
    size_t aiW, aiH;
    GetAIResolution(aiW, aiH);
    size_t pSz = aiW * aiH * sizeof(half); 
    char* inPtr = (char*)m_DBufs[0];

    LaunchBGRAToPlanarFP16((unsigned char*)m_GBgraIn, inPtr + 3*pSz, (int)d.Width, (int)d.Height, (int)aiW, (int)aiH, (int)d.Width*4, m_Stream);
    
    if(m_FirstFrame) {
        cudaMemcpyAsync(m_Prev, inPtr + 3*pSz, 3*pSz, cudaMemcpyDeviceToDevice, m_Stream);
        m_FirstFrame = false; 
        return false;
    }
    
    cudaMemcpyAsync(inPtr, m_Prev, 3*pSz, cudaMemcpyDeviceToDevice, m_Stream);

    // Double-check engine and context are valid before using
    if(!m_Engine || !m_Ctx) {
        return false;
    }
    
    int numTensors = m_Engine->getNbIOTensors();
    for(int i=0; i<numTensors; i++) {
        const char* tn = m_Engine->getIOTensorName(i);
        if(!tn) continue;
        if(m_Engine->getTensorIOMode(tn) == nvinfer1::TensorIOMode::kINPUT) {
            m_Ctx->setTensorAddress(tn, m_DBufs[0]);
        } else {
            m_Ctx->setTensorAddress(tn, m_DBufs[2]);
        }
    }
    
    // Time inference for auto-quality
    auto inferStart = std::chrono::high_resolution_clock::now();
    
    if(!m_Ctx->enqueueV3(m_Stream)) return false;

    LaunchPlanarFP16ToBGRA(m_DBufs[2], (unsigned char*)m_GBgraOut, (int)aiW, (int)aiH, (int)d.Width, (int)d.Height, (int)d.Width*4, m_Sharpness, m_Stream);
    
    cudaGraphicsMapResources(1, &m_CudaOutRes, m_Stream);
    cudaArray_t outArray;
    cudaGraphicsSubResourceGetMappedArray(&outArray, m_CudaOutRes, 0, 0);
    cudaMemcpy2DToArrayAsync(outArray, 0, 0, m_GBgraOut, d.Width*4, d.Width*4, d.Height, cudaMemcpyDeviceToDevice, m_Stream);
    cudaGraphicsUnmapResources(1, &m_CudaOutRes, m_Stream);
    
    cudaStreamSynchronize(m_Stream);
    
    auto inferEnd = std::chrono::high_resolution_clock::now();
    m_LastInferenceMs = std::chrono::duration<float, std::milli>(inferEnd - inferStart).count();
    
    // Auto-quality adjustment: toggle between 80% and 100%
    if(m_AutoQuality) {
        float targetMs = 1000.0f / m_TargetFPS;
        float headroom = targetMs - m_LastInferenceMs;
        
        if(headroom > 5.0f && m_Quality == AIQuality::QUALITY_80) {
            m_Quality = AIQuality::QUALITY_100;
        } else if(headroom < -2.0f && m_Quality == AIQuality::QUALITY_100) {
            m_Quality = AIQuality::QUALITY_80;
        }
    }
    
    cudaMemcpyAsync(m_Prev, inPtr + 3*pSz, 3*pSz, cudaMemcpyDeviceToDevice, m_Stream);

    *outTex = m_SharedOut.Get(); 
    (*outTex)->AddRef(); 
    return true;
}

// ZERO-COPY: Run inference and write directly to provided CUDA buffer
bool InferenceEngine::RunInferenceDirect(ID3D11Texture2D* inTex, void* outputBgra, int outWidth, int outHeight, int outPitch) {
    if(!inTex || !outputBgra) return false;
    if(m_Backend == AIBackend::UNIVERSAL_DML) return false;  // DML doesn't support direct
    
    // Safety checks for TensorRT objects
    if(!m_Engine || !m_Ctx || !m_Runtime) return false;

    D3D11_TEXTURE2D_DESC d; 
    inTex->GetDesc(&d);
    
    // Setup shared input texture if needed (same as RunInference)
    if(d.Width != m_Lw || d.Height != m_Lh) {
        if(m_CudaInRes) { cudaGraphicsUnregisterResource(m_CudaInRes); m_CudaInRes = nullptr; }
        m_SharedIn.Reset();
        
        if(m_GBgraIn) { cudaFree(m_GBgraIn); m_GBgraIn = nullptr; }
        size_t bgraSize = d.Width * d.Height * 4;
        cudaMalloc(&m_GBgraIn, bgraSize);
        
        m_Lw = d.Width; 
        m_Lh = d.Height;
        
        D3D11_TEXTURE2D_DESC shared = {};
        shared.Width = d.Width;
        shared.Height = d.Height;
        shared.MipLevels = 1;
        shared.ArraySize = 1;
        shared.Format = DXGI_FORMAT_B8G8R8A8_UNORM;
        shared.SampleDesc.Count = 1;
        shared.Usage = D3D11_USAGE_DEFAULT;
        shared.BindFlags = D3D11_BIND_RENDER_TARGET | D3D11_BIND_SHADER_RESOURCE;
        shared.MiscFlags = D3D11_RESOURCE_MISC_SHARED;
        
        if(FAILED(m_Dev->CreateTexture2D(&shared, 0, &m_SharedIn))) return false;
        if(cudaGraphicsD3D11RegisterResource(&m_CudaInRes, m_SharedIn.Get(), cudaGraphicsRegisterFlagsNone) != cudaSuccess) return false;
    }

    ComPtr<ID3D11DeviceContext> ctx; 
    m_Dev->GetImmediateContext(&ctx);
    ctx->CopyResource(m_SharedIn.Get(), inTex);
    
    // Map input texture to CUDA
    cudaGraphicsMapResources(1, &m_CudaInRes, m_Stream);
    cudaArray_t inArray;
    cudaGraphicsSubResourceGetMappedArray(&inArray, m_CudaInRes, 0, 0);
    size_t linearPitch = d.Width * 4;
    cudaMemcpy2DFromArrayAsync(m_GBgraIn, linearPitch, inArray, 0, 0, linearPitch, d.Height, cudaMemcpyDeviceToDevice, m_Stream);
    cudaGraphicsUnmapResources(1, &m_CudaInRes, m_Stream);

    // Get AI resolution
    size_t aiW, aiH;
    GetAIResolution(aiW, aiH);
    size_t pSz = aiW * aiH * sizeof(half); 
    char* inPtr = (char*)m_DBufs[0];

    // Preprocess: BGRA → Planar FP16
    LaunchBGRAToPlanarFP16((unsigned char*)m_GBgraIn, inPtr + 3*pSz, (int)d.Width, (int)d.Height, (int)aiW, (int)aiH, (int)d.Width*4, m_Stream);
    
    if(m_FirstFrame) {
        cudaMemcpyAsync(m_Prev, inPtr + 3*pSz, 3*pSz, cudaMemcpyDeviceToDevice, m_Stream);
        m_FirstFrame = false; 
        return false;
    }
    
    cudaMemcpyAsync(inPtr, m_Prev, 3*pSz, cudaMemcpyDeviceToDevice, m_Stream);

    // Set tensor addresses
    if(!m_Engine || !m_Ctx) return false;
    
    int numTensors = m_Engine->getNbIOTensors();
    for(int i=0; i<numTensors; i++) {
        const char* tn = m_Engine->getIOTensorName(i);
        if(!tn) continue;
        if(m_Engine->getTensorIOMode(tn) == nvinfer1::TensorIOMode::kINPUT) {
            m_Ctx->setTensorAddress(tn, m_DBufs[0]);
        } else {
            m_Ctx->setTensorAddress(tn, m_DBufs[2]);
        }
    }
    
    // Time inference
    auto inferStart = std::chrono::high_resolution_clock::now();
    
    if(!m_Ctx->enqueueV3(m_Stream)) return false;

    // Postprocess: Planar FP16 → BGRA, write DIRECTLY to output buffer (ZERO-COPY!)
    LaunchPlanarFP16ToBGRA(m_DBufs[2], (unsigned char*)outputBgra, (int)aiW, (int)aiH, outWidth, outHeight, outPitch, m_Sharpness, m_Stream);
    
    cudaStreamSynchronize(m_Stream);
    
    auto inferEnd = std::chrono::high_resolution_clock::now();
    m_LastInferenceMs = std::chrono::duration<float, std::milli>(inferEnd - inferStart).count();
    
    // Auto-quality adjustment: toggle between 80% and 100%
    if(m_AutoQuality) {
        float targetMs = 1000.0f / m_TargetFPS;
        float headroom = targetMs - m_LastInferenceMs;
        
        if(headroom > 5.0f && m_Quality == AIQuality::QUALITY_80) {
            m_Quality = AIQuality::QUALITY_100;
        } else if(headroom < -2.0f && m_Quality == AIQuality::QUALITY_100) {
            m_Quality = AIQuality::QUALITY_80;
        }
    }
    
    cudaMemcpyAsync(m_Prev, inPtr + 3*pSz, 3*pSz, cudaMemcpyDeviceToDevice, m_Stream);
    return true;
}

void InferenceEngine::GetAIResolution(size_t& w, size_t& h) {
    // Simplified: 80% for performance, 100% for quality
    float scale = (m_Quality == AIQuality::QUALITY_100) ? 1.00f : 0.80f;
    
    if(m_Enable4K) {
        w = (size_t)(3840 * scale);
        h = (size_t)(2160 * scale);
    } else {
        w = (size_t)(1920 * scale);
        h = (size_t)(1080 * scale);
    }
    
    // Round to multiple of 32 for neural network compatibility
    w = (w / 32) * 32;
    h = (h / 32) * 32;
}

void InferenceEngine::Reset() {
    // Clean up CUDA resources for restart
    if(m_CudaInRes) { cudaGraphicsUnregisterResource(m_CudaInRes); m_CudaInRes = nullptr; }
    if(m_CudaOutRes) { cudaGraphicsUnregisterResource(m_CudaOutRes); m_CudaOutRes = nullptr; }
    
    m_SharedIn.Reset();
    m_SharedOut.Reset();
    
    // Free GPU buffers
    for(int i = 0; i < 3; i++) {
        if(m_DBufs[i]) { cudaFree(m_DBufs[i]); m_DBufs[i] = nullptr; }
    }
    if(m_Prev) { cudaFree(m_Prev); m_Prev = nullptr; }
    if(m_GBgraIn) { cudaFree(m_GBgraIn); m_GBgraIn = nullptr; }
    if(m_GBgraOut) { cudaFree(m_GBgraOut); m_GBgraOut = nullptr; }
    
    // Reset TensorRT (keep runtime, release engine/context)
    m_Ctx.reset();
    m_Engine.reset();
    
    // Reset state
    m_FirstFrame = true;
    m_Lw = 0;
    m_Lh = 0;
    
    // Sync CUDA
    if(m_Stream) cudaStreamSynchronize(m_Stream);
}
