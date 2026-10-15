$ErrorActionPreference = "Continue"
$tools = "$env:LOCALAPPDATA\Arduino15\packages\esp32\tools"
$staging = "$env:LOCALAPPDATA\Arduino15\staging\packages"

$jobs = @(
    @{ pkg='esp-x32';  sys='xtensa-esp-elf';  zip='xtensa-esp-elf-14.2.0_20260121-x86_64-w64-mingw32.zip' },
    @{ pkg='esp-rv32'; sys='riscv32-esp-elf'; zip='riscv32-esp-elf-14.2.0_20260121-x86_64-w64-mingw32.zip' }
)

foreach ($j in $jobs) {
    Write-Host ""
    Write-Host "=== $($j.pkg) ===" -ForegroundColor Cyan

    $base = Join-Path $tools "$($j.pkg)\2601"
    $sysroot = Join-Path $base $j.sys
    $stdint = Join-Path $sysroot 'include\stdint.h'

    if (Test-Path $stdint) {
        Write-Host "  [OK] sysroot ya presente: $stdint" -ForegroundColor Green
        continue
    }

    $zip = Join-Path $staging $j.zip
    if (-not (Test-Path $zip)) {
        Write-Host "  [X] no está el zip: $zip" -ForegroundColor Red
        continue
    }

    $zipMB = [math]::Round((Get-Item $zip).Length / 1MB, 0)
    Write-Host "  Extrayendo $($j.zip) ($zipMB MB) a $env:TEMP ..." -ForegroundColor Yellow

    $tmp = Join-Path $env:TEMP "$($j.pkg)-recover"
    Remove-Item $tmp -Recurse -Force -EA SilentlyContinue
    Expand-Archive $zip $tmp -Force

    # Buscar el stdint.h del sysroot (excluyendo el de lib/gcc/...)
    $hit = Get-ChildItem $tmp -Recurse -Filter "stdint.h" -EA SilentlyContinue |
        Where-Object {
            $_.FullName -notmatch '\\lib\\gcc\\' -and
            $_.FullName -match "\\$([regex]::Escape($j.sys))\\include\\stdint\.h$"
        } | Select-Object -First 1

    if (-not $hit) {
        Write-Host "  [X] no encontré stdint.h del sysroot. Estructura del zip:" -ForegroundColor Red
        Get-ChildItem $tmp -Recurse -Directory -Depth 2 | Select-Object -First 20 FullName |
            ForEach-Object { Write-Host "    $_" }
        continue
    }

    # sysroot = dos niveles arriba de stdint.h (include -> sysroot)
    $sysSrc = Split-Path (Split-Path $hit.FullName -Parent) -Parent
    Write-Host "  sysroot encontrado: $sysSrc"
    Write-Host "  moviendo a: $sysroot"

    if (Test-Path $sysroot) { Remove-Item $sysroot -Recurse -Force -EA SilentlyContinue }
    Move-Item $sysSrc $sysroot -Force

    if (Test-Path "$sysroot\include\stdint.h") {
        Write-Host "  [OK] sysroot restaurado" -ForegroundColor Green
    } else {
        Write-Host "  [X] algo falló al mover" -ForegroundColor Red
    }

    Remove-Item $tmp -Recurse -Force -EA SilentlyContinue
}

Write-Host ""
Write-Host "=== VERIFICACION FINAL ===" -ForegroundColor Cyan
$checks = @(
    'esp-x32\2601\xtensa-esp-elf\include\stdint.h',
    'esp-rv32\2601\riscv32-esp-elf\include\stdint.h'
)
foreach ($c in $checks) {
    $full = Join-Path $tools $c
    $ok = Test-Path $full
    $color = if ($ok) { 'Green' } else { 'Red' }
    Write-Host "  $(if($ok){'[OK]'}else{'[X] '}) $c" -ForegroundColor $color
}

Write-Host ""
Write-Host "=== Estructura final de esp-x32\2601 ===" -ForegroundColor Cyan
Get-ChildItem "$tools\esp-x32\2601" | Select-Object Mode,Name | Format-Table -AutoSize