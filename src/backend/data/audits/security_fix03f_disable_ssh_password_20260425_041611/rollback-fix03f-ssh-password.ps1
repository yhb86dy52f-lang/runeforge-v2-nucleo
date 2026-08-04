Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Copy-Item -LiteralPath "C:\RUNEFOGE_PRO\runeforge\data\audits\security_fix03f_disable_ssh_password_20260425_041611\sshd_config.20260425_041611.bak" -Destination "C:\ProgramData\ssh\sshd_config" -Force
Restart-Service sshd -Force
Start-Sleep -Seconds 2

Write-Host "[ROLLBACK_FIX03F_SSH_PASSWORD_OK]" -ForegroundColor Yellow
Get-Service sshd | Format-Table Name,Status,StartType -AutoSize
Select-String -LiteralPath "C:\ProgramData\ssh\sshd_config" -Pattern "^\s*(PasswordAuthentication|PubkeyAuthentication|AllowUsers)\b"
