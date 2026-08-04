Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

Start-Sleep -Seconds 600

if (-not (Test-Path -LiteralPath "C:\RUNEFOGE_PRO\runeforge\data\audits\security_fix03c_ssh_tailscale_only_20260425_032840\KEEP_FIX03C_OK.confirm")) {
    pwsh -NoLogo -ExecutionPolicy Bypass -File "C:\RUNEFOGE_PRO\runeforge\data\audits\security_fix03c_ssh_tailscale_only_20260425_032840\rollback-fix03c-ssh-firewall.ps1"
}
