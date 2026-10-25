$ErrorActionPreference = "Continue"
$base = "$env:LOCALAPPDATA\Arduino15\packages\esp32\tools\esp32-libs\3.3.12"

Write-Host "=== Nivel 1: $base ===" -ForegroundColor Cyan
Get-ChildItem $base -EA SilentlyContinue | Select-Object Mode, Name, @{n='KB';e={[math]::Round($_.Length/1KB,1)}} | Format-Table -AutoSize

Write-Host ""
Write-Host "=== Nivel 2: $base\esp32-libs ===" -ForegroundColor Cyan
$inner = Join-Path $base 'esp32-libs'
if (Test-Path $inner) {
    Get-ChildItem $inner -EA SilentlyContinue | Select-Object Mode, Name, @{n='KB';e={[math]::Round($_.Length/1KB,1)}} | Format-Table -AutoSize
}

Write-Host ""
Write-Host "=== Buscando bootloader_qio_80m.elf en este arbol ===" -ForegroundColor Cyan
Get-ChildItem $base -Recurse -Filter "bootloader_qio_80m.elf" -EA SilentlyContinue |
    ForEach-Object { Write-Host "  $($_.FullName)  ($([math]::Round($_.Length/1KB,1)) KB)" }

Write-Host ""
Write-Host "=== Buscando carpeta 'bin' dentro ===" -ForegroundColor Cyan
Get-ChildItem $base -Recurse -Directory -Filter "bin" -EA SilentlyContinue |
    ForEach-Object { Write-Host "  $($_.FullName)" }