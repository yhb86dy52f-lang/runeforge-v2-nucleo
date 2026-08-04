Set-StrictMode -Version Latest
$ErrorActionPreference="Stop"

$Ts=Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$Stamp=Get-Date -Format "yyyyMMdd_HHmmss"

Write-Host "[RUNEFORGE_OPENSSH_PIN_983][$Ts]" -ForegroundColor Cyan

$Root="C:\RUNEFOGE_PRO\runeforge"
$AuditDir=Join-Path $Root "data\audits\openssh_pin_983_$Stamp"
$OpenSshDir="C:\Program Files\OpenSSH-Win64"
$BrokenDir="C:\Program Files\OpenSSH-Win64_BROKEN10_$Stamp"
$ProgramDataSsh="C:\ProgramData\ssh"
$SshdConfig="$ProgramDataSsh\sshd_config"
$AdminKeys="$ProgramDataSsh\administrators_authorized_keys"
$ZipPath=Join-Path $AuditDir "OpenSSH-Win64-v9.8.3.zip"
$ExtractDir=Join-Path $AuditDir "extract"
$ProgramDataBackup=Join-Path $AuditDir "ProgramData_ssh_backup_$Stamp"
$CurrentOpenSshBackup=Join-Path $AuditDir "OpenSSH_Win64_current_filelist_$Stamp.txt"
$Log=Join-Path $AuditDir "openssh_pin_983_result_$Stamp.json"

New-Item -ItemType Directory -Force -Path $AuditDir | Out-Null

$r=[ordered]@{
 Timestamp=$Ts
 AuditDir=$AuditDir
 TargetTag="v9.8.3.0p2-Preview"
 CurrentDir=$OpenSshDir
 BrokenDir=$BrokenDir
 ProgramDataBackup=$ProgramDataBackup
 DownloadUrl=$null
 Downloaded=$false
 ZipSHA256=$null
 ExtractedSource=$null
 OldFolderMoved=$false
 NewCopied=$false
 ConfigRestored=$false
 ConfigUpdated=$false
 AclFixed=$false
 SshdConfigTest=$null
 ServiceStatus=$null
 ServicePath=$null
 SshdVersion=$null
 Port22=$null
 RecentCrashes=$null
 Status="STARTED"
 Error=$null
}

try{
 if(!(Test-Path $Root)){throw "No existe Root: $Root"}
 if(!(Test-Path $ProgramDataSsh)){throw "No existe $ProgramDataSsh"}
 if(!(Test-Path $SshdConfig)){throw "No existe $SshdConfig"}
 if(!(Test-Path $AdminKeys)){throw "No existe $AdminKeys"}

 Copy-Item -LiteralPath $ProgramDataSsh -Destination $ProgramDataBackup -Recurse -Force

 if(Test-Path $OpenSshDir){
   Get-ChildItem -LiteralPath $OpenSshDir -Force | Select-Object FullName,Length,LastWriteTime | Out-File -LiteralPath $CurrentOpenSshBackup -Encoding utf8
 }

 [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
 $release=Invoke-RestMethod -Uri "https://api.github.com/repos/PowerShell/Win32-OpenSSH/releases/tags/v9.8.3.0p2-Preview" -Headers @{"User-Agent"="Runeforge-OpenSSH-Pin"} -TimeoutSec 30
 $asset=$release.assets | Where-Object {$_.name -eq "OpenSSH-Win64.zip"} | Select-Object -First 1
 if(!$asset){throw "No se encontró OpenSSH-Win64.zip en v9.8.3.0p2-Preview"}

 $r.DownloadUrl=$asset.browser_download_url
 Invoke-WebRequest -Uri $r.DownloadUrl -OutFile $ZipPath -UseBasicParsing -TimeoutSec 120
 $r.Downloaded=$true
 $r.ZipSHA256=(Get-FileHash -Algorithm SHA256 -LiteralPath $ZipPath).Hash

 Expand-Archive -LiteralPath $ZipPath -DestinationPath $ExtractDir -Force

 $src=Get-ChildItem -LiteralPath $ExtractDir -Directory -Recurse | Where-Object {Test-Path -LiteralPath (Join-Path $_.FullName "sshd.exe")} | Select-Object -First 1
 if(!$src){throw "No se encontró carpeta con sshd.exe dentro de $ExtractDir"}
 $r.ExtractedSource=$src.FullName

 Stop-Service sshd -Force -ErrorAction SilentlyContinue
 Start-Sleep -Seconds 2

 if(Test-Path $OpenSshDir){
   Rename-Item -LiteralPath $OpenSshDir -NewName ("OpenSSH-Win64_BROKEN10_"+$Stamp) -Force
   $r.OldFolderMoved=$true
 }

 New-Item -ItemType Directory -Force -Path $OpenSshDir | Out-Null
 Copy-Item -Path (Join-Path $src.FullName "*") -Destination $OpenSshDir -Recurse -Force
 $r.NewCopied=$true

 Get-ChildItem -LiteralPath $OpenSshDir -Recurse -Force -ErrorAction SilentlyContinue | Unblock-File -ErrorAction SilentlyContinue

 $NewSshd=Join-Path $OpenSshDir "sshd.exe"
 $NewSftp=Join-Path $OpenSshDir "sftp-server.exe"
 if(!(Test-Path $NewSshd)){throw "No quedó sshd.exe en $NewSshd"}
 if(!(Test-Path $NewSftp)){throw "No quedó sftp-server.exe en $NewSftp"}

 Copy-Item -Path (Join-Path $ProgramDataBackup "*") -Destination $ProgramDataSsh -Recurse -Force
 $r.ConfigRestored=$true

 $lines=Get-Content -LiteralPath $SshdConfig
 $lines=$lines | ForEach-Object {
   if($_ -match "^\s*Subsystem\s+sftp\s+"){"Subsystem sftp `"$NewSftp`""}else{$_}
 }
 if(-not($lines -match "^\s*Subsystem\s+sftp\s+")){
   $lines+="Subsystem sftp `"$NewSftp`""
 }
 Set-Content -LiteralPath $SshdConfig -Value $lines -Encoding ascii -Force
 $r.ConfigUpdated=$true

 icacls $OpenSshDir /inheritance:e /t /c | Out-Null
 icacls $OpenSshDir /grant:r "*S-1-5-18:F" "*S-1-5-32-544:F" "*S-1-5-32-545:RX" /t /c | Out-Null

 icacls $AdminKeys /inheritance:r | Out-Null
 icacls $AdminKeys /grant:r "*S-1-5-18:F" "*S-1-5-32-544:F" | Out-Null
 icacls $AdminKeys /remove:g "*S-1-1-0" "*S-1-5-11" "*S-1-5-32-545" 2>$null | Out-Null
 icacls $AdminKeys /setowner "*S-1-5-32-544" | Out-Null

 $r.AclFixed=$true

 sc.exe config sshd binPath= "`"$NewSshd`"" | Out-Null
 sc.exe config sshd start= auto | Out-Null

 & $NewSshd -t -f $SshdConfig
 $r.SshdConfigTest=$LASTEXITCODE
 if($LASTEXITCODE -ne 0){throw "sshd_config no pasó validación"}

 Start-Service sshd
 Start-Sleep -Seconds 3

 $svc=Get-Service sshd
 $svcCim=Get-CimInstance Win32_Service -Filter "Name='sshd'"
 $r.ServiceStatus=$svc.Status.ToString()
 $r.ServicePath=$svcCim.PathName

 $v=(Get-Item $NewSshd).VersionInfo
 $r.SshdVersion="$($v.FileVersion) / $($v.ProductVersion)"

 $r.Port22=Get-NetTCPConnection -State Listen -LocalPort 22 -ErrorAction SilentlyContinue | Select-Object LocalAddress,LocalPort,OwningProcess

 $r.RecentCrashes=Get-WinEvent -FilterHashtable @{LogName="Application";StartTime=(Get-Date).AddMinutes(-3)} -ErrorAction SilentlyContinue | Where-Object {$_.Message -match "sshd.exe|sshd-session.exe|APPCRASH|c0000005"} | Select-Object TimeCreated,ProviderName,Id

 if($svc.Status -ne "Running"){throw "sshd no quedó Running"}

 $r.Status="OK_OPENSSH_PIN_983_APPLIED"
}catch{
 $r.Status="FAILED"
 $r.Error=$_.Exception.Message
}

$r | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $Log -Encoding utf8
Write-Host "[RUNEFORGE_OPENSSH_PIN_983_RESULT]" -ForegroundColor Green
$r | ConvertTo-Json -Depth 8