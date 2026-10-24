$ErrorActionPreference = "Continue"
$esp = "$env:LOCALAPPDATA\Arduino15\packages\esp32\tools\esptool_py\5.3.1\esptool.exe"
$sketch = "$env:LOCALAPPDATA\arduino\sketches"

# Localizar los bins compilados (el más reciente)
$build = Get-ChildItem $sketch -Directory -EA SilentlyContinue |
    Where-Object { Test-Path "$($_.FullName)\ScannerPRO_v9_COLLAB.ino.bin" } |
    Sort-Object LastWriteTime -Descending | Select-Object -First 1

if (-not $build) { Write-Host "[X] No encontré build con ScannerPRO_v9_COLLAB.ino.bin" -ForegroundColor Red; exit 1 }
Write-Host "[OK] Build: $($build.FullName)" -ForegroundColor Green

$boot = "$($build.FullName)\ScannerPRO_v9_COLLAB.ino.bootloader.bin"
$part = "$($build.FullName)\ScannerPRO_v9_COLLAB.ino.partitions.bin"
$app  = "$($build.FullName)\ScannerPRO_v9_COLLAB.ino.bin"

# Boot_app0 viene del core
$bootApp0 = Get-ChildItem "$env:LOCALAPPDATA\Arduino15\packages\esp32\hardware\esp32\3.3.12" -Recurse -Filter "boot_app0.bin" -EA SilentlyContinue | Select-Object -First 1
if (-not $bootApp0) { Write-Host "[!] No encontré boot_app0.bin, se omite" -ForegroundColor Yellow }
else { Write-Host "[OK] boot_app0: $($bootApp0.FullName)" }

# Offsets típicos ESP32 (dev module)
# 0x1000  bootloader
# 0x8000  partitions
# 0xe000  boot_app0
# 0x10000 app
$args = @(
    "--chip", "esp32",
    "--port", "COM5",
    "--baud", "460800",
    "--before", "default_reset",
    "--after",  "hard_reset",
    "write_flash", "-z",
    "--flash_mode", "dio",
    "--flash_freq", "80m",
    "--flash_size", "detect",
    "0x1000",  $boot,
    "0x8000",  $part
)
if ($bootApp0) {
    $args += @("0xe000", $bootApp0.FullName)
}
$args += @("0x10000", $app)

Write-Host ""
Write-Host "=== Ejecutando esptool con auto-reset ===" -ForegroundColor Cyan
Write-Host "Comando:"
Write-Host "  $esp $($args -join ' ')" -ForegroundColor DarkGray
Write-Host ""

& $esp @args 2>&1 | ForEach-Object { Write-Host $_ }

$exit = $LASTEXITCODE
Write-Host ""
if ($exit -eq 0) {
    Write-Host "[VERDE] FLASH OK" -ForegroundColor Green
} else {
    Write-Host "[ROJO] flash fallo (exit=$exit)" -ForegroundColor Red
}