param([int]$Port = 3100)
$ErrorActionPreference = 'Stop'
$App = 'C:\RUNEFOGE_PRO\runeforge\app'

$health = Invoke-RestMethod -Uri "http://127.0.0.1:$Port/health" -TimeoutSec 5
$status = Invoke-RestMethod -Uri "http://127.0.0.1:$Port/status" -TimeoutSec 5

Write-Host 'OK_BACKEND_VALIDADO'
Write-Host "APP=$App"
Write-Host "PORT=$Port"
Write-Host "HEALTH_OK=$($health.ok)"
Write-Host "STATUS_OK=$($status.ok)"
