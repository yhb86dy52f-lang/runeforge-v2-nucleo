# RUNEFORGE SSH IPHONE FIX ROLLBACK
# Fecha: 2026-05-06 01:28:42
# Restaura administrators_authorized_keys previo al fix.

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Backup = "C:\RUNEFOGE_PRO\runeforge\data\audits\ssh_iphone_fix_20260506_012842\administrators_authorized_keys.20260506_012842.bak"
$Target = "C:\ProgramData\ssh\administrators_authorized_keys"

if (-not (Test-Path -LiteralPath $Backup)) {
    throw "No existe backup: $Backup"
}

Copy-Item -LiteralPath $Backup -Destination $Target -Force

icacls $Target /inheritance:r | Out-Null
icacls $Target /grant:r "*S-1-5-18:F" "*S-1-5-32-544:F" | Out-Null
icacls $Target /setowner "*S-1-5-32-544" | Out-Null

Restart-Service sshd -Force

Write-Host "[OK] Rollback SSH iPhone aplicado." -ForegroundColor Green
