$ErrorActionPreference="SilentlyContinue"
$ts=Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Write-Host "[RF_HEALTH][$ts]" -ForegroundColor Cyan
$ports=@(22,3100,8082,47990,5985)
Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Where-Object {$_.LocalPort -in $ports} | Select-Object LocalAddress,LocalPort,OwningProcess,@{n="Process";e={(Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName}} | Sort-Object LocalPort | Format-Table -AutoSize
try { Invoke-RestMethod "http://127.0.0.1:3100/health" -TimeoutSec 3 | ConvertTo-Json -Depth 5 } catch { Write-Host "RUNEFORGE_3100=NO_RESPONSE" -ForegroundColor Yellow }
