$ErrorActionPreference = "Continue"
$esp = "$env:LOCALAPPDATA\Arduino15\packages\esp32\tools\esptool_py\5.3.1\esptool.exe"
$sketch = "$env:LOCALAPPDATA\arduino\sketches"

$build = Get-ChildItem $sketch -Directory -EA SilentlyContinue |
    Where-Object { Test-Path "$($_.FullName)\ScannerPRO_v9_COLLAB.ino.bin" } |
    Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $build) { Write-Host "[X] No encontré build" -ForegroundColor Red; exit 1 }

$boot = "$($build.FullName)\ScannerPRO_v9_COLLAB.ino.bootloader.bin"
$part = "$($build.FullName)\ScannerPRO_v9_COLLAB.ino.partitions.bin"
$app  = "$($build.FullName)\ScannerPRO_v9_COLLAB.ino.bin"
$bootApp0 = "$env:LOCALAPPDATA\Arduino15\packages\esp32\hardware\esp32\3.3.12\tools\partitions\boot_app0.bin"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  PREPARATE. Sigue los pasos EN ORDEN y CON CALMA" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  1) PRESIONA y MANTEN el boton BOOT (o IO0 / FLASH)" -ForegroundColor White
Write-Host "     >>> NO LO SUELTES. Sigue presionado todo el tiempo <<<" -ForegroundColor Yellow
Write-Host ""
Write-Host "  2) Presiona y suelta el boton EN (o RESET / RST)" -ForegroundColor White
Write-Host "     >>> Pulsacion corta, 200 ms <<<" -ForegroundColor Gray
Write-Host ""
Write-Host "  3) Espera 1 segundo completo" -ForegroundColor White
Write-Host "     >>> cuenta despacio: uno... mil <<<" -ForegroundColor Gray
Write-Host ""
Write-Host "  4) SUELTA el boton BOOT" -ForegroundColor White
Write-Host "     >>> ahora sí sueltalo <<<" -ForegroundColor Yellow
Write-Host ""
Write-Host "  El chip queda en download mode. esptool conecta."
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Cuenta regresiva de 30s
for ($i = 30; $i -ge 1; $i--) {
    Write-Host -NoNewline ("`r  >>> Esperando {0,2} segundos antes de conectar <<<   " -f $i) -ForegroundColor Yellow
    Start-Sleep -Seconds 1
}
Write-Host ""
Write-Host ""
Write-Host "=== Conectando a COM5 (no_reset) ===" -ForegroundColor Cyan

$args = @(
    "--chip", "esp32",
    "--port", "COM5",
    "--baud", "115200",
    "--before", "no_reset",
    "--after",  "hard_reset",
    "write_flash", "-z",
    "--flash_mode", "dio",
    "--flash_freq", "80m",
    "--flash_size", "detect",
    "0x1000",  $boot,
    "0x8000",  $part,
    "0xe000",  $bootApp0,
    "0x10000", $app
)

& $esp @args 2>&1 | ForEach-Object { Write-Host $_ }

$exit = $LASTEXITCODE
Write-Host ""
if ($exit -eq 0) {
    Write-Host "[VERDE] FLASH OK - chip reseteado, arrancando firmware" -ForegroundColor Green
} else {
    Write-Host "[ROJO] flash fallo (exit=$exit)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Si vuelve a fallar:" -ForegroundColor Yellow
    Write-Host "  - Repite la secuencia BOOT+EN otra vez DURANTE los 30s" -ForegroundColor Gray
    Write-Host "  - Verifica el cable USB (debe ser de DATOS, no solo carga)" -ForegroundColor Gray
    Write-Host "  - Algunas placas: suelta BOOT ANTES de EN, otras DESPUES" -ForegroundColor Gray
}