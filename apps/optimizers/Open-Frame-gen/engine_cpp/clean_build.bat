@echo off
REM ============================================================
REM  CLEAN BUILD - Completely removes old build and rebuilds
REM ============================================================
echo.
echo ========================================
echo    NANO AI PRO - CLEAN BUILD
echo ========================================
echo.

REM Check for Visual Studio
where cl.exe >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo [!] Visual Studio command line tools not found!
    echo [!] Run this from "x64 Native Tools Command Prompt for VS 2022"
    echo.
    pause
    exit /b 1
)

echo [1/5] Completely removing old build directory...
if exist "build" (
    rmdir /s /q build
    echo     - Old build removed
) else (
    echo     - No old build found (fresh start)
)

echo [2/5] Creating fresh build directory...
mkdir build
cd build

echo [3/5] Running CMake (this will take a moment)...
cmake .. -G "Visual Studio 17 2022" -A x64 -DCMAKE_BUILD_TYPE=Release
if %ERRORLEVEL% neq 0 (
    echo.
    echo [!] CMake FAILED!
    echo.
    echo Common issues:
    echo   1. TensorRT folder missing at repo root (see README: download the TensorRT 10 ZIP SDK)
    echo   2. CUDA Toolkit not installed
    echo   3. Wrong command prompt (must be VS x64 Native Tools)
    echo.
    cd ..
    pause
    exit /b 1
)

echo [4/5] Building Release (this may take 5-10 minutes first time)...
cmake --build . --config Release --verbose
if %ERRORLEVEL% neq 0 (
    echo.
    echo [!] BUILD FAILED!
    echo.
    echo Look for errors in the output above.
    echo See the "C++ / TensorRT pipeline" section of the README.
    echo.
    cd ..
    pause
    exit /b 1
)

echo [5/5] Copying required files...
if exist "..\..\checkpoints\nano_v16.onnx" (
    copy "..\..\checkpoints\nano_v16.onnx" "Release\" >nul
    echo     ✓ Model file copied
)

cd ..

echo.
echo ========================================
echo    BUILD SUCCESSFUL!
echo ========================================
echo.
echo Run the app:
echo   cd build\Release
echo   OpenFrameGen.exe
echo.
pause
