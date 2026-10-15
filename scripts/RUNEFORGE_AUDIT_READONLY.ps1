#Requires -Version 5.1
<#
  RUNEFORGE_IPHONE_AUDIT_READONLY.ps1
  v1.1 - Solo lectura - iPhone 14 Pro
  Timestamp obligatorio en toda salida
  Requiere "Confiar en este equipo" para Lockdown/Backup
#>
param(
  [string]$BackupRoot = "$env:APPDATA\Apple Computer\MobileSync\Backup",
  [string]$AltBackupRoot = "$env:USERPROFILE\Apple\MobileSync\Backup"
)

$ts = Get-Date -Format "yyyy-MM-ddTHH:mm:ssK"
$tsFile = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
Write-Host "[$ts] === RUNEFORGE AUDIT READONLY START ===" -F Cyan
Write-Host "[$ts] Host: $env:COMPUTERNAME User: $env:USERNAME" -F Gray

Write-Host "`n[$ts] [1] Apple Mobile Device Service" -F Yellow
$svc = Get-Service -Name "Apple Mobile Device Service" -ErrorAction SilentlyContinue
if($svc){ Write-Host "[$ts] Status: $($svc.Status)" -F Green } else { Write-Host "[$ts] Servicio no encontrado - instala Apple Devices o iTunes" -F Red }

Write-Host "`n[$ts] [2] USB Apple" -F Yellow
Get-PnpDevice -Class USB -PresentOnly -ErrorAction SilentlyContinue | Where-Object { $_.FriendlyName -like "*Apple*" } | ForEach-Object { Write-Host "[$ts] $($_.Status) | $($_.FriendlyName)" }

Write-Host "`n[$ts] [3] Lockdown - REQUIERE CONFIANZA" -F Yellow
@("$env:ProgramData\Apple\Lockdown","$env:ALLUSERSPROFILE\Apple\Lockdown") | Where-Object { Test-Path $_ } | ForEach-Object {
  Write-Host "[$ts] $_" -F Green
  Get-ChildItem $_ -Filter "*.plist" | Select Name,LastWriteTime | Format-Table -AutoSize
}

Write-Host "`n[$ts] [4] Backups - REQUIERE CONFIANZA" -F Yellow
foreach($root in @($BackupRoot,$AltBackupRoot) | Where-Object { Test-Path $_ }){
  Write-Host "[$ts] $root" -F White
  Get-ChildItem $root -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    $size=[math]::Round((Get-ChildItem $_.FullName -Recurse -File -EA SilentlyContinue | Measure Length -Sum).Sum/1MB,2)
    [PSCustomObject]@{Timestamp=$ts; UDID=$_.Name; LastWrite=$_.LastWriteTime; SizeMB=$size; Manifest=Test-Path (Join-Path $_.FullName "Manifest.plist")} | Format-List
  }
}

Write-Host "`n[$ts] [5] File Sharing MANUAL: iTunes > iPhone > Archivos > aShell > Guardar en D:\Runeforge\Backup\aShell-$tsFile" -F White
Write-Host "`n[$ts] [6] BLOQUEADO sin jailbreak: /private, sandbox otras apps, Keychain, MAC real, IMEI" -F Red
Write-Host "[$ts] PERMITIDO: ~/Documents aShell, Files importado, Fotos con permiso, Shortcuts telemetry" -F Green
Write-Host "`n[$ts] === AUDIT END ===" -F Cyan
