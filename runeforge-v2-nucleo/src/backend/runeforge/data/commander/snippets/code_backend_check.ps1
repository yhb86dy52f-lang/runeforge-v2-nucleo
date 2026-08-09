# RUNEFORGE BACKEND CHECK
# No modifica nada.

$Root = "C:\RUNEFOGE_PRO\runeforge"
$Backend = Join-Path $Root "app"

Set-Location $Backend

Write-Host "[1] package.json" -ForegroundColor Cyan
if (Test-Path ".\package.json") {
    Get-Content ".\package.json" -Raw |
    ConvertFrom-Json |
    Select-Object name,type,scripts
} else {
    Write-Host "PENDIENTE: No existe package.json" -ForegroundColor Yellow
}

Write-Host "`n[2] PM2" -ForegroundColor Cyan
try {
    pm2 status
} catch {
    Write-Host "PENDIENTE: PM2 no disponible" -ForegroundColor Yellow
}

Write-Host "`n[3] Puertos candidatos Runeforge" -ForegroundColor Cyan
Get-NetTCPConnection -State Listen |
Where-Object { $_.LocalPort -in 3000,3007,3100,5173,8080,8082 } |
Select-Object LocalAddress,LocalPort,OwningProcess |
Format-Table -AutoSize
