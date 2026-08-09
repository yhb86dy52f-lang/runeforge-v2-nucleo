$ErrorActionPreference="SilentlyContinue"
$ts=Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Write-Host "[RF_STATUS][$ts]" -ForegroundColor Cyan
[pscustomobject]@{
  Time=$ts
  Root="C:\RUNEFOGE_PRO\runeforge"
  SSH=(Get-Service sshd -ErrorAction SilentlyContinue).Status
  PM2=(pm2 pid runeforge 2>$null)
  Health=try{(Invoke-RestMethod "http://127.0.0.1:3100/health" -TimeoutSec 3)}catch{"NO_RESPONSE"}
} | ConvertTo-Json -Depth 6
