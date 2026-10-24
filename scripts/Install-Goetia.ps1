
# Instalador Goetia - Ejecutar en PowerShell como Administrador si quieres instalar global
$ErrorActionPreference = "Stop"
Write-Host "[RUNEFORGE] Instalando Grimorio Goetia..." -ForegroundColor Cyan

# Desbloquear archivo (Windows marca como de internet)
try { Unblock-File -Path $PSScriptRoot\Goetia-PowerShell-Completo.psm1 -ErrorAction SilentlyContinue } catch {}

# Bypass temporal de ExecutionPolicy solo para este proceso
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# Importar con ruta absoluta
$modPath = Join-Path $PSScriptRoot "Goetia-PowerShell-Completo.psm1"
if(-not (Test-Path $modPath)){
    $modPath = Join-Path (Get-Location) "Goetia-PowerShell-Completo.psm1"
}
Write-Host "Cargando desde: $modPath" -ForegroundColor Yellow
Import-Module $modPath -Force -Verbose

Write-Host "OK - Prueba: Get-GoetiaPrompt -Id 26" -ForegroundColor Green
Get-GoetiaPrompt -Id 26
