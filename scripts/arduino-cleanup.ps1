$ErrorActionPreference = "Continue"
$cli = "C:\Program Files\Arduino CLI\arduino-cli.exe"
$url = "https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json"

Write-Host "=== 1. Limpiar additional_urls ===" -ForegroundColor Cyan
& $cli config set board_manager.additional_urls $url

Write-Host ""
Write-Host "=== 2. Estado de la config ===" -ForegroundColor Cyan
$dump = & $cli config dump | Out-String
if ($dump -match 'additional_urls:[\s\S]*?-\s*(.+?)[\r\n]') {
    Write-Host "URL configurada: $($Matches[1].Trim())" -ForegroundColor Green
} else {
    Write-Host "No hay additional_urls (revisar dump manual)" -ForegroundColor Yellow
}
$dump | Select-String -Pattern "additional_urls" -Context 0,4

Write-Host ""
Write-Host "=== 3. Actualizar indices ===" -ForegroundColor Cyan
& $cli core update-index --additional-urls $url

Write-Host ""
Write-Host "=== 4. Core list ===" -ForegroundColor Cyan
& $cli core list

Write-Host ""
Write-Host "=== 5. esptool instalados ===" -ForegroundColor Cyan
Get-ChildItem "$env:LOCALAPPDATA\Arduino15\packages\esp32\tools\esptool_py" `
    -Recurse -Filter "esptool.exe" -EA SilentlyContinue |
    Select-Object FullName, @{n='MB';e={[math]::Round($_.Length/1MB,1)}} |
    Format-Table -AutoSize

Write-Host ""
Write-Host "=== FIN ===" -ForegroundColor Green