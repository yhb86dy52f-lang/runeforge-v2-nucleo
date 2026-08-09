$ErrorActionPreference = 'Stop'

$User = 'nesth'
$TailscaleIp = '100.103.231.24'
$ProgramDataSsh = 'C:\ProgramData\ssh'
$OpenSshDir = 'C:\Windows\System32\OpenSSH'
$SshdExe = Join-Path $OpenSshDir 'sshd.exe'
$SshKeygenExe = Join-Path $OpenSshDir 'ssh-keygen.exe'
$SshdConfig = Join-Path $ProgramDataSsh 'sshd_config'
$UserSshDir = "C:\Users\$User\.ssh"
$UserAuthorizedKeys = Join-Path $UserSshDir 'authorized_keys'
$AdminAuthorizedKeys = Join-Path $ProgramDataSsh 'administrators_authorized_keys'
$LogPath = "C:\RUNEFOGE_PRO\runeforge-mvp\data\trace\ssh_repair_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

New-Item -ItemType Directory -Force -Path (Split-Path $LogPath -Parent) | Out-Null
Start-Transcript -Path $LogPath -Force | Out-Null

function Write-Section($name) {
    Write-Host ""
    Write-Host "=== $name ==="
}

function Ensure-OpenSshInstalled {
    Write-Section 'ENSURE_OPENSSH'
    $cap = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*'
    if (-not $cap -or $cap.State -ne 'Installed') {
        Add-WindowsCapability -Online -Name 'OpenSSH.Server~~~~0.0.1.0' | Out-Null
    }
}

function Ensure-ServiceRegistration {
    Write-Section 'ENSURE_SERVICE_REGISTRATION'
    if (-not (Get-Service sshd -ErrorAction SilentlyContinue)) {
        & "$OpenSshDir\install-sshd.ps1"
    }
}

function Ensure-HostKeys {
    Write-Section 'ENSURE_HOST_KEYS'
    New-Item -ItemType Directory -Force -Path $ProgramDataSsh | Out-Null
    & $SshKeygenExe -A
}

function Ensure-UserFolders {
    Write-Section 'ENSURE_USER_FOLDERS'
    New-Item -ItemType Directory -Force -Path $UserSshDir | Out-Null
    if (-not (Test-Path $UserAuthorizedKeys)) {
        New-Item -ItemType File -Path $UserAuthorizedKeys -Force | Out-Null
    }
    if (-not (Test-Path $AdminAuthorizedKeys)) {
        New-Item -ItemType File -Path $AdminAuthorizedKeys -Force | Out-Null
    }
}

function Write-MinimalConfig {
    Write-Section 'WRITE_SSHD_CONFIG'
    $cfg = @'
Port 22
AddressFamily any
ListenAddress 0.0.0.0
ListenAddress ::
HostKey __PROGRAMDATA__/ssh/ssh_host_rsa_key
HostKey __PROGRAMDATA__/ssh/ssh_host_ecdsa_key
HostKey __PROGRAMDATA__/ssh/ssh_host_ed25519_key
PubkeyAuthentication yes
PasswordAuthentication yes
PermitEmptyPasswords no
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
UseDNS no
Subsystem sftp sftp-server.exe

Match Group administrators
       AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys
'@
    Set-Content -Path $SshdConfig -Value $cfg -Encoding ascii
}

function Apply-Permissions {
    Write-Section 'APPLY_PERMISSIONS'
    $AdminsAccount = (New-Object System.Security.Principal.SecurityIdentifier 'S-1-5-32-544').Translate([System.Security.Principal.NTAccount]).Value
    $SystemAccount = (New-Object System.Security.Principal.SecurityIdentifier 'S-1-5-18').Translate([System.Security.Principal.NTAccount]).Value
    $UserAccount = "$env:COMPUTERNAME\$User"

    & icacls $ProgramDataSsh /inheritance:r | Out-Null
    & icacls $ProgramDataSsh /grant:r "${SystemAccount}:(OI)(CI)F" "${AdminsAccount}:(OI)(CI)F" | Out-Null

    & icacls $SshdConfig /inheritance:r | Out-Null
    & icacls $SshdConfig /grant:r "${SystemAccount}:F" "${AdminsAccount}:F" | Out-Null

    & icacls $AdminAuthorizedKeys /inheritance:r | Out-Null
    & icacls $AdminAuthorizedKeys /grant:r "${SystemAccount}:F" "${AdminsAccount}:F" | Out-Null

    & icacls $UserSshDir /inheritance:r | Out-Null
    & icacls $UserSshDir /grant:r "${UserAccount}:(OI)(CI)F" "${SystemAccount}:(OI)(CI)F" "${AdminsAccount}:(OI)(CI)F" | Out-Null

    & icacls $UserAuthorizedKeys /inheritance:r | Out-Null
    & icacls $UserAuthorizedKeys /grant:r "${UserAccount}:F" "${SystemAccount}:F" "${AdminsAccount}:F" | Out-Null
}

function Ensure-Firewall {
    Write-Section 'ENSURE_FIREWALL'
    if (-not (Get-NetFirewallRule -DisplayName 'Runeforge SSH 22' -ErrorAction SilentlyContinue)) {
        New-NetFirewallRule -DisplayName 'Runeforge SSH 22' -Direction Inbound -Protocol TCP -LocalPort 22 -Action Allow -Profile Any | Out-Null
    }
}

function Test-Config {
    Write-Section 'TEST_CONFIG'
    & $SshdExe -t
}

function Start-Sshd {
    Write-Section 'START_SSHD'
    Set-Service -Name sshd -StartupType Automatic
    try { Stop-Service sshd -Force -ErrorAction SilentlyContinue } catch {}
    Start-Service sshd
    Start-Sleep -Seconds 2
}

function Show-Result {
    Write-Section 'RESULT'
    $svc = Get-Service sshd -ErrorAction SilentlyContinue
    $listen = Get-NetTCPConnection -LocalPort 22 -State Listen -ErrorAction SilentlyContinue
    [pscustomobject]@{
        Hostname = $env:COMPUTERNAME
        User = $User
        TailscaleIP = $TailscaleIp
        ServiceStatus = if ($svc) { $svc.Status } else { 'NOT_FOUND' }
        Port22Listening = [bool]$listen
        SSH = "ssh $User@$TailscaleIp -p 22"
        Config = $SshdConfig
        UserAuthorizedKeys = $UserAuthorizedKeys
        AdminAuthorizedKeys = $AdminAuthorizedKeys
        Log = $LogPath
    } | Format-List
}

Ensure-OpenSshInstalled
Ensure-ServiceRegistration
Ensure-HostKeys
Ensure-UserFolders
Write-MinimalConfig
Apply-Permissions
Ensure-Firewall
Test-Config
Start-Sshd
Show-Result

Stop-Transcript | Out-Null