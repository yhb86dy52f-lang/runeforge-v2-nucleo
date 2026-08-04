# RUNEFORGE ROLLBACK OPENSSH NATIVO
# Fecha: 2026-05-06 02:42:51

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$SshdConfig = "C:\ProgramData\ssh\sshd_config"
$AdminKeys = "C:\ProgramData\ssh\administrators_authorized_keys"
$BackupConfig = "C:\RUNEFOGE_PRO\runeforge\data\audits\openssh_native_20260506_024251\sshd_config.20260506_024251.bak"
$BackupAdminKeys = "C:\RUNEFOGE_PRO\runeforge\data\audits\openssh_native_20260506_024251\administrators_authorized_keys.20260506_024251.bak"
$OldSshd = "C:\Program Files\OpenSSH-Win64\sshd.exe"

Write-Host "[ROLLBACK_OPENSSH_NATIVE] Restaurando servicio previo..." -ForegroundColor Yellow

Stop-Service sshd -Force -ErrorAction SilentlyContinue

if (Test-Path -LiteralPath $BackupConfig) {
    Copy-Item -LiteralPath $BackupConfig -Destination $SshdConfig -Force
}

if (Test-Path -LiteralPath $BackupAdminKeys) {
    Copy-Item -LiteralPath $BackupAdminKeys -Destination $AdminKeys -Force
}

if (Test-Path -LiteralPath $OldSshd) {
    sc.exe config sshd binPath= ""$OldSshd"" | Out-Null
}

icacls $AdminKeys /inheritance:r | Out-Null
icacls $AdminKeys /grant:r "*S-1-5-18:F" "*S-1-5-32-544:F" | Out-Null
icacls $AdminKeys /setowner "*S-1-5-32-544" | Out-Null

Start-Service sshd

Write-Host "[OK] Rollback OpenSSH nativo aplicado." -ForegroundColor Green
