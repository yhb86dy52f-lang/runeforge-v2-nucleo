# =====================================================================
# RUNEFORGE - REINSTALAR OPENSSH-WIN64 LIMPIO
# Ejecutar en PowerShell 7 Admin / PC directa
# =====================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$Stamp = Get-Date -Format "yyyyMMdd_HHmmss"

Write-Host "[RUNEFORGE_REINSTALAR_OPENSSH][$Ts]" -ForegroundColor Cyan

$Root = "C:\RUNEFOGE_PRO\runeforge"
$AuditDir = Join-Path $Root "data\audits\openssh_reinstall_$Stamp"

$OpenSshDir = "C:\Program Files\OpenSSH-Win64"
$OldBackupDir = "C:\Program Files\OpenSSH-Win64_BROKEN_$Stamp"

$ProgramDataSsh = "C:\ProgramData\ssh"
$SshdConfig = Join-Path $ProgramDataSsh "sshd_config"
$AdminKeys = Join-Path $ProgramDataSsh "administrators_authorized_keys"

$ZipPath = Join-Path $AuditDir "OpenSSH-Win64.zip"
$ExtractDir = Join-Path $AuditDir "extract"
$ProgramDataBackup = Join-Path $AuditDir "ProgramData_ssh_backup_$Stamp"
$ServiceBackup = Join-Path $AuditDir "sshd_service_before_$Stamp.txt"
$FirewallBackup = Join-Path $AuditDir "firewall_22_before_$Stamp.txt"
$Rollback = Join-Path $AuditDir "rollback-reinstall-openssh-$Stamp.ps1"
$Log = Join-Path $AuditDir "openssh_reinstall_result_$Stamp.json"

New-Item -ItemType Directory -Force -Path $AuditDir | Out-Null

$Result = [ordered]@{
    Timestamp = $Ts
    Stamp = $Stamp
    AuditDir = $AuditDir
    OpenSshDir = $OpenSshDir
    OldBackupDir = $OldBackupDir
    ProgramDataBackup = $ProgramDataBackup
    ZipPath = $ZipPath
    DownloadUrl = $null
    Downloaded = $false
    ZipHashSHA256 = $null
    Extracted = $false
    OldFolderBackedUp = $false
    NewFolderInstalled = $false
    ServiceRepointed = $false
    ConfigRestored = $false
    ConfigUpdated = $false
    AclFixed = $false
    SshdConfigTest = $null
    ServiceStatus = $null
    ServicePath = $null
    Port22 = $null
    Firewall22 = $null
    RecentCrashesAfter = $null
    Rollback = $Rollback
    Status = "STARTED"
    Error = $null
}

try {
    if (-not (Test-Path -LiteralPath $Root)) {
        throw "No existe Root Runeforge: $Root"
    }

    if (-not (Test-Path -LiteralPath $ProgramDataSsh)) {
        throw "No existe carpeta SSH: $ProgramDataSsh"
    }

    if (-not (Test-Path -LiteralPath $SshdConfig)) {
        throw "No existe sshd_config: $SshdConfig"
    }

    if (-not (Test-Path -LiteralPath $AdminKeys)) {
        throw "No existe administrators_authorized_keys: $AdminKeys"
    }

    sc.exe qc sshd | Set-Content -LiteralPath $ServiceBackup -Encoding utf8

    Get-NetFirewallRule -Enabled True -Direction Inbound -ErrorAction SilentlyContinue |
        ForEach-Object {
            $r = $_
            $pf = Get-NetFirewallPortFilter -AssociatedNetFirewallRule $r -ErrorAction SilentlyContinue
            $af = Get-NetFirewallAddressFilter -AssociatedNetFirewallRule $r -ErrorAction SilentlyContinue
            $app = Get-NetFirewallApplicationFilter -AssociatedNetFirewallRule $r -ErrorAction SilentlyContinue

            foreach ($p in $pf) {
                if ([string]$p.LocalPort -eq "22") {
                    [pscustomobject]@{
                        DisplayName = $r.DisplayName
                        Name = $r.Name
                        Action = $r.Action.ToString()
                        Profile = $r.Profile.ToString()
                        Protocol = $p.Protocol.ToString()
                        LocalPort = [string]$p.LocalPort
                        RemoteAddress = [string]$af.RemoteAddress
                        Program = [string]$app.Program
                    }
                }
            }
        } | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $FirewallBackup -Encoding utf8

    Copy-Item -LiteralPath $ProgramDataSsh -Destination $ProgramDataBackup -Recurse -Force

    $RollbackCode = @"
# RUNEFORGE ROLLBACK REINSTALL OPENSSH
# Fecha: $Ts

Set-StrictMode -Version Latest
`$ErrorActionPreference = "Stop"

`$OpenSshDir = "$OpenSshDir"
`$OldBackupDir = "$OldBackupDir"
`$ProgramDataSsh = "$ProgramDataSsh"
`$ProgramDataBackup = "$ProgramDataBackup"

Write-Host "[ROLLBACK_REINSTALL_OPENSSH] Iniciando..." -ForegroundColor Yellow

Stop-Service sshd -Force -ErrorAction SilentlyContinue

if (Test-Path -LiteralPath `$OpenSshDir) {
    Rename-Item -LiteralPath `$OpenSshDir -NewName ("OpenSSH-Win64_ROLLBACK_FAILED_" + (Get-Date -Format "yyyyMMdd_HHmmss")) -Force
}

if (Test-Path -LiteralPath `$OldBackupDir) {
    Rename-Item -LiteralPath `$OldBackupDir -NewName "OpenSSH-Win64" -Force
}

if (Test-Path -LiteralPath `$ProgramDataBackup) {
    Copy-Item -LiteralPath (Join-Path `$ProgramDataBackup "*") -Destination `$ProgramDataSsh -Recurse -Force
}

sc.exe config sshd binPath= "`"`$OpenSshDir\sshd.exe`"" | Out-Null
sc.exe config sshd start= auto | Out-Null

icacls "`$ProgramDataSsh\administrators_authorized_keys" /inheritance:r | Out-Null
icacls "`$ProgramDataSsh\administrators_authorized_keys" /grant:r "*S-1-5-18:F" "*S-1-5-32-544:F" | Out-Null
icacls "`$ProgramDataSsh\administrators_authorized_keys" /setowner "*S-1-5-32-544" | Out-Null

Start-Service sshd

Write-Host "[OK] Rollback OpenSSH aplicado." -ForegroundColor Green
"@

    Set-Content -LiteralPath $Rollback -Value $RollbackCode -Encoding utf8BOM -Force

    Write-Host "[INFO] Consultando release oficial GitHub..." -ForegroundColor Yellow
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/PowerShell/Win32-OpenSSH/releases/latest" -Headers @{ "User-Agent" = "Runeforge-Reinstall-OpenSSH" } -TimeoutSec 30
    $asset = $release.assets | Where-Object { $_.name -match "^OpenSSH-Win64.*\.zip$" } | Select-Object -First 1

    if (-not $asset) {
        throw "No se encontró asset OpenSSH-Win64.zip en el release latest."
    }

    $Result.DownloadUrl = $asset.browser_download_url

    Write-Host "[INFO] Descargando: $($Result.DownloadUrl)" -ForegroundColor Yellow
    Invoke-WebRequest -Uri $Result.DownloadUrl -OutFile $ZipPath -UseBasicParsing -TimeoutSec 120
    $Result.Downloaded = $true
    $Result.ZipHashSHA256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $ZipPath).Hash

    Expand-Archive -LiteralPath $ZipPath -DestinationPath $ExtractDir -Force
    $Result.Extracted = $true

    $ExtractedOpenSsh = Get-ChildItem -LiteralPath $ExtractDir -Directory -Recurse |
        Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName "sshd.exe") } |
        Select-Object -First 1

    if (-not $ExtractedOpenSsh) {
        if (Test-Path -LiteralPath (Join-Path $ExtractDir "sshd.exe")) {
            $ExtractedOpenSsh = Get-Item -LiteralPath $ExtractDir
        } else {
            throw "No se encontró sshd.exe dentro del ZIP extraído."
        }
    }

    if (-not (Test-Path -LiteralPath (Join-Path $ExtractedOpenSsh.FullName "sftp-server.exe"))) {
        throw "El paquete nuevo no contiene sftp-server.exe."
    }

    Stop-Service sshd -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2

    if (Test-Path -LiteralPath $OpenSshDir) {
        Rename-Item -LiteralPath $OpenSshDir -NewName ("OpenSSH-Win64_BROKEN_" + $Stamp) -Force
        $Result.OldFolderBackedUp = $true
    }

    New-Item -ItemType Directory -Force -Path $OpenSshDir | Out-Null
    Copy-Item -LiteralPath (Join-Path $ExtractedOpenSsh.FullName "*") -Destination $OpenSshDir -Recurse -Force
    $Result.NewFolderInstalled = $true

    $NewSshd = Join-Path $OpenSshDir "sshd.exe"
    $NewSftp = Join-Path $OpenSshDir "sftp-server.exe"

    if (-not (Test-Path -LiteralPath $NewSshd)) {
        throw "No quedó instalado sshd.exe nuevo en $NewSshd"
    }

    if (-not (Test-Path -LiteralPath $NewSftp)) {
        throw "No quedó instalado sftp-server.exe nuevo en $NewSftp"
    }

    sc.exe config sshd binPath= "`"$NewSshd`"" | Out-Null
    sc.exe config sshd start= auto | Out-Null
    $Result.ServiceRepointed = $true

    Copy-Item -LiteralPath (Join-Path $ProgramDataBackup "*") -Destination $ProgramDataSsh -Recurse -Force
    $Result.ConfigRestored = $true

    $lines = Get-Content -LiteralPath $SshdConfig

    $lines = $lines | ForEach-Object {
        if ($_ -match "^\s*Subsystem\s+sftp\s+") {
            "Subsystem sftp `"$NewSftp`""
        } else {
            $_
        }
    }

    if (-not ($lines -match "^\s*Subsystem\s+sftp\s+")) {
        $lines += "Subsystem sftp `"$NewSftp`""
    }

    Set-Content -LiteralPath $SshdConfig -Value $lines -Encoding ascii -Force
    $Result.ConfigUpdated = $true

    icacls $ProgramDataSsh /inheritance:r | Out-Null
    icacls $ProgramDataSsh /grant:r "*S-1-5-18:F" "*S-1-5-32-544:F" | Out-Null

    icacls $AdminKeys /inheritance:r | Out-Null
    icacls $AdminKeys /grant:r "*S-1-5-18:F" "*S-1-5-32-544:F" | Out-Null
    icacls $AdminKeys /remove:g "*S-1-1-0" "*S-1-5-11" "*S-1-5-32-545" "$env:USERDOMAIN\$env:USERNAME" 2>$null | Out-Null
    icacls $AdminKeys /setowner "*S-1-5-32-544" | Out-Null

    icacls $OpenSshDir /inheritance:r | Out-Null
    icacls $OpenSshDir /grant:r "*S-1-5-18:F" "*S-1-5-32-544:F" "*S-1-5-32-545:RX" | Out-Null

    $Result.AclFixed = $true

    $hostFix = Join-Path $OpenSshDir "FixHostFilePermissions.ps1"
    $userFix = Join-Path $OpenSshDir "FixUserFilePermissions.ps1"

    if (Test-Path -LiteralPath $hostFix) {
        powershell.exe -ExecutionPolicy Bypass -File $hostFix -Confirm:$false
    }

    if (Test-Path -LiteralPath $userFix) {
        powershell.exe -ExecutionPolicy Bypass -File $userFix -Confirm:$false
    }

    & $NewSshd -t -f $SshdConfig
    $Result.SshdConfigTest = $LASTEXITCODE

    if ($LASTEXITCODE -ne 0) {
        throw "sshd_config no pasó validación con OpenSSH reinstalado."
    }

    $existingTailRule = Get-NetFirewallRule -DisplayName "Runeforge SSH Tailscale Only" -ErrorAction SilentlyContinue

    if (-not $existingTailRule) {
        New-NetFirewallRule `
            -DisplayName "Runeforge SSH Tailscale Only" `
            -Direction Inbound `
            -Action Allow `
            -Protocol TCP `
            -LocalPort 22 `
            -RemoteAddress "100.64.0.0/10" `
            -Program $NewSshd `
            -Profile Any `
            -Enabled True | Out-Null
    }

    Start-Service sshd
    Start-Sleep -Seconds 3

    $svc = Get-Service sshd -ErrorAction Stop
    $svcCim = Get-CimInstance Win32_Service -Filter "Name='sshd'"

    $Result.ServiceStatus = $svc.Status.ToString()
    $Result.ServicePath = $svcCim.PathName

    if ($svc.Status -ne "Running") {
        throw "sshd no quedó Running."
    }

    $Result.Port22 = Get-NetTCPConnection -State Listen -LocalPort 22 -ErrorAction SilentlyContinue |
        Select-Object LocalAddress,LocalPort,OwningProcess

    $Result.Firewall22 = Get-NetFirewallRule -Enabled True -Direction Inbound -ErrorAction SilentlyContinue |
        ForEach-Object {
            $r = $_
            $pf = Get-NetFirewallPortFilter -AssociatedNetFirewallRule $r -ErrorAction SilentlyContinue
            $af = Get-NetFirewallAddressFilter -AssociatedNetFirewallRule $r -ErrorAction SilentlyContinue
            $app = Get-NetFirewallApplicationFilter -AssociatedNetFirewallRule $r -ErrorAction SilentlyContinue

            foreach ($p in $pf) {
                if ([string]$p.LocalPort -eq "22") {
                    [pscustomobject]@{
                        DisplayName = $r.DisplayName
                        Action = $r.Action.ToString()
                        Profile = $r.Profile.ToString()
                        Protocol = $p.Protocol.ToString()
                        LocalPort = [string]$p.LocalPort
                        RemoteAddress = [string]$af.RemoteAddress
                        Program = [string]$app.Program
                    }
                }
            }
        }

    $Result.RecentCrashesAfter = Get-WinEvent -FilterHashtable @{
        LogName = "Application"
        StartTime = (Get-Date).AddMinutes(-3)
    } -ErrorAction SilentlyContinue |
    Where-Object { $_.Message -match "sshd.exe|APPCRASH|c0000005" } |
    Select-Object TimeCreated,ProviderName,Id

    $Result.Status = "OK_OPENSSH_REINSTALLED"
}
catch {
    $Result.Status = "FAILED"
    $Result.Error = $_.Exception.Message
}
finally {
    $Result | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $Log -Encoding utf8
    Write-Host ""
    Write-Host "[RUNEFORGE_REINSTALAR_OPENSSH_RESULT]" -ForegroundColor Green
    $Result | ConvertTo-Json -Depth 10
}