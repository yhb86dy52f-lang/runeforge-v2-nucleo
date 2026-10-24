@echo off
REM ============================================================
REM  OPEN FRAME GEN - Release Build Script
REM  Auto-initializes VS 2022 environment, no manual steps needed
REM ============================================================
setlocal enabledelayedexpansion

echo.
echo ========================================
echo    Open Frame Gen - Release Builder
echo ========================================
echo.

REM ---- Locate vcvarsall.bat ----
set "VS_PATH="
for %%P in (
    "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat"
    "C:\Program Files\Microsoft Visual Studio\2022\Professional\VC\Auxiliary\Build\vcvarsall.bat"
    "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvarsall.bat"
) do (
    if exist %%P (
        set "VS_PATH=%%~P"
        goto :found_vs
    )
)
echo [!] Could not find Visual Studio 2022 vcvarsall.bat
echo [!] Install Visual Studio 2022 with "Desktop development with C++" workload
pause
exit /b 1

:found_vs
echo [+] Found Visual Studio: %VS_PATH%

REM ---- Initialize VS x64 environment if cl.exe not already in PATH ----
where cl.exe >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo [*] Initializing VS x64 environment...
    call "%VS_PATH%" x64
    if %ERRORLEVEL% neq 0 (
        echo [!] Failed to initialize VS environment
        pause
        exit /b 1
    )
) else (
    echo [+] VS environment already initialized
)

REM ---- Check nvcc ----
where nvcc.exe >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo [!] CUDA nvcc not found! Install CUDA Toolkit 13.x from:
    echo     https://developer.nvidia.com/cuda-downloads
    pause
    exit /b 1
)
echo [+] CUDA nvcc found

REM ---- Check TensorRT SDK ----
set "SCRIPT_DIR=%~dp0"
set "TRT_ROOT=%SCRIPT_DIR%..\TensorRT"

if not exist "%TRT_ROOT%\include\NvInfer.h" (
    echo [!] TensorRT headers not found at: %TRT_ROOT%\include\NvInfer.h
    goto :trt_missing
)
echo [+] TensorRT headers found: %TRT_ROOT%\include

if not exist "%TRT_ROOT%\lib\nvinfer.lib" if not exist "%TRT_ROOT%\lib\nvinfer_10.lib" (
    echo.
    echo [!] TensorRT lib files NOT found at: %TRT_ROOT%\lib\nvinfer.lib or nvinfer_10.lib
    goto :trt_libs_missing
)
echo [+] TensorRT libs found: %TRT_ROOT%\lib

goto :do_build

:trt_missing
echo.
echo ================================================================
echo   MISSING: TensorRT SDK (headers + libs)
echo ================================================================
echo   The 'TensorRT' folder in the repo only has the source code.
echo   You need the BINARY SDK (ZIP package from NVIDIA).
echo.
echo   Steps:
echo   1. Go to: https://developer.nvidia.com/tensorrt/download
echo   2. Download: TensorRT 10.x.x.x for Windows, CUDA 12.x, ZIP
echo   3. Extract the ZIP - you'll get a folder like:
echo      TensorRT-10.x.x.x.Windows.win10.cuda-12.x
echo   4. Copy its contents into:
echo      %TRT_ROOT%\
echo      (So that %TRT_ROOT%\lib\nvinfer.lib exists)
echo ================================================================
echo.
pause
exit /b 1

:trt_libs_missing
echo.
echo ================================================================
echo   MISSING: TensorRT .lib files (headers found, libs missing)
echo ================================================================
echo   The 'TensorRT' folder has headers but no compiled libraries.
echo   You need to add the lib/ folder from the NVIDIA binary SDK.
echo.
echo   Steps:
echo   1. Go to: https://developer.nvidia.com/tensorrt/download
echo   2. Download: TensorRT 10.x.x.x for Windows, CUDA 12.x, ZIP
echo   3. From the extracted ZIP, copy the 'lib' folder to:
echo      %TRT_ROOT%\lib\
echo      (So that %TRT_ROOT%\lib\nvinfer.lib exists)
echo   4. Also copy the DLLs (nvinfer_10.dll etc.) to the same lib\
echo ================================================================
echo.
pause
exit /b 1

:do_build
REM ---- Clean and create build dir ----
if exist "%SCRIPT_DIR%build" (
    echo [0/4] Cleaning previous build...
    rmdir /s /q "%SCRIPT_DIR%build"
)
mkdir "%SCRIPT_DIR%build"
cd /d "%SCRIPT_DIR%build"

echo [1/4] Configuring CMake (Release)...
cmake .. -G "Visual Studio 17 2022" -A x64 ^
    -DCMAKE_BUILD_TYPE=Release ^
    -DTENSORRT_ROOT="%TRT_ROOT%"
if %ERRORLEVEL% neq 0 (
    echo [!] CMake configuration failed!
    cd ..
    pause
    exit /b 1
)

echo [2/4] Building Release configuration...
cmake --build . --config Release --parallel
if %ERRORLEVEL% neq 0 (
    echo [!] Build failed! Check the error messages above.
    cd ..
    pause
    exit /b 1
)

echo [3/4] Copying model file...
if exist "%SCRIPT_DIR%..\checkpoints\nano_v16.onnx" (
    copy "%SCRIPT_DIR%..\checkpoints\nano_v16.onnx" "Release\" >nul
    echo     - nano_v16.onnx copied
) else (
    echo [!] Warning: nano_v16.onnx not found in checkpoints\
)
if exist "%SCRIPT_DIR%..\checkpoints\nano_v16.onnx.engine" (
    copy "%SCRIPT_DIR%..\checkpoints\nano_v16.onnx.engine" "Release\" >nul
    echo     - nano_v16.onnx.engine (cached TRT engine) copied
)

echo [4/4] Copying TensorRT DLLs to Release...
if exist "%TRT_ROOT%\bin\nvinfer_10.dll" (
    copy "%TRT_ROOT%\bin\*.dll" "Release\" >nul
    echo     - TensorRT DLLs copied from bin\
) else if exist "%TRT_ROOT%\lib\nvinfer_10.dll" (
    copy "%TRT_ROOT%\lib\*.dll" "Release\" >nul
    echo     - TensorRT DLLs copied from lib\
) else (
    echo [!] Warning: TensorRT DLLs not found. Copy them manually to:
    echo     %SCRIPT_DIR%build\Release\
)

cd ..

echo.
echo ========================================
echo   Build Complete!
echo ========================================
echo.
echo Executable: %SCRIPT_DIR%build\Release\OpenFrameGen.exe
echo.
echo To run:
echo   1. Ensure nano_v16.onnx is in the Release folder
echo   2. Ensure TensorRT DLLs are in the Release folder
echo   3. Launch OpenFrameGen.exe
echo   4. Press Ctrl+Shift+O to toggle overlay
echo.
pause
