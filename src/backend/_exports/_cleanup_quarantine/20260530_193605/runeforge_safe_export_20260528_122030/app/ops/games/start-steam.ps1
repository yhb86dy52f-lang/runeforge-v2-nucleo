Write-Host '=== START STEAM ==='

$steamPaths = @(
    'C:\Program Files (x86)\Steam\Steam.exe',
    'C:\Program Files\Steam\Steam.exe'
)

$steamExe = $steamPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $steamExe) {
    Write-Host 'Steam no encontrado'
    exit 1
}

Start-Process -FilePath $steamExe
Start-Sleep -Seconds 3

Get-Process steam* -ErrorAction SilentlyContinue |
Select-Object ProcessName, Id |
Format-Table -AutoSize
