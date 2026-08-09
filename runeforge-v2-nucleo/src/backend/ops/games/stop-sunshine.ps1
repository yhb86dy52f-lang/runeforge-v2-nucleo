$ErrorActionPreference = 'SilentlyContinue'

Write-Host '=== RUNEFORGE STOP SUNSHINE ==='
Write-Host ''

$procs = Get-Process sunshine* -ErrorAction SilentlyContinue

if (-not $procs) {
    Write-Host 'Sunshine no está corriendo'
    exit 0
}

$procs | Stop-Process -Force

Start-Sleep -Seconds 2

Write-Host 'Procesos restantes:'
Get-Process sunshine* -ErrorAction SilentlyContinue |
Select-Object ProcessName, Id |
Format-Table -AutoSize

Write-Host ''
Write-Host 'Fin stop-sunshine'
