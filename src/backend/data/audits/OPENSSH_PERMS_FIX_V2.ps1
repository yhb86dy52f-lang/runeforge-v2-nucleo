# RUNEFORGE_OPENSSH_PERMS_FIX_V2
# Reparación controlada de permisos OpenSSH-Win64
# Ejecutar en PowerShell 7 Admin / PC directa

$ErrorActionPreference = "Stop"

$ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"

Write-Host "[RUNEFORGE_OPENSSH_PERMS_FIX_V2][$ts]"

$Root = "C:\RUNEFOGE_PRO\runeforge"
$AuditDir = Join-Path $Root "data\audits\openssh_acl_fix_v2_$stamp"

$Dir = "C:\Program Files\OpenSSH-Win64"
$SshdExe = Join-Path $Dir "sshd.exe"
$HostFix = Join-Path $Dir "FixHostFilePermissions.ps1"
$UserFix = Join-Path $Dir "FixUserFilePermissions.ps1"

$Config = "C:\ProgramData\ssh\sshd_config"
$AdminKeys = "C:\ProgramData\ssh\administrators_authorized_keys"

New-Item -ItemType Directory -Force -Path $AuditDir | Out-Null

$HostLog = Join-Path $AuditDir "FixHostFilePermissions_$stamp.log"
$UserLog = Join-Path $AuditDir "FixUserFilePermissions_$stamp.log"
$KeysBak = Join-Path $AuditDir "administrators_authorized_keys_$stamp.bak"
$CfgBak = Join-Path $AuditDir "sshd_config_$stamp.bak"
$ResultLog = Join-Path $AuditDir "openssh_acl_fix_v2_result_$stamp.json"

$r = [ordered]@{
    Timestamp = $ts
    AuditDir = $AuditDir
    HostFixExists = Test-Path -LiteralPath $HostFix
    UserFixExists = Test-Path -LiteralPath $UserFix
    ConfigBackup = $CfgBak
    KeysBackup = $KeysBak
    HostFixOk = $false
    UserFixOk = $false
    AclReinforced = $false
    SshdConfigTest = $null
    Restarted = $false
    Service = $null
    Port22 = $null
    CrashesAfter = $null
    Status = "STARTED"
    Error = $null
}

try {
    if (!(Test-Path -LiteralPath $Root)) {
        throw "No existe Root: $Root"
    }

    if (!(Test-Path -LiteralPath $Dir)) {
        throw "No existe OpenSSH-Win64: $Dir"
    }

    if (!(Test-Path -LiteralPath $SshdExe)) {
        throw "No existe sshd.exe: $SshdExe"
    }

    if (!(Test-Path -LiteralPath $HostFix)) {
        throw "No existe HostFix: $HostFix"
    }

    if (!(Test-Path -LiteralPath $UserFix)) {
        throw "No existe UserFix: $UserFix"
    }

    if (!(Test-Path -LiteralPath $Config)) {
        throw "No existe sshd_config: $Config"
    }

    if (!(Test-Path -LiteralPath $AdminKeys)) {
        throw "No existe administrators_authorized_keys: $AdminKeys"
    }

    Copy-Item -LiteralPath $AdminKeys -Destination $KeysBak -Force
    Copy-Item -LiteralPath $Config -Destination $CfgBak -Force

    $ConfirmPreference = "None"

    try {
        $hostOutput = & $HostFix -Confirm:$false 2>&1
        $r.HostFixOk = $?
        $hostOutput | Out-File -FilePath $HostLog -Encoding utf8
    }
    catch {
        $r.HostFixOk = $false
        $_ | Out-File -FilePath $HostLog -Encoding utf8
    }

    try {
        $userOutput = & $UserFix -Confirm:$false 2>&1
        $r.UserFixOk = $?
        $userOutput | Out-File -FilePath $UserLog -Encoding utf8
    }
    catch {
        $r.UserFixOk = $false
        $_ | Out-File -FilePath $UserLog -Encoding utf8
    }

    icacls $AdminKeys /inheritance:r | Out-Null
    icacls $AdminKeys /grant:r "*S-1-5-18:F" "*S-1-5-32-544:F" | Out-Null
    icacls $AdminKeys /remove:g "*S-1-1-0" "*S-1-5-11" "*S-1-5-32-545" "$env:USERDOMAIN\$env:USERNAME" 2>$null | Out-Null
    icacls $AdminKeys /setowner "*S-1-5-32-544" | Out-Null

    $r.AclReinforced = $true

    & $SshdExe -t -f $Config
    $r.SshdConfigTest = $LASTEXITCODE

    if ($LASTEXITCODE -ne 0) {
        throw "sshd_config no pasó validación."
    }

    Restart-Service sshd -Force
    Start-Sleep -Seconds 2

    $r.Restarted = $true

    $svc = Get-Service sshd
    $r.Service = $svc.Status.ToString()

    $r.Port22 = Get-NetTCPConnection -State Listen -LocalPort 22 -ErrorAction SilentlyContinue |
        Select-Object LocalAddress,LocalPort,OwningProcess

    $r.CrashesAfter = Get-WinEvent -FilterHashtable @{
        LogName = "Application"
        StartTime = (Get-Date).AddMinutes(-2)
    } -ErrorAction SilentlyContinue |
    Where-Object {
        $_.Message -match "sshd.exe|APPCRASH|c0000005"
    } |
    Select-Object TimeCreated,ProviderName,Id

    if ($svc.Status -ne "Running") {
        throw "sshd no quedó Running."
    }

    $r.Status = "OK_OPENSSH_PERMS_FIX_V2_APPLIED"
}
catch {
    $r.Status = "FAILED"
    $r.Error = $_.Exception.Message
}

$r | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $ResultLog -Encoding utf8

Write-Host "[RUNEFORGE_OPENSSH_PERMS_FIX_V2_RESULT]"
$r | ConvertTo-Json -Depth 8