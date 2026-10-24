$ErrorActionPreference = "Continue"
$tools = "$env:LOCALAPPDATA\Arduino15\packages\esp32\tools"

foreach ($pkg in @('esp-x32','esp-rv32')) {
    Write-Host ""
    Write-Host "=== $pkg ===" -ForegroundColor Cyan
    $base = Join-Path $tools $pkg
    if (-not (Test-Path $base)) { Write-Host "  [X] no existe $base" -ForegroundColor Red; continue }

    Get-ChildItem $base -Directory | ForEach-Object {
        Write-Host "  Version: $($_.Name)" -ForegroundColor Yellow
        $verDir = $_.FullName

        Write-Host "    Contenido nivel 1:"
        Get-ChildItem $verDir | Select-Object Mode, Name | Format-Table -AutoSize | Out-String |
            ForEach-Object { $_ -split "`r?`n" | Where-Object { $_ -match '\S' } | ForEach-Object { Write-Host "      $_" } }

        $bin = Join-Path $verDir 'bin'
        if (Test-Path $bin) {
            Write-Host "    bin\ (primeros 10):"
            Get-ChildItem $bin | Select-Object -First 10 Name |
                ForEach-Object { Write-Host "      $($_.Name)" }
            Write-Host "    gcc-like:"
            Get-ChildItem $bin -Filter "*.exe" | Where-Object { $_.Name -match 'gcc|clang' } |
                ForEach-Object { Write-Host "      $($_.Name)" }
        } else {
            Write-Host "    [X] no existe bin" -ForegroundColor Red
            # Buscar gcc recursivamente
            Write-Host "    Buscando *gcc*.exe recursivamente:"
            Get-ChildItem $verDir -Recurse -Filter "*gcc*.exe" -EA SilentlyContinue |
                ForEach-Object { Write-Host "      $($_.FullName)" }
        }
    }
}

Write-Host ""
Write-Host "=== Que espera el core 3.3.12 ===" -ForegroundColor Cyan
$recipe = "$env:LOCALAPPDATA\Arduino15\packages\esp32\hardware\esp32\3.3.12\platform.txt"
if (Test-Path $recipe) {
    Select-String -Path $recipe -Pattern "xtensa-esp32-elf-gcc|xtensa-esp-elf-gcc|riscv32-esp-elf-gcc|compiler.path" |
        Select-Object -First 15 | ForEach-Object { Write-Host "  L$($_.LineNumber): $($_.Line.Trim())" }
}