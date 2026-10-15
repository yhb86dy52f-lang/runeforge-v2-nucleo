#Requires -Version 5.1
# RUNEFORGE_IPHONE_AUDIT_READONLY v1.2 - fix mkdir + USB detect mejorado
param(
  [string]$BackupRoot = "$env:APPDATA\Apple Computer\MobileSync\Backup",
  [string]$AltBackupRoot = "$env:USERPROFILE\Apple\MobileSync\Backup",
  [string]$OutDir = "C:\RUNEFORGE_V2_CORE\knowledge\devices"
)

$ts = Get-Date -Format "yyyy-MM-ddTHH:mm:ssK"
$tsFile = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
# FIX H-02: Crea ruta si no existe - tu error anterior
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

Write-Host "[$ts] === RUNEFORGE AUDIT READONLY v1.2 START ===" -F Cyan
Write-Host "[$ts] Host: $env:COMPUTERNAME User: $env:USERNAME" -F Gray
Write-Host "[$ts] OutDir: $OutDir" -F Gray

Write-Host "`n[$ts] [1] Apple Mobile Device Service" -F Yellow
$svc = Get-Service -Name "Apple Mobile Device Service" -ErrorAction SilentlyContinue
if($svc){ Write-Host "[$ts] Status: $($svc.Status)" -F Green } else { Write-Host "[$ts] No instalado - instala Apple Devices desde Microsoft Store" -F Red }

Write-Host "`n[$ts] [2] USB Apple - detect mejorado" -F Yellow
$devs = @()
$devs += Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue | Where-Object { $_.FriendlyName -like "*iPhone*" -or $_.FriendlyName -like "*Apple Mobile*" -or $_.InstanceId -like "*APPLE*" -or $_.InstanceId -like "*VID_05AC*" }
$devs += Get-PnpDevice -Class WPD -PresentOnly -ErrorAction SilentlyContinue | Where-Object { $_.FriendlyName -like "*iPhone*" }
$devs = $devs | Sort-Object InstanceId -Unique
if($devs){ $devs | ForEach-Object { Write-Host "[$ts] $($_.Status) | $($_.Class) | $($_.FriendlyName) | $($_.InstanceId)" -F White } } else { Write-Host "[$ts] Ningun iPhone USB detectado - conecta por cable Lightning y desbloquea" -F Yellow }

Write-Host "`n[$ts] [3] Lockdown - REQUIERE CONFIANZA" -F Yellow
@("$env:ProgramData\Apple\Lockdown","$env:ALLUSERSPROFILE\Apple\Lockdown") | ForEach-Object {
  if(Test-Path $_){
    Write-Host "[$ts] Carpeta: $_" -F Green
    Get-ChildItem $_ -Filter "*.plist" -ErrorAction SilentlyContinue | ForEach-Object { Write-Host "[$ts]  - $($_.Name) $($_.LastWriteTime) $($_.Length) bytes" -F White }
  }
}

Write-Host "`n[$ts] [4] Backups" -F Yellow
foreach($root in @($BackupRoot,$AltBackupRoot) | Where-Object { Test-Path $_ }){
  Write-Host "[$ts] $root" -F White
  Get-ChildItem $root -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    $size=[math]::Round((Get-ChildItem $_.FullName -Recurse -File -EA SilentlyContinue | Measure Length -Sum).Sum/1MB,2)
    Write-Host "[$ts] UDID $($_.Name.Substring(0,8))... Last $($_.LastWriteTime) ${size}MB Manifest $((Test-Path (Join-Path $_.FullName 'Manifest.plist')))" -F Gray
  }
}

Write-Host "`n[$ts] [5] File Sharing MANUAL: Apple Devices > iPhone > Archivos > aShell" -F White
Write-Host "[$ts] [6] BLOQUEADO sin jailbreak: /private, sandbox otras apps, MAC real" -F Red
Write-Host "[$ts] === AUDIT END v1.2 ===" -F Cyan
Write-Host "[$ts] Guarda en $OutDir\audit-$tsFile.txt" -F Gray
