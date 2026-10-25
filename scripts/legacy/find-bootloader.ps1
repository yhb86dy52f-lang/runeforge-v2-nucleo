$ErrorActionPreference = "Continue"
$libsBase = "$env:LOCALAPPDATA\Arduino15\packages\esp32\tools\esp32-libs\3.3.12"

Write-Host "=== Buscando bootloader_qio_80m.elf en esp32-libs\3.3.12 ===" -ForegroundColor Cyan
$found = Get-ChildItem $libsBase -Recurse -Filter "bootloader_qio_80m.elf" -EA SilentlyContinue
if ($found) {
    $found | Select-Object FullName, Length | Format-Table -AutoSize
} else {
    Write-Host "[X] No existe en esp32-libs\3.3.12" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Buscando bootloader_qio_80m.elf en TODO Arduino15 ===" -ForegroundColor Cyan
$all = Get-ChildItem "$env:LOCALAPPDATA\Arduino15" -Recurse -Filter "bootloader_qio_80m.elf" -EA SilentlyContinue
if ($all) {
    $all | Select-Object FullName, Length | Format-Table -AutoSize
} else {
    Write-Host "[X] No existe en ningun lado" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Buscando bootloader_*.elf en esp32-libs\3.3.12\bin ===" -ForegroundColor Cyan
$binDir = "$libsBase\bin"
if (Test-Path $binDir) {
    Get-ChildItem $binDir -Filter "bootloader*.elf" -EA SilentlyContinue | Select-Object Name, Length | Format-Table -AutoSize
} else {
    Write-Host "[X] No existe $binDir" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Estructura de esp32-libs\3.3.12 ===" -ForegroundColor Cyan
Get-ChildItem $libsBase -Directory -EA SilentlyContinue | Select-Object Name | Format-Table -AutoSize