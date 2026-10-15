$ErrorActionPreference = "Continue"
$fw = "C:\RUNEFORGE_V2_CORE\firmware\RUNEFORGE_COLLAB_FINAL_CORREGIDO_v1"

Write-Host "=== Buscando flash.ps1 ===" -ForegroundColor Cyan
$hits = Get-ChildItem $fw -Recurse -Filter "flash.ps1" -EA SilentlyContinue
if ($hits) {
    $hits | Select-Object FullName, Length, LastWriteTime | Format-Table -AutoSize
} else {
    Write-Host "[X] No hay flash.ps1 en ningun lado de $fw" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Estructura de la carpeta firmware ===" -ForegroundColor Cyan
Get-ChildItem "$fw\firmware" -EA SilentlyContinue | Select-Object Mode, Name, Length | Format-Table -AutoSize

Write-Host ""
Write-Host "=== Estructura completa (2 niveles) ===" -ForegroundColor Cyan
Get-ChildItem $fw -Directory | ForEach-Object {
    Write-Host ""
    Write-Host "[$($_.Name)]" -ForegroundColor Yellow
    Get-ChildItem $_.FullName -EA SilentlyContinue | Select-Object Mode, Name, Length | Format-Table -AutoSize
}