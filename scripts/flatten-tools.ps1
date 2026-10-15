$ErrorActionPreference = "Continue"
$tools = "$env:LOCALAPPDATA\Arduino15\packages\esp32\tools"

Write-Host "=== Detectando paquetes con anidamiento ===" -ForegroundColor Cyan
$fixed = 0
Get-ChildItem $tools -Directory -EA SilentlyContinue | ForEach-Object {
    $name = $_.Name
    Get-ChildItem $_.FullName -Directory -EA SilentlyContinue | ForEach-Object {
        $verDir = $_.FullName
        $innerName = Join-Path $verDir $name
        if (Test-Path $innerName) {
            Write-Host ""
            Write-Host "[ANIDADO] $name" -ForegroundColor Yellow
            Write-Host "  Version dir: $verDir"
            Write-Host "  Inner: $innerName"

            # Mover contenido del inner hacia arriba
            Get-ChildItem $innerName -Force -EA SilentlyContinue |
                Move-Item -Destination $verDir -Force -EA SilentlyContinue
            Remove-Item $innerName -Force -Recurse -EA SilentlyContinue
            $fixed++
            Write-Host "  [OK] Aplanado" -ForegroundColor Green
        }
    }
}

Write-Host ""
Write-Host "=== Total aplanados: $fixed ===" -ForegroundColor Green

Write-Host ""
Write-Host "=== Verificacion final ===" -ForegroundColor Cyan
$checklist = @(
    'esp32-libs\3.3.12\bin\bootloader_qio_80m.elf',
    'esp32c3-libs\3.3.12\bin\bootloader_qio_80m.elf',
    'esp32c6-libs\3.3.12\bin\bootloader_qio_80m.elf',
    'esp32s3-libs\3.3.12\bin\bootloader_qio_80m.elf',
    'esp32s2-libs\3.3.12\bin\bootloader_qio_80m.elf',
    'esp-x32\2601\bin\xtensa-esp32-elf-gcc.exe',
    'esp-rv32\2601\bin\riscv32-esp-elf-gcc.exe'
)
foreach ($p in $checklist) {
    $full = Join-Path $tools $p
    $ok = Test-Path $full
    $color = if ($ok) { 'Green' } else { 'Red' }
    Write-Host "  $(if($ok){'[OK]'}else{'[X] '}) $p" -ForegroundColor $color
}