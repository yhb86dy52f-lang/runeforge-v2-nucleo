# RUNEFORGE LAUNCHER v2.6.2 (corregido)
$ErrorActionPreference = "Continue"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Join-Path $scriptDir ".."
Set-Location $root

Write-Host "Runeforge Launcher - Iniciando servicios..." -ForegroundColor Cyan

$node = Get-Command node -ErrorAction SilentlyContinue
if (-not $node) {
    Write-Host "ERROR: Node.js no instalado." -ForegroundColor Red
    exit 1
}

try {
    $res = Invoke-RestMethod -Uri "http://127.0.0.1:11434/api/tags" -TimeoutSec 2 -ErrorAction Stop
    Write-Host "Ollama activo." -ForegroundColor Green
} catch {
    Write-Host "Ollama no responde. Iniciando..." -ForegroundColor Yellow
    Start-Process ollama -ArgumentList "serve" -WindowStyle Hidden
    Start-Sleep -Seconds 5
}

$backendPath = Join-Path $root "src\backend"
if (Test-Path $backendPath) {
    Push-Location $backendPath
    if (-not (Test-Path "node_modules")) {
        Write-Host "Instalando dependencias del backend..." -ForegroundColor Yellow
        npm install --silent
    }
    $port3100 = Get-NetTCPConnection -LocalPort 3100 -ErrorAction SilentlyContinue
    if (-not $port3100) {
        Write-Host "Iniciando backend en puerto 3100..." -ForegroundColor Yellow
        Start-Process node -ArgumentList "index.js" -WindowStyle Hidden -WorkingDirectory $backendPath
        Start-Sleep -Seconds 3
    }
    Pop-Location
}

$relayPath = Join-Path $root "src\relay"
if (Test-Path $relayPath) {
    Push-Location $relayPath
    if (-not (Test-Path "node_modules")) {
        Write-Host "Instalando dependencias del relay..." -ForegroundColor Yellow
        npm install --silent
    }
    $port3198 = Get-NetTCPConnection -LocalPort 3198 -ErrorAction SilentlyContinue
    if (-not $port3198) {
        Write-Host "Iniciando relay en puerto 3198..." -ForegroundColor Yellow
        Start-Process node -ArgumentList "index.js" -WindowStyle Hidden -WorkingDirectory $relayPath
        Start-Sleep -Seconds 3
    }
    Pop-Location
}

Write-Host "Servicios iniciados." -ForegroundColor Green
