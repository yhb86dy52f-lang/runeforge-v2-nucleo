$ErrorActionPreference = "Continue"
$flash = "C:\RUNEFORGE_V2_CORE\flash.ps1"

# Backup
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
Copy-Item $flash "$flash.bak-$stamp" -Force
Write-Host "[OK] Backup: $flash.bak-$stamp" -ForegroundColor Green

# Leer
$content = [IO.File]::ReadAllText($flash, [System.Text.UTF8Encoding]::new($false))

# Parchear: .arduino15 en USERPROFILE -> Arduino15 en LOCALAPPDATA
$antes1 = '$env:USERPROFILE ' + "'.arduino15"
$antes2 = '$env:USERPROFILE ' + "'\.arduino15"
$despues1 = '$env:LOCALAPPDATA ' + "'Arduino15"
$despues2 = '$env:LOCALAPPDATA ' + "'\Arduino15"

$content = $content -replace [regex]::Escape('.arduino15'), 'Arduino15'

# Reemplazar $env:USERPROFILE solo en las lineas que contienen Arduino15
$lines = $content -split "`r?`n"
$new = foreach ($line in $lines) {
    if ($line -match 'Arduino15.*packages.*esp32') {
        $line -replace '\$env:USERPROFILE', '$env:LOCALAPPDATA'
    } else {
        $line
    }
}
$content = $new -join "`r`n"

# Escribir
[IO.File]::WriteAllText($flash, $content, [System.Text.UTF8Encoding]::new($false))
Write-Host "[OK] flash.ps1 parcheado" -ForegroundColor Green

# Verificar
Write-Host ""
Write-Host "=== Lineas modificadas ===" -ForegroundColor Cyan
Select-String -Path $flash -Pattern "esptool_py|Arduino15.*packages" | ForEach-Object {
    Write-Host "  L$($_.LineNumber): $($_.Line.Trim())"
}

Write-Host ""
Write-Host "=== Verificacion de rutas (Test-Path) ===" -ForegroundColor Cyan
$espBase = Join-Path $env:LOCALAPPDATA 'Arduino15\packages\esp32\tools\esptool_py'
Write-Host "  espBase = $espBase"
Write-Host "  Existe: $(Test-Path $espBase)" -ForegroundColor $(if (Test-Path $espBase) { 'Green' } else { 'Red' })

$coreBase = Join-Path $env:LOCALAPPDATA 'Arduino15\packages\esp32\hardware\esp32'
Write-Host "  coreBase = $coreBase"
Write-Host "  Existe: $(Test-Path $coreBase)" -ForegroundColor $(if (Test-Path $coreBase) { 'Green' } else { 'Red' })

Get-ChildItem $espBase -Directory -EA SilentlyContinue | ForEach-Object {
    $exe = Join-Path $_.FullName 'esptool.exe'
    Write-Host "    version: $($_.Name) | esptool.exe: $(Test-Path $exe)"
}