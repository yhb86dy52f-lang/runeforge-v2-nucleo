cmake_minimum_required(VERSION 3.18)

project(OpenFrameGen LANGUAGES CXX CUDA)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CUDA_STANDARD 17)
set(CMAKE_CUDA_STANDARD_REQUIRED ON)

# TensorRT location - check for 'TensorRT' or 'TensorRT-10' at repo root
if(NOT TENSORRT_ROOT)
    if(EXISTS "${CMAKE_SOURCE_DIR}/../TensorRT/include/NvInfer.h")
        set(TENSORRT_ROOT "${CMAKE_SOURCE_DIR}/../TensorRT" CACHE PATH "Path to TensorRT root directory" FORCE)
    elseif(EXISTS "${CMAKE_SOURCE_DIR}/../TensorRT-10/include/NvInfer.h")
        set(TENSORRT_ROOT "${CMAKE_SOURCE_DIR}/../TensorRT-10" CACHE PATH "Path to TensorRT root directory" FORCE)
    else()
        set(TENSORRT_ROOT "${CMAKE_SOURCE_DIR}/../TensorRT" CACHE PATH "Path to TensorRT root directory")
    endif()
endif()

if(NOT EXISTS "${TENSORRT_ROOT}/include/NvInfer.h")
    message(FATAL_ERROR "TensorRT headers not found at ${TENSORRT_ROOT}/include/NvInfer.h\n"
        "Please set TENSORRT_ROOT to your TensorRT SDK path (must have include/ and lib/ folders).\n"
        "Download the TensorRT 10 Windows ZIP from: https://developer.nvidia.com/tensorrt/download")
endif()

message(STATUS "Using TensorRT from: ${TENSORRT_ROOT}")

# Find TensorRT lib directory - TRT10 uses versioned names (nvinfer_10.lib)
if(EXISTS "${TENSORRT_ROOT}/lib/nvinfer_10.lib")
    set(TENSORRT_LIB_DIR "${TENSORRT_ROOT}/lib")
    set(TRT_LIBS nvinfer_10 nvonnxparser_10 nvinfer_plugin_10)
elseif(EXISTS "${TENSORRT_ROOT}/lib/nvinfer.lib")
    set(TENSORRT_LIB_DIR "${TENSORRT_ROOT}/lib")
    set(TRT_LIBS nvinfer nvonnxparser nvinfer_plugin)
elseif(EXISTS "${TENSORRT_ROOT}/lib/x64/nvinfer_10.lib")
    set(TENSORRT_LIB_DIR "${TENSORRT_ROOT}/lib/x64")
    set(TRT_LIBS nvinfer_10 nvonnxparser_10 nvinfer_plugin_10)
elseif(EXISTS "${TENSORRT_ROOT}/lib/x64/nvinfer.lib")
    set(TENSORRT_LIB_DIR "${TENSORRT_ROOT}/lib/x64")
    set(TRT_LIBS nvinfer nvonnxparser nvinfer_plugin)
elseif(EXISTS "${TENSORRT_ROOT}/lib")
    set(TENSORRT_LIB_DIR "${TENSORRT_ROOT}/lib")
    set(TRT_LIBS nvinfer_10 nvonnxparser_10 nvinfer_plugin_10)
    message(WARNING "TensorRT lib dir found but nvinfer_10.lib missing - link will fail!\n"
        "Place nvinfer_10.lib, nvonnxparser_10.lib, nvinfer_plugin_10.lib in: ${TENSORRT_ROOT}/lib")
else()
    message(FATAL_ERROR "TensorRT lib directory not found at ${TENSORRT_ROOT}/lib\n"
        "Download the TensorRT 10 Windows ZIP from: https://developer.nvidia.com/tensorrt/download\n"
        "Extract and place lib/ folder inside: ${TENSORRT_ROOT}/")
endif()
message(STATUS "TensorRT lib dir: ${TENSORRT_LIB_DIR}")

find_package(CUDAToolkit REQUIRED)

add_executable(OpenFrameGen
    src/main.cpp
    src/CaptureEngine.cpp
    src/InferenceEngine.cpp
    src/OverlayWindow.cpp
    src/SharedDevice.cpp
    src/kernels.cu
    include/CaptureEngine.h
    include/InferenceEngine.h
    include/OverlayWindow.h
    include/SharedDevice.h
)

target_include_directories(OpenFrameGen PRIVATE
    "${CMAKE_SOURCE_DIR}/include"
    "${TENSORRT_ROOT}/include"
    ${CUDAToolkit_INCLUDE_DIRS}
)

target_link_directories(OpenFrameGen PRIVATE "${TENSORRT_LIB_DIR}")

target_link_libraries(OpenFrameGen PRIVATE
    d3d11
    dxgi
    dwmapi
    comctl32
    CUDA::cudart
    CUDA::cuda_driver
    ${TRT_LIBS}
)

set_property(TARGET OpenFrameGen PROPERTY CUDA_SEPARABLE_COMPILATION ON)
target_compile_definitions(OpenFrameGen PRIVATE NOMINMAX WIN32_LEAN_AND_MEAN)
