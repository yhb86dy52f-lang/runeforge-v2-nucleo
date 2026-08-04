$ErrorActionPreference = 'Stop'

Write-Host '=== RUNEFORGE START SUNSHINE ==='
Write-Host ''

$sunPaths = @(
    'C:\Program Files\Sunshine\Sunshine.exe',
    'C:\Program Files\LizardByte\Sunshine\Sunshine.exe',
    "$env:LOCALAPPDATA\Programs\Sunshine\Sunshine.exe"
)

$sunExe = $sunPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $sunExe) {
    Write-Host 'Sunshine no encontrado en rutas típicas'
    exit 1
}

Write-Host "Sunshine encontrado: $sunExe"

$running = Get-Process sunshine -ErrorAction SilentlyContinue

if ($running) {
    Write-Host 'Sunshine ya está corriendo'
} else {
    Start-Process -FilePath $sunExe
    Start-Sleep -Seconds 5
    Write-Host 'Sunshine lanzado'
}

Write-Host ''
Write-Host 'Procesos Sunshine:'
Get-Process sunshine* -ErrorAction SilentlyContinue |
Select-Object ProcessName, Id |
Format-Table -AutoSize

Write-Host ''
Write-Host 'Fin start-sunshine'
