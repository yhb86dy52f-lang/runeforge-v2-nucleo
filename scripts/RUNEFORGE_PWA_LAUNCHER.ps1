 # =====================================================================
# RUNEFORGE_PWA_LAUNCHER.ps1
# Limpia archivos inútiles de Node, audita la red y genera un lanzador
# inteligente en Batch que auto-abre el navegador y advierte de la red.
# =====================================================================

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

$Buf = New-Object System.Collections.Generic.List[string]
function W($m) { $Buf.Add([string]$m) | Out-Null; Write-Host $m }

W "==================================================================="
W " RUNEFORGE · LANZADOR PWA SEGURO · $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
W "==================================================================="

$SimuladorDir = "C:\RUNEFORGE_V2_CORE\runeforge-v2-nucleo\simulador"
Set-Location $SimuladorDir

# ---------- FASE 1: Limpieza de archivos inútiles ----------
W "`n[FASE 1] Limpieza de archivos residuales (Node.js/Env)"
# El .env que creamos no sirve para Python
if (Test-Path ".env") {
    Remove-Item ".env" -Force
    W "  [+] Eliminado .env (Python no lo usa)."
}
if (Test-Path ".gitignore") {
    # Mantener el gitignore pero quitar la regla del .env
    (Get-Content ".gitignore") | Where-Object { $_ -notmatch "^\.env$" -and $_ -notmatch "^$" } | Set-Content ".gitignore"
    W "  [+] Actualizado .gitignore (ya no ignora .env)."
}

# ---------- FASE 2: Auditoría de red ----------
W "`n[FASE 2] Auditoría de exposición de red (0.0.0.0)"
$batPath = Join-Path $SimuladorDir "iniciar_servidor.bat"
if (Test-Path $batPath) {
    $content = Get-Content $batPath -Raw
    if ($content -match "0\.0\.0\.0") {
        W "  [!] ALERTA: El lanzador actual abre el puerto a TODA tu red Wi-Fi."
        W "      Cualquiera en tu misma red puede ver tus archivos si sabe tu IP."
    }
}

# ---------- FASE 3: Creación del Lanzador Inteligente ----------
W "`n[FASE 3] Generando Lanzador Seguro e Inteligente"
$newLauncher = Join-Path $SimuladorDir "Lanzar_RUNEFORGE.bat"

$launcherContent = @"
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
"@

$launcherContent | Set-Content -Path $newLauncher -Encoding ASCII
W "  [+] Creado nuevo lanzador: $newLauncher"

# ---------- RESUMEN ----------
W "`n==================================================================="
W " RESUMEN DE OPERACIÓN"
W "==================================================================="
W " 1. Se limpiaron los archivos residuales de la configuracion Node."
W " 2. Se auditó el riesgo de exponer el servidor en la red Wi-Fi."
W " 3. Se creó un nuevo lanzador que te da a elegir entre Local o Red."
W "    -> Usa siempre 'Lanzar_RUNEFORGE.bat' a partir de ahora."
W "==================================================================="

Set-Clipboard -Value ($Buf -join "`r`n")
Write-Host "`n[OK] Salida copiada al portapapeles (Ctrl+V)."