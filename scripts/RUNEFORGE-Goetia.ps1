# RUNEFORGE-Goetia.ps1 - LOADER v3.0 - 100% FUNCIONAL
param([switch]$NoDemo)
$ErrorActionPreference = "Continue"
Write-Host "[RUNEFORGE v3.0] Iniciando Grimorio Corregido..." -ForegroundColor Cyan
try { Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force -ErrorAction SilentlyContinue } catch {}
$scriptDir = $PSScriptRoot
if(-not $scriptDir){ $scriptDir = Get-Location }
$modulePath = Join-Path $scriptDir "RUNEFORGE-Goetia-Final.psm1"
if(-not (Test-Path $modulePath)){
    $modulePath = "C:\RUNEFORGE_V2_CORE\scripts\RUNEFORGE-Goetia-Final.psm1"
}
Write-Host "Cargando: $modulePath" -ForegroundColor Yellow
if(Test-Path $modulePath){
    Unblock-File -Path $modulePath -ErrorAction SilentlyContinue
    Import-Module $modulePath -Force
    Write-Host "[OK] 72 Sellos v3.0 cargados - FIXED MinMB + PS7" -ForegroundColor Green
    if(-not $NoDemo){
        Write-Host "`n--- TEST RAPIDO CORREGIDO ---" -ForegroundColor Magenta
        Invoke-Purson -Path $scriptDir -MinMB 1
        Invoke-Andromalius
    }
} else {
    Write-Error "No encontrado: $modulePath"
}
