# 1. Verificar que PowerShell 7 existe
if (-not (Get-Command pwsh -ErrorAction SilentlyContinue)) {
    Write-Host "PowerShell 7 no encontrado. Instálalo desde: https://github.com/PowerShell/PowerShell"
    exit 1
}

# 2. Verificar que el script existe donde debe estar; si no, crearlo desde portapapeles
$scriptPath = 'C:\RUNEFOGE_PRO\runeforge\scripts\resource-guardian-v2.ps1'
if (-not (Test-Path $scriptPath)) {
    New-Item -ItemType Directory -Path (Split-Path $scriptPath) -Force | Out-Null
    Get-Clipboard | Set-Content $scriptPath -Encoding UTF8
    Write-Host "Script creado desde portapapeles en: $scriptPath"
}

# 3. Ejecutar
pwsh -File $scriptPath -ExecutionPolicy Bypass
