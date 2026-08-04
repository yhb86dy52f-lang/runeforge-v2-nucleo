#Requires -Version 7.0
[CmdletBinding()]
param(
  [string]$Root = "C:\RUNEFOGE_PRO\runeforge"
)

$ErrorActionPreference = "Stop"
$ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
$SrcAhk = Join-Path $Here "scripts\ahk"
$TargetAhk = Join-Path $Root "scripts\ahk"
$CommanderData = Join-Path $Root "data\commander"
$BackupDir = Join-Path $CommanderData "backups\ahk_$stamp"
$Launcher = Join-Path $Root "scripts\Start-Runeforge-Panel.ps1"
$ReportDir = Join-Path $CommanderData "reports"
$Report = Join-Path $ReportDir "RF_COMMANDER_INSTALL_V43_PACK_$stamp.md"

$Expected = @(
  "RUNEFORGE_COMMANDER_V43_5_CLEAN_OPS_FUSION.ahk",
  "RUNEFORGE_COMMANDER_V43_6_QUICK_DOCK.ahk",
  "RUNEFORGE_COMMANDER_V43_4_CLEAN_OPS.ahk",
  "RUNEFORGE_COMMANDER_V42_EXPORT_BRIDGE.ahk",
  "RUNEFORGE_COMMANDER_V41_GHOST_FUSION.ahk"
)

function Get-AhkExe {
  $candidates = @(
    "$env:ProgramFiles\AutoHotkey\v2\AutoHotkey64.exe",
    "$env:ProgramFiles\AutoHotkey\AutoHotkey64.exe",
    "$env:LOCALAPPDATA\Programs\AutoHotkey\v2\AutoHotkey64.exe"
  )
  foreach($c in $candidates){ if(Test-Path $c){ return $c } }
  $cmd = Get-Command AutoHotkey64.exe -ErrorAction SilentlyContinue
  if($cmd){ return $cmd.Source }
  $cmd = Get-Command AutoHotkey.exe -ErrorAction SilentlyContinue
  if($cmd){ return $cmd.Source }
  return $null
}

if(-not (Test-Path $Root)){ throw "Root no existe: $Root" }
if(-not (Test-Path $SrcAhk)){ throw "No existe carpeta origen: $SrcAhk" }

$missing = @()
foreach($name in $Expected){
  $p = Join-Path $SrcAhk $name
  if(-not (Test-Path $p)){ $missing += $name }
}
if($missing.Count -gt 0){ throw "Faltan archivos AHK: $($missing -join ', ')" }

$ahkExe = Get-AhkExe
if(-not $ahkExe){ throw "AutoHotkey no detectado. Instala AutoHotkey v2 antes de continuar." }

New-Item -ItemType Directory -Force -Path $TargetAhk,$CommanderData,(Join-Path $CommanderData "exports"),(Join-Path $CommanderData "snippets"),$BackupDir,$ReportDir | Out-Null

# Backup existing AHK and launcher
if(Test-Path $TargetAhk){
  Get-ChildItem -LiteralPath $TargetAhk -Filter "*.ahk" -File -ErrorAction SilentlyContinue | Copy-Item -Destination $BackupDir -Force
}
if(Test-Path $Launcher){
  Copy-Item -LiteralPath $Launcher -Destination (Join-Path $BackupDir "Start-Runeforge-Panel.ps1.bak") -Force
}

# Install AHK files
foreach($name in $Expected){
  Copy-Item -LiteralPath (Join-Path $SrcAhk $name) -Destination (Join-Path $TargetAhk $name) -Force
}

# Create launcher
$launcherContent = @'
#Requires -Version 7.0
[CmdletBinding()]
param(
  [ValidateSet("Full","Quick","Both","LegacyV43_4","LegacyV42","LegacyV41")]
  [string]$Mode = "Quick"
)

$ErrorActionPreference = "Stop"
$Root = "C:\RUNEFOGE_PRO\runeforge"
$AhkDir = Join-Path $Root "scripts\ahk"

function Get-AhkExe {
  $candidates = @(
    "$env:ProgramFiles\AutoHotkey\v2\AutoHotkey64.exe",
    "$env:ProgramFiles\AutoHotkey\AutoHotkey64.exe",
    "$env:LOCALAPPDATA\Programs\AutoHotkey\v2\AutoHotkey64.exe"
  )
  foreach($c in $candidates){ if(Test-Path $c){ return $c } }
  $cmd = Get-Command AutoHotkey64.exe -ErrorAction SilentlyContinue
  if($cmd){ return $cmd.Source }
  $cmd = Get-Command AutoHotkey.exe -ErrorAction SilentlyContinue
  if($cmd){ return $cmd.Source }
  throw "AutoHotkey v2 no detectado."
}

function Start-AhkFile([string]$Name) {
  $exe = Get-AhkExe
  $script = Join-Path $AhkDir $Name
  if(-not (Test-Path $script)){ throw "No existe AHK: $script" }
  Start-Process -FilePath $exe -ArgumentList "`"$script`"" -WorkingDirectory $Root
  Write-Host "[RUNEFORGE_PANEL] Started $Name"
}

switch($Mode){
  "Full"       { Start-AhkFile "RUNEFORGE_COMMANDER_V43_5_CLEAN_OPS_FUSION.ahk" }
  "Quick"      { Start-AhkFile "RUNEFORGE_COMMANDER_V43_6_QUICK_DOCK.ahk" }
  "Both"       { Start-AhkFile "RUNEFORGE_COMMANDER_V43_5_CLEAN_OPS_FUSION.ahk"; Start-Sleep -Milliseconds 400; Start-AhkFile "RUNEFORGE_COMMANDER_V43_6_QUICK_DOCK.ahk" }
  "LegacyV43_4"{ Start-AhkFile "RUNEFORGE_COMMANDER_V43_4_CLEAN_OPS.ahk" }
  "LegacyV42"  { Start-AhkFile "RUNEFORGE_COMMANDER_V42_EXPORT_BRIDGE.ahk" }
  "LegacyV41"  { Start-AhkFile "RUNEFORGE_COMMANDER_V41_GHOST_FUSION.ahk" }
}
'@

$launcherContent | Set-Content -LiteralPath $Launcher -Encoding UTF8

$installed = foreach($name in $Expected){
  $p = Join-Path $TargetAhk $name
  $item = Get-Item $p
  [pscustomobject]@{
    Name=$name
    Bytes=$item.Length
    Sha256=(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash
  }
}

$md = @()
$md += "# RF_COMMANDER_INSTALL_V43_PACK"
$md += ""
$md += "- Fecha: $ts"
$md += "- Root: ``$Root``"
$md += "- TargetAhk: ``$TargetAhk``"
$md += "- BackupDir: ``$BackupDir``"
$md += "- Launcher: ``$Launcher``"
$md += "- AutoHotkey: ``$ahkExe``"
$md += ""
$md += "## Installed"
$md += ""
$md += "| Name | Bytes | SHA256 |"
$md += "|---|---:|---|"
foreach($f in $installed){ $md += "| $($f.Name) | $($f.Bytes) | ``$($f.Sha256)`` |" }
$md += ""
$md += "## Launch"
$md += ""
$md += "```powershell"
$md += "pwsh -NoProfile -ExecutionPolicy Bypass -File `"$Launcher`" -Mode Quick"
$md += "pwsh -NoProfile -ExecutionPolicy Bypass -File `"$Launcher`" -Mode Full"
$md += "pwsh -NoProfile -ExecutionPolicy Bypass -File `"$Launcher`" -Mode Both"
$md += "```"

$md -join "`r`n" | Set-Content -LiteralPath $Report -Encoding UTF8

Write-Host "[RF_COMMANDER_INSTALL_V43_PACK][$ts]"
[pscustomobject]@{
  Installed = $true
  Root = $Root
  TargetAhk = $TargetAhk
  BackupDir = $BackupDir
  Launcher = $Launcher
  Report = $Report
  AutoHotkeyExe = $ahkExe
} | Format-List
