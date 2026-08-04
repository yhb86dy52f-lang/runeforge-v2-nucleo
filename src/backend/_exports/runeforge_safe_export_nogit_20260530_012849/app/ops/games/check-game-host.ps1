$ErrorActionPreference = 'SilentlyContinue'

Write-Host '=== RUNEFORGE CHECK GAME HOST ==='
Write-Host ''

Write-Host 'Host:'
hostname

Write-Host ''
Write-Host 'Usuario:'
whoami

Write-Host ''
Write-Host 'PowerShell:'
$PSVersionTable.PSVersion

Write-Host ''
Write-Host 'GPU:'
Get-CimInstance Win32_VideoController |
Select-Object Name, DriverVersion, VideoProcessor |
Format-Table -AutoSize

Write-Host ''
Write-Host 'IPv4 activas:'
Get-NetIPAddress -AddressFamily IPv4 |
Where-Object {
    $_.IPAddress -notlike '127.*' -and
    $_.IPAddress -notlike '169.254*'
} |
Select-Object InterfaceAlias, IPAddress |
Format-Table -AutoSize

Write-Host ''
Write-Host 'Tailscale proceso:'
Get-Process tailscale* |
Select-Object ProcessName, Id |
Format-Table -AutoSize

Write-Host ''
Write-Host 'Steam procesos:'
Get-Process steam* |
Select-Object ProcessName, Id |
Format-Table -AutoSize

Write-Host ''
Write-Host 'Sunshine procesos:'
Get-Process sunshine* |
Select-Object ProcessName, Id |
Format-Table -AutoSize

Write-Host ''
Write-Host 'Rutas Sunshine típicas:'
$sunPaths = @(
    'C:\Program Files\Sunshine\Sunshine.exe',
    'C:\Program Files\LizardByte\Sunshine\Sunshine.exe',
    "$env:LOCALAPPDATA\Programs\Sunshine\Sunshine.exe"
)

$found = $sunPaths | Where-Object { Test-Path $_ }

if ($found) {
    $found | ForEach-Object { Write-Host $_ }
} else {
    Write-Host 'Sunshine no encontrado en rutas típicas'
}

Write-Host ''
Write-Host 'Fin check-game-host'
