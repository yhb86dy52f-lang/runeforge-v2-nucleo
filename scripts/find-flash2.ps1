$ErrorActionPreference = "Continue"
$root = "C:\RUNEFORGE_V2_CORE"

Write-Host "=== Buscando flash.ps1 en todo $root ===" -ForegroundColor Cyan
$hits = Get-ChildItem $root -Recurse -Filter "flash.ps1" -EA SilentlyContinue
if ($hits) {
    $hits | Select-Object FullName, @{n='KB';e={[math]::Round($_.Length/1KB,1)}}, LastWriteTime |
        Format-Table -AutoSize
} else {
    Write-Host "[X] No existe flash.ps1 en $root" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Buscando cualquier *.ps1 con 'flash' o 'arduino' en el nombre ===" -ForegroundColor Cyan
Get-ChildItem $root -Recurse -Include "*flash*.ps1","*arduino*.ps1","*esptool*.ps1" -EA SilentlyContinue |
    Select-Object FullName, @{n='KB';e={[math]::Round($_.Length/1KB,1)}}, LastWriteTime |
    Format-Table -AutoSize

Write-Host ""
Write-Host "=== Historial de comandos con flash.ps1 ===" -ForegroundColor Cyan
$histFile = (Get-PSReadlineOption).HistorySavePath
if (Test-Path $histFile) {
    Get-Content $histFile | Select-String -Pattern "flash\.ps1" -SimpleMatch |
        Select-Object -Last 20
} else {
    Write-Host "Sin historial PSReadline" -ForegroundColor Yellow
}