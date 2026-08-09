# RUNEFORGE NODE/PM2 PORT CHECK
# No modifica nada

$Root = "C:\RUNEFOGE_PRO\runeforge"
$Backend = Join-Path $Root "app"

Write-Host "[1] PM2" -ForegroundColor Cyan
try { pm2 status } catch { Write-Host "PENDIENTE: PM2 no disponible" -ForegroundColor Yellow }

Write-Host "`n[2] Puertos Node / Runeforge" -ForegroundColor Cyan
Get-NetTCPConnection -State Listen |
ForEach-Object {
    $proc = $null
    try { $proc = Get-Process -Id $_.OwningProcess -ErrorAction Stop } catch {}
    [pscustomobject]@{
        LocalAddress = $_.LocalAddress
        LocalPort = $_.LocalPort
        Process = if ($proc) { $proc.ProcessName } else { "UNKNOWN" }
        PID = $_.OwningProcess
    }
} |
Where-Object {
    $_.LocalPort -in 3000,3007,3100,5173,8080,8082 -or $_.Process -match "node|pm2"
} |
Sort-Object LocalPort |
Format-Table -AutoSize
