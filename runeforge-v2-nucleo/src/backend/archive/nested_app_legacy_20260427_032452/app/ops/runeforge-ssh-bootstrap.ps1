$ErrorActionPreference = 'Stop'

$User = 'nesth'
$TailscaleIp = '100.103.231.24'

$PhoneKey = 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILSrDhvh1Y/eR44f74IQRP2IP3BHnjbhhGET2FDLKpq0 #ssh.id - @nesth'
$DesktopKey = 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILtVaLzqEvozfrabt3T1RiCbJeZ8NfpNDgkEqceu2d4B #ssh.id - @nesth'

$HomeDir = "C:\Users\$User"
$UserSshDir = Join-Path $HomeDir '.ssh'
$UserAuthorizedKeys = Join-Path $UserSshDir 'authorized_keys'
$AdminAuthorizedKeys = 'C:\ProgramData\ssh\administrators_authorized_keys'
$SshdConfig = 'C:\ProgramData\ssh\sshd_config'

$AdminsAccount = (New-Object System.Security.Principal.SecurityIdentifier 'S-1-5-32-544').Translate([System.Security.Principal.NTAccount]).Value
$SystemAccount = (New-Object System.Security.Principal.SecurityIdentifier 'S-1-5-18').Translate([System.Security.Principal.NTAccount]).Value
$UserAccount = "$env:COMPUTERNAME\$User"

function Ensure-OpenSshServer {
    if (-not (Get-Service sshd -ErrorAction SilentlyContinue)) {
        & dism.exe /Online /Add-Capability /CapabilityName:OpenSSH.Server~~~~0.0.1.0 | Out-Null
    }
}

function Ensure-FirewallRule {
    $ruleName = 'Runeforge SSH 22'
    if (-not (Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue)) {
        New-NetFirewallRule `
            -DisplayName $ruleName `
            -Direction Inbound `
            -Action Allow `
            -Protocol TCP `
            -LocalPort 22 `
            -Profile Private | Out-Null
    }
}

function Set-SshdSetting {
    param(
        [string]$Key,
        [string]$Value
    )

    if (-not (Test-Path $SshdConfig)) {
        New-Item -ItemType File -Path $SshdConfig -Force | Out-Null
    }

    $content = Get-Content $SshdConfig -Raw
    $pattern = "(?m)^[#\s]*$([regex]::Escape($Key))\s+.*$"
    $line = "$Key $Value"

    if ($content -match $pattern) {
        $content = [regex]::Replace($content, $pattern, $line)
    }
    else {
        if ($content.Length -gt 0 -and -not $content.EndsWith("`r`n")) {
            $content += "`r`n"
        }
        $content += "$line`r`n"
    }

    Set-Content -Path $SshdConfig -Value $content -Encoding ascii
}

function Write-KeysFile {
    param(
        [string]$Path,
        [string[]]$Keys
    )

    $dir = Split-Path $Path -Parent
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    $cleanKeys = $Keys | Where-Object { $_ -and $_.Trim() }
    Set-Content -Path $Path -Value $cleanKeys -Encoding ascii
}

Ensure-OpenSshServer

$keys = @($PhoneKey, $DesktopKey)

Write-KeysFile -Path $UserAuthorizedKeys -Keys $keys

$adminsGroupName = $AdminsAccount.Split('\')[-1]
$adminMembers = Get-LocalGroupMember -Group $adminsGroupName -ErrorAction SilentlyContinue
$isAdminUser = $false

if ($adminMembers) {
    $isAdminUser = ($adminMembers | Where-Object { $_.Name -match "(^|\\)$([regex]::Escape($User))$" }).Count -gt 0
}

if ($isAdminUser) {
    Write-KeysFile -Path $AdminAuthorizedKeys -Keys $keys
}

Set-SshdSetting -Key 'PubkeyAuthentication' -Value 'yes'
Set-SshdSetting -Key 'PasswordAuthentication' -Value 'yes'
Set-SshdSetting -Key 'PermitEmptyPasswords' -Value 'no'
Set-SshdSetting -Key 'AllowUsers' -Value $User

& icacls $UserSshDir /inheritance:r | Out-Null
& icacls $UserSshDir /grant:r "${UserAccount}:(OI)(CI)F" "${SystemAccount}:(OI)(CI)F" "${AdminsAccount}:(OI)(CI)F" | Out-Null

& icacls $UserAuthorizedKeys /inheritance:r | Out-Null
& icacls $UserAuthorizedKeys /grant:r "${UserAccount}:F" "${SystemAccount}:F" "${AdminsAccount}:F" | Out-Null

if ($isAdminUser) {
    & icacls $AdminAuthorizedKeys /inheritance:r | Out-Null
    & icacls $AdminAuthorizedKeys /grant:r "${AdminsAccount}:F" "${SystemAccount}:F" | Out-Null
}

Ensure-FirewallRule

Set-Service -Name sshd -StartupType Automatic
if ((Get-Service sshd).Status -eq 'Running') {
    Restart-Service sshd
} else {
    Start-Service sshd
}

[pscustomobject]@{
    Hostname = $env:COMPUTERNAME
    User = $User
    TailscaleIP = $TailscaleIp
    Port = 22
    SSH = "ssh $User@$TailscaleIp -p 22"
    UserAuthorizedKeys = $UserAuthorizedKeys
    AdminAuthorizedKeys = if ($isAdminUser) { $AdminAuthorizedKeys } else { '' }
} | Format-List