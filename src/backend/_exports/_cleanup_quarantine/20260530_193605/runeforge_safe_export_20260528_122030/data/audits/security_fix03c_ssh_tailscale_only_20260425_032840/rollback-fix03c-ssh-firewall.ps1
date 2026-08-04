Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

$RulesDisabledPath = "C:\RUNEFOGE_PRO\runeforge\data\audits\security_fix03c_ssh_tailscale_only_20260425_032840\ssh-rules-disabled.json"
$NewRuleName = "Runeforge SSH Tailscale Only"

if (Test-Path -LiteralPath $RulesDisabledPath) {
    $rules = @(Get-Content -LiteralPath $RulesDisabledPath -Raw | ConvertFrom-Json)
    foreach ($r in $rules) {
        try {
            Enable-NetFirewallRule -Name $r.Name
        } catch {}
    }
}

try {
    Get-NetFirewallRule -DisplayName $NewRuleName -ErrorAction SilentlyContinue |
        Remove-NetFirewallRule
} catch {}

Write-Host "[ROLLBACK_FIX03C_SSH_FIREWALL_OK]" -ForegroundColor Yellow

Get-NetFirewallRule -Direction Inbound -Action Allow -ErrorAction SilentlyContinue |
Where-Object {
    $_.DisplayName -match "SSH|OpenSSH|Runeforge SSH|Allow SSH" -or $_.Name -match "sshd|AllowSSH"
} |
ForEach-Object {
    $rule = $_
    $pf = Get-NetFirewallPortFilter -AssociatedNetFirewallRule $rule -ErrorAction SilentlyContinue
    $af = Get-NetFirewallAddressFilter -AssociatedNetFirewallRule $rule -ErrorAction SilentlyContinue
    [pscustomobject]@{
        DisplayName = $rule.DisplayName
        Name = $rule.Name
        Enabled = $rule.Enabled
        LocalPort = if ($pf) { $pf.LocalPort -join "," } else { "" }
        RemoteAddress = if ($af) { $af.RemoteAddress -join "," } else { "" }
    }
} | Format-Table -AutoSize
