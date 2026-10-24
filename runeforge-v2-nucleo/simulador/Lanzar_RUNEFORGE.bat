@echo off
title RUNEFORGE - Servidor Seguro
color 0A
echo =======================================================
echo   RUNEFORGE PWA - Iniciando Laboratorio
echo =======================================================
cd /d "%~dp0"

echo Verificando Python...
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Python no esta instalado o no esta en el PATH.
    echo Descargalo en https://www.python.org/downloads/ y marca "Add to PATH".
    pause
    exit /b
)

echo.
echo =======================================================
echo Selecciona el modo de ejecucion:
echo   [1] LOCAL SEGURO (Solo esta PC - Recomendado)
echo   [2] RED WI-FI (Para probar en celular/tablet)
echo =======================================================
set /p opcion="Elige (1 o 2): "

if "%opcion%"=="1" (
    echo.
    echo Iniciando en modo LOCAL (http://127.0.0.1:8080)...
    start "" "http://127.0.0.1:8080"
    python -m http.server 8080 --bind 127.0.0.1
) else if "%opcion%"=="2" (
    echo.
    echo Iniciando en modo RED (Compartido en Wi-Fi)...
    echo [!] CUIDADO: Asegurate de estar en una red de confianza.
    start "" "http://localhost:8080"
    python -m http.server 8080 --bind 0.0.0.0
) else (
    echo Opcion no valida. Saliendo...
    pause
    exit /b
)
pause
