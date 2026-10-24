@echo off
title RUNEFORGE - AUDITORIA DE SISTEMA
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\RUNEFORGE_V2_CORE\scripts\AUDIT.ps1"
echo.
echo [*] Presiona cualquier tecla para salir.
pause >nul