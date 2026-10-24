#include <windows.h>
#include <dwmapi.h>
#include <commctrl.h>
#include <string>
#include <filesystem>
#include "SharedDevice.h"
#include "CaptureEngine.h"
#include "InferenceEngine.h"
#include "OverlayWindow.h"

#pragma comment(lib, "comctl32.lib")
#pragma comment(lib, "dwmapi.lib")

// Global state
CaptureEngine* g_Capture = nullptr;
InferenceEngine* g_Inference = nullptr;
OverlayWindow* g_Overlay = nullptr;

bool g_Running = false;
bool g_SplitMode = false;
bool g_Visible = true;
bool g_FrameLimit = true;
int g_TargetFPS = 144;
float g_Sharpness = 0.6f;

// Control IDs
enum {
    ID_START_STOP = 1,
    ID_SPLIT_MODE,
    ID_FPS_SELECT,
    ID_QUALITY_SELECT,
    ID_SHARPNESS_SLIDER,
    ID_SHARPNESS_LABEL,
    ID_OBS_PREVIEW,
    ID_FRAME_LIMIT
};

// Main window procedure
LRESULT CALLBACK MainWndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    static HWND hStartBtn, hSplitCheck, hFpsList, hQualityList, hSharpSlider, hSharpLabel, hObsCheck, hLimitCheck;
    
    switch (msg) {
    case WM_CREATE: {
        HINSTANCE hInst = GetModuleHandleA(nullptr);
        InitCommonControls();
        
        // Title/Mode indicator
        CreateWindowA("STATIC", "NANO AI - Fullscreen Mode", WS_CHILD | WS_VISIBLE | SS_CENTER,
            10, 10, 245, 20, hwnd, nullptr, hInst, nullptr);
        
        // FPS selection
        CreateWindowA("STATIC", "Target FPS:", WS_CHILD | WS_VISIBLE,
            10, 40, 70, 20, hwnd, nullptr, hInst, nullptr);
        hFpsList = CreateWindowA("COMBOBOX", "", WS_CHILD | WS_VISIBLE | CBS_DROPDOWNLIST,
            80, 38, 60, 100, hwnd, (HMENU)ID_FPS_SELECT, hInst, nullptr);
        SendMessageA(hFpsList, CB_ADDSTRING, 0, (LPARAM)"60");
        SendMessageA(hFpsList, CB_ADDSTRING, 0, (LPARAM)"120");
        SendMessageA(hFpsList, CB_ADDSTRING, 0, (LPARAM)"144");
        SendMessageA(hFpsList, CB_ADDSTRING, 0, (LPARAM)"Uncapped");
        SendMessageA(hFpsList, CB_SETCURSEL, 2, 0);
        
        // Quality selection
        CreateWindowA("STATIC", "Quality:", WS_CHILD | WS_VISIBLE,
            150, 40, 50, 20, hwnd, nullptr, hInst, nullptr);
        hQualityList = CreateWindowA("COMBOBOX", "", WS_CHILD | WS_VISIBLE | CBS_DROPDOWNLIST,
            200, 38, 55, 100, hwnd, (HMENU)ID_QUALITY_SELECT, hInst, nullptr);
        SendMessageA(hQualityList, CB_ADDSTRING, 0, (LPARAM)"80%");
        SendMessageA(hQualityList, CB_ADDSTRING, 0, (LPARAM)"100%");
        SendMessageA(hQualityList, CB_SETCURSEL, 0, 0);
        
        // Sharpness slider
        CreateWindowA("STATIC", "Sharpness:", WS_CHILD | WS_VISIBLE,
            10, 70, 60, 20, hwnd, nullptr, hInst, nullptr);
        hSharpSlider = CreateWindowA(TRACKBAR_CLASSA, "", WS_CHILD | WS_VISIBLE | TBS_HORZ,
            70, 68, 130, 25, hwnd, (HMENU)ID_SHARPNESS_SLIDER, hInst, nullptr);
        SendMessageA(hSharpSlider, TBM_SETRANGE, TRUE, MAKELONG(0, 100));
        SendMessageA(hSharpSlider, TBM_SETPOS, TRUE, 60);
        hSharpLabel = CreateWindowA("STATIC", "0.60", WS_CHILD | WS_VISIBLE,
            205, 70, 40, 20, hwnd, (HMENU)ID_SHARPNESS_LABEL, hInst, nullptr);
        
        // Split mode checkbox
        hSplitCheck = CreateWindowA("BUTTON", "Split Screen", 
            WS_CHILD | WS_VISIBLE | BS_AUTOCHECKBOX,
            10, 95, 100, 25, hwnd, (HMENU)ID_SPLIT_MODE, hInst, nullptr);
        
        // OBS Preview checkbox
        hObsCheck = CreateWindowA("BUTTON", "OBS Preview", 
            WS_CHILD | WS_VISIBLE | BS_AUTOCHECKBOX,
            115, 95, 100, 25, hwnd, (HMENU)ID_OBS_PREVIEW, hInst, nullptr);
        
        // Frame limit checkbox (checked by default)
        hLimitCheck = CreateWindowA("BUTTON", "Limit FPS", 
            WS_CHILD | WS_VISIBLE | BS_AUTOCHECKBOX,
            10, 120, 80, 25, hwnd, (HMENU)ID_FRAME_LIMIT, hInst, nullptr);
        SendMessageA(hLimitCheck, BM_SETCHECK, BST_CHECKED, 0);
        
        // Start button
        hStartBtn = CreateWindowA("BUTTON", "START", WS_CHILD | WS_VISIBLE | BS_DEFPUSHBUTTON,
            95, 120, 160, 30, hwnd, (HMENU)ID_START_STOP, hInst, nullptr);
        
        // Register hotkey: Ctrl+Shift+O to toggle overlay
        RegisterHotKey(hwnd, 1, MOD_CONTROL | MOD_SHIFT, 'O');
        break;
    }
    
    case WM_HSCROLL:
        // Sharpness slider
        if ((HWND)lParam == hSharpSlider) {
            int pos = (int)SendMessageA(hSharpSlider, TBM_GETPOS, 0, 0);
            g_Sharpness = pos / 100.0f;
            char buf[16];
            sprintf_s(buf, "%.2f", g_Sharpness);
            SetWindowTextA(hSharpLabel, buf);
            if (g_Inference) g_Inference->SetSharpness(g_Sharpness);
        }
        break;
    
    case WM_HOTKEY:
        if (wParam == 1 && g_Overlay) {
            g_Visible = !g_Visible;
            g_Overlay->SetVisible(g_Visible);
        }
        break;
    
    case WM_COMMAND:
        switch (LOWORD(wParam)) {
        case ID_FPS_SELECT: {
            int idx = (int)SendMessageA(hFpsList, CB_GETCURSEL, 0, 0);
            const int fps[] = {60, 120, 144, 0};
            if (idx >= 0 && idx < 4) {
                if (fps[idx] == 0) {
                    g_FrameLimit = false;
                    SendMessageA(hLimitCheck, BM_SETCHECK, BST_UNCHECKED, 0);
                } else {
                    g_TargetFPS = fps[idx];
                    g_FrameLimit = true;
                    SendMessageA(hLimitCheck, BM_SETCHECK, BST_CHECKED, 0);
                }
            }
            break;
        }
        
        case ID_SPLIT_MODE:
            g_SplitMode = (SendMessageA(hSplitCheck, BM_GETCHECK, 0, 0) == BST_CHECKED);
            break;
        
        case ID_OBS_PREVIEW:
            if (g_Overlay) {
                bool enable = (SendMessageA(hObsCheck, BM_GETCHECK, 0, 0) == BST_CHECKED);
                g_Overlay->EnablePreviewWindow(enable);
            }
            break;
        
        case ID_FRAME_LIMIT: {
            g_FrameLimit = (SendMessageA(hLimitCheck, BM_GETCHECK, 0, 0) == BST_CHECKED);
            if (!g_FrameLimit) {
                SendMessageA(hFpsList, CB_SETCURSEL, 3, 0); // "Uncapped"
            } else {
                // If they re-check it while uncapped, revert to 144
                int idx = (int)SendMessageA(hFpsList, CB_GETCURSEL, 0, 0);
                if (idx == 3) {
                    SendMessageA(hFpsList, CB_SETCURSEL, 2, 0); // "144"
                    g_TargetFPS = 144;
                }
            }
            break;
        }
        
        case ID_START_STOP:
            if (!g_Running) {
                // Set quality (0=80%, 1=100%)
                int qIdx = (int)SendMessageA(hQualityList, CB_GETCURSEL, 0, 0);
                AIQuality quality = (qIdx == 1) ? AIQuality::QUALITY_100 : AIQuality::QUALITY_80;
                g_Inference->SetQuality(quality);
                g_Inference->SetSharpness(g_Sharpness);
                
                // Find model file - always look relative to the exe's own directory
                char exePath[MAX_PATH] = {};
                GetModuleFileNameA(nullptr, exePath, MAX_PATH);
                std::filesystem::path exeDir = std::filesystem::path(exePath).parent_path();
                std::filesystem::path modelPath = exeDir / "nano_v16.onnx";
                if (!std::filesystem::exists(modelPath)) {
                    std::string msg = "Cannot find nano_v16.onnx!\nExpected at:\n" + modelPath.string();
                    MessageBoxA(hwnd, msg.c_str(), "Error", MB_ICONERROR);
                    break;
                }
                
                // Initialize model
                if (!g_Inference->LoadModel(modelPath.string(), SharedDevice::Get().Device())) {
                    MessageBoxA(hwnd, "Failed to load AI model!", "Error", MB_ICONERROR);
                    break;
                }
                
                // Initialize fullscreen capture (nullptr = entire screen)
                if (!g_Capture->Init(nullptr, 0)) {
                    MessageBoxA(hwnd, "Failed to initialize capture!", "Error", MB_ICONERROR);
                    break;
                }
                
                HMONITOR hMon = MonitorFromWindow(hwnd, MONITOR_DEFAULTTOPRIMARY);
                if (!g_Overlay->Init(hMon)) {
                    MessageBoxA(hwnd, "Failed to create overlay!", "Error", MB_ICONERROR);
                    break;
                }
                
                g_Running = true;
                g_Visible = true;
                g_Overlay->SetVisible(true);
                SetWindowTextA(hStartBtn, "STOP");
                EnableWindow(hQualityList, FALSE);
            } else {
                // STOP - clean up for restart
                g_Running = false;
                g_Overlay->SetVisible(false);
                
                // Reset engines for clean restart
                g_Capture->Reset();
                g_Inference->Reset();
                
                SetWindowTextA(hStartBtn, "START");
                EnableWindow(hQualityList, TRUE);
            }
            break;
        }
        break;
    
    case WM_DESTROY:
        UnregisterHotKey(hwnd, 1);
        PostQuitMessage(0);
        break;
    
    default:
        return DefWindowProcA(hwnd, msg, wParam, lParam);
    }
    return 0;
}

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE, LPSTR, int) {
    // Initialize D3D11
    if (!SharedDevice::Get().Init()) {
        MessageBoxA(nullptr, "Failed to initialize D3D11!", "Error", MB_ICONERROR);
        return 1;
    }
    
    // Create components
    g_Capture = new CaptureEngine();
    g_Inference = new InferenceEngine();
    g_Overlay = new OverlayWindow();
    
    // Create control window
    WNDCLASSA wc = {};
    wc.lpfnWndProc = MainWndProc;
    wc.hInstance = hInstance;
    wc.lpszClassName = "NANOControl";
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
    wc.hCursor = LoadCursor(nullptr, IDC_ARROW);
    RegisterClassA(&wc);
    
    HWND hMain = CreateWindowA("NANOControl", "NANO AI",
        WS_OVERLAPPEDWINDOW & ~WS_MAXIMIZEBOX & ~WS_THICKFRAME,
        CW_USEDEFAULT, CW_USEDEFAULT, 280, 200,
        nullptr, nullptr, hInstance, nullptr);
    ShowWindow(hMain, SW_SHOW);
    
    // Frame timing - use high resolution timer
    LARGE_INTEGER freq, frameStart, now;
    QueryPerformanceFrequency(&freq);
    QueryPerformanceCounter(&frameStart);
    
    int frameCount = 0, captureCount = 0;
    float outputFps = 0, inputFps = 0;
    double fpsTimer = 0;
    LARGE_INTEGER lastFpsUpdate = frameStart;
    
    // Main loop
    MSG msg = {};
    while (msg.message != WM_QUIT) {
        if (PeekMessageA(&msg, nullptr, 0, 0, PM_REMOVE)) {
            TranslateMessage(&msg);
            DispatchMessageA(&msg);
            continue;
        }
        
        if (g_Running) {
            // Capture frame
            ID3D11Texture2D* capturedFrame = nullptr;
            if (g_Capture->CaptureNextFrame(&capturedFrame)) {
                captureCount++;
                
                // Run AI inference
                ID3D11Texture2D* aiFrame = nullptr;
                bool hasAI = g_Inference->RunInference(capturedFrame, &aiFrame);
                
                if (g_SplitMode && hasAI) {
                    // Split mode: left=original, right=AI
                    g_Overlay->RenderSplit(capturedFrame, aiFrame);
                    g_Overlay->Present();
                    frameCount++;
                } else if (hasAI) {
                    // Frame interpolation mode: display BOTH frames for 2x boost
                    // First: display the original captured frame
                    g_Overlay->Render(capturedFrame);
                    g_Overlay->Present();
                    frameCount++;
                    
                    // Second: display the AI-interpolated frame
                    g_Overlay->Render(aiFrame);
                    g_Overlay->Present();
                    frameCount++;
                } else {
                    // No AI yet (first frame) - just show original
                    g_Overlay->Render(capturedFrame);
                    g_Overlay->Present();
                    frameCount++;
                }
                
                // Cleanup
                if (aiFrame) aiFrame->Release();
                capturedFrame->Release();
            }
            
            // Update FPS counter every second
            QueryPerformanceCounter(&now);
            double elapsed = (double)(now.QuadPart - lastFpsUpdate.QuadPart) / freq.QuadPart;
            
            if (elapsed >= 1.0) {
                outputFps = (float)(frameCount / elapsed);
                inputFps = (float)(captureCount / elapsed);
                frameCount = 0;
                captureCount = 0;
                lastFpsUpdate = now;
                g_Overlay->UpdateStats(outputFps, inputFps, g_SplitMode);
            }
            
            // Frame pacing - sync to target refresh rate
            if (g_FrameLimit) {
                double targetFrameTime = 1.0 / g_TargetFPS;
                
                // Calculate time since frame started
                QueryPerformanceCounter(&now);
                double frameTime = (double)(now.QuadPart - frameStart.QuadPart) / freq.QuadPart;
                double remaining = targetFrameTime - frameTime;
                
                if (remaining > 0) {
                    // Sleep most of the way (leave 1.5ms for precision)
                    if (remaining > 0.0015) {
                        Sleep((DWORD)((remaining - 0.0015) * 1000));
                    }
                    
                    // Spin-wait for precise timing
                    do {
                        QueryPerformanceCounter(&now);
                        frameTime = (double)(now.QuadPart - frameStart.QuadPart) / freq.QuadPart;
                    } while (frameTime < targetFrameTime);
                }
                
                // Sync with desktop compositor for tear-free display
                DwmFlush();
            }
            
            // Mark frame start for next iteration
            QueryPerformanceCounter(&frameStart);
        } else {
            Sleep(16);  // Idle when not running
        }
        
        g_Overlay->ProcessMessages();
    }
    
    // Cleanup
    delete g_Overlay;
    delete g_Inference;
    delete g_Capture;
    
    return (int)msg.wParam;
}
