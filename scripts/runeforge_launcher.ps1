# ============================================================
#  RUNEFORGE LAUNCHER
#  Inicia Ollama, backend Fastify y relay WhatsApp.
#  Verifica dependencias y puertos.
# ============================================================
$ErrorActionPreference = "Continue"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir
Write-Host "`n===========================================" -ForegroundColor Cyan
Write-Host "   RUNEFORGE LAUNCHER v2.6.2" -ForegroundColor Cyan
Write-Host "===========================================`n" -ForegroundColor Cyan
# ---------- Verificar Node.js ----------
$node = Get-Command node -ErrorAction SilentlyContinue
if (-not $node) {
    Write-Host "[ERROR] Node.js no encontrado. Instalar desde https://nodejs.org" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Node.js: $(node --version)" -ForegroundColor Green
# ---------- Verificar npm ----------
$npm = Get-Command npm -ErrorAction SilentlyContinue
if (-not $npm) {
    Write-Host "[ERROR] npm no encontrado." -ForegroundColor Red
    exit 1
}
# ---------- Ollama ----------
$ollama = Get-Command ollama -ErrorAction SilentlyContinue
if ($ollama) {
    Write-Host "[OK] Ollama instalado." -ForegroundColor Green
    try {
        $status = Invoke-RestMethod -Uri "http://127.0.0.1:11434/api/tags" -TimeoutSec 3 -ErrorAction Stop
        Write-Host "[OK] Ollama servicio activo." -ForegroundColor Green
    } catch {
        Write-Host "[INFO] Iniciando Ollama..." -ForegroundColor Yellow
        Start-Process -FilePath "ollama" -ArgumentList "serve" -WindowStyle Hidden
        Start-Sleep -Seconds 5
        Write-Host "[OK] Ollama iniciado." -ForegroundColor Green
    }
} else {
    Write-Host "[WARN] Ollama no instalado. Instalar desde https://ollama.com" -ForegroundColor Yellow
}
# ---------- Backend (Fastify) ----------
$backendPath = Join-Path $scriptDir "src\backend"
if (Test-Path $backendPath) {
    Write-Host "[INFO] Preparando backend..." -ForegroundColor Yellow
    Push-Location $backendPath
    if (-not (Test-Path "node_modules")) {
        Write-Host "[INFO] Instalando dependencias del backend..." -ForegroundColor Yellow
        npm install --silent
        if ($LASTEXITCODE -ne 0) {
            Write-Host "[ERROR] Falló npm install en backend." -ForegroundColor Red
            Pop-Location
            exit 1
        }
    }
    $port3100 = Get-NetTCPConnection -LocalPort 3100 -ErrorAction SilentlyContinue
    if ($port3100) {
        Write-Host "[OK] Backend ya está corriendo en puerto 3100." -ForegroundColor Green
    } else {
        Write-Host "[INFO] Iniciando backend (puerto 3100)..." -ForegroundColor Yellow
        Start-Process -FilePath "node" -ArgumentList "index.js" -WindowStyle Hidden -WorkingDirectory $backendPath
        Start-Sleep -Seconds 3
        Write-Host "[OK] Backend iniciado." -ForegroundColor Green
    }
    Pop-Location
} else {
    Write-Host "[WARN] Carpeta src\backend no encontrada. Omitiendo backend." -ForegroundColor Yellow
}
# ---------- Relay (WhatsApp) ----------
$relayPath = Join-Path $scriptDir "src\relay"
if (Test-Path $relayPath) {
    Write-Host "[INFO] Preparando relay..." -ForegroundColor Yellow
    Push-Location $relayPath
    if (-not (Test-Path "node_modules")) {
        Write-Host "[INFO] Instalando dependencias del relay..." -ForegroundColor Yellow
        npm install --silent
        if ($LASTEXITCODE -ne 0) {
            Write-Host "[ERROR] Falló npm install en relay." -ForegroundColor Red
            Pop-Location
            exit 1
        }
    }
    $port3198 = Get-NetTCPConnection -LocalPort 3198 -ErrorAction SilentlyContinue
    if ($port3198) {
        Write-Host "[OK] Relay ya está corriendo en puerto 3198." -ForegroundColor Green
    } else {
        Write-Host "[INFO] Iniciando relay (puerto 3198)..." -ForegroundColor Yellow
        Start-Process -FilePath "node" -ArgumentList "index.js" -WindowStyle Hidden -WorkingDirectory $relayPath
        Start-Sleep -Seconds 3
        Write-Host "[OK] Relay iniciado." -ForegroundColor Green
    }
    Pop-Location
} else {
    Write-Host "[WARN] Carpeta src\relay no encontrada. Omitiendo relay." -ForegroundColor Yellow
}
# ---------- Resumen ----------
Write-Host "`n===========================================" -ForegroundColor Cyan
Write-Host "  SERVICIOS INICIADOS" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "  Backend  : http://localhost:3100/dashboard" -ForegroundColor White
Write-Host "  Ollama   : http://localhost:11434" -ForegroundColor White
Write-Host "  Relay    : http://localhost:3198" -ForegroundColor White
Write-Host "===========================================`n" -ForegroundColor Cyan
Write-Host "[CHECK] Probando endpoints..." -ForegroundColor Yellow
try {
    $res = Invoke-RestMethod -Uri "http://localhost:3100/api/ollama/status" -TimeoutSec 2 -ErrorAction Stop
    Write-Host "[OK] Backend responde." -ForegroundColor Green
} catch {
    Write-Host "[WARN] Backend no responde (puede estar iniciando)." -ForegroundColor Yellow
}
try {
    $res = Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -TimeoutSec 2 -ErrorAction Stop
    Write-Host "[OK] Ollama responde." -ForegroundColor Green
} catch {
    Write-Host "[WARN] Ollama no responde (puede estar iniciando)." -ForegroundColor Yellow
}
Write-Host "`nPresiona cualquier tecla para salir..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
