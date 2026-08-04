# RUNEFORGE ROLLBACK REINSTALL OPENSSH
# Fecha: 2026-05-09 06:42:34

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$OpenSshDir = "C:\Program Files\OpenSSH-Win64"
$OldBackupDir = "C:\Program Files\OpenSSH-Win64_BROKEN_20260509_064234"
$ProgramDataSsh = "C:\ProgramData\ssh"
$ProgramDataBackup = "C:\RUNEFOGE_PRO\runeforge\data\audits\openssh_reinstall_20260509_064234\ProgramData_ssh_backup_20260509_064234"

Write-Host "[ROLLBACK_REINSTALL_OPENSSH] Iniciando..." -ForegroundColor Yellow

Stop-Service sshd -Force -ErrorAction SilentlyContinue

if (Test-Path -LiteralPath $OpenSshDir) {
    Rename-Item -LiteralPath $OpenSshDir -NewName ("OpenSSH-Win64_ROLLBACK_FAILED_" + (Get-Date -Format "yyyyMMdd_HHmmss")) -Force
}

if (Test-Path -LiteralPath $OldBackupDir) {
    Rename-Item -LiteralPath $OldBackupDir -NewName "OpenSSH-Win64" -Force
}

if (Test-Path -LiteralPath $ProgramDataBackup) {
    Copy-Item -LiteralPath (Join-Path $ProgramDataBackup "*") -Destination $ProgramDataSsh -Recurse -Force
}

sc.exe config sshd binPath= ""$OpenSshDir\sshd.exe"" | Out-Null
sc.exe config sshd start= auto | Out-Null

icacls "$ProgramDataSsh\administrators_authorized_keys" /inheritance:r | Out-Null
icacls "$ProgramDataSsh\administrators_authorized_keys" /grant:r "*S-1-5-18:F" "*S-1-5-32-544:F" | Out-Null
icacls "$ProgramDataSsh\administrators_authorized_keys" /setowner "*S-1-5-32-544" | Out-Null

Start-Service sshd

Write-Host "[OK] Rollback OpenSSH aplicado." -ForegroundColor Green
