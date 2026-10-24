$ErrorActionPreference = "Continue"
$tools = "$env:LOCALAPPDATA\Arduino15\packages\esp32\tools"

$jobs = @(
    @{ pkg='esp-x32';  inner='xtensa-esp-elf'    },
    @{ pkg='esp-rv32'; inner='riscv32-esp-elf'   }
)

foreach ($j in $jobs) {
    $base = Join-Path $tools "$($j.pkg)\2601"
    $inner = Join-Path $base $j.inner

    Write-Host ""
    Write-Host "=== $($j.pkg) ===" -ForegroundColor Cyan
    if (-not (Test-Path $inner)) {
        Write-Host "  [X] no existe $inner" -ForegroundColor Red
        continue
    }

    Write-Host "  Moviendo $inner\* -> $base\"

    # Mover TODO (incluye ocultos)
    Get-ChildItem $inner -Force | Move-Item -Destination $base -Force
    Remove-Item $inner -Force -Recurse -EA SilentlyContinue

    Write-Host "  [OK] aplanado" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== Verificacion final ===" -ForegroundColor Cyan
$checks = @(
    'esp-x32\2601\bin\xtensa-esp-elf-gcc.exe',
    'esp-x32\2601\bin\xtensa-esp32-elf-gcc.exe',
    'esp-rv32\2601\bin\riscv32-esp-elf-gcc.exe'
)
foreach ($c in $checks) {
    $full = Join-Path $tools $c
    $ok = Test-Path $full
    $color = if ($ok) { 'Green' } else { 'Red' }
    Write-Host "  $(if($ok){'[OK]'}else{'[X] '}) $c" -ForegroundColor $color
}

Write-Host ""
Write-Host "=== Estructura de esp-x32\2601 ===" -ForegroundColor Cyan
Get-ChildItem "$tools\esp-x32\2601" -EA SilentlyContinue | Select-Object Mode, Name | Format-Table -AutoSize