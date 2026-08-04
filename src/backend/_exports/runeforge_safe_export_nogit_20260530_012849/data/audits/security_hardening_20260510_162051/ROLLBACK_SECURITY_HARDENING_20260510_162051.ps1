$ErrorActionPreference="Stop"
$FwBackup="C:\RUNEFOGE_PRO\runeforge\data\audits\security_hardening_20260510_162051\firewall_before_20260510_162051.wfw"
if(Test-Path $FwBackup){ netsh advfirewall import $FwBackup | Out-Null; Write-Host "[ROLLBACK] Firewall restaurado." } else { Write-Host "[ROLLBACK] Backup firewall no encontrado." }
