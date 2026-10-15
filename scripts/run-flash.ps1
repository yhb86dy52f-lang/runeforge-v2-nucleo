$ErrorActionPreference = "Continue"
$flash = "C:\RUNEFORGE_V2_CORE\flash.ps1"

Set-Location C:\RUNEFORGE_V2_CORE
Write-Host "=== Ejecutando $flash ===" -ForegroundColor Cyan
Write-Host ""

& $flash
$exit = $LASTEXITCODE

Write-Host ""
if ($exit -eq 0) {
    Write-Host "[OK] flash.ps1 termino con codigo 0" -ForegroundColor Green
} else {
    Write-Host "[!] flash.ps1 termino con codigo $exit" -ForegroundColor Yellow
}