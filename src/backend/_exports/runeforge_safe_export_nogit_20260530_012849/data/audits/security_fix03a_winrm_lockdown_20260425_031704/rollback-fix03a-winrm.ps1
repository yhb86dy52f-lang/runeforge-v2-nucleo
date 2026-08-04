Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

Set-Service WinRM -StartupType Automatic
Start-Service WinRM

Enable-PSRemoting -Force

Get-NetFirewallRule -DisplayGroup "Windows Remote Management" -ErrorAction SilentlyContinue |
Enable-NetFirewallRule

Write-Host "[ROLLBACK_FIX03A_WINRM_OK]" -ForegroundColor Yellow
Get-Service WinRM | Format-Table Name,Status,StartType -AutoSize
Get-NetTCPConnection -State Listen -LocalPort 5985,5986 -ErrorAction SilentlyContinue |
Format-Table LocalAddress,LocalPort,OwningProcess -AutoSize
