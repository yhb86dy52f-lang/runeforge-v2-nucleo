@echo off
title DICTATE Studio
powershell -NoProfile -Command "try { Invoke-RestMethod http://127.0.0.1:8081/health -TimeoutSec 3 | Out-Null } catch { Start-Process wscript.exe -ArgumentList '\"C:\RUNEFORGE_V2_CORE\whisper-backend\start-whisper-hidden.vbs\"'; Start-Sleep -Seconds 15 }"
start "" "C:\RUNEFORGE_V2_CORE\target\release\dictate-studio-v2.exe"
