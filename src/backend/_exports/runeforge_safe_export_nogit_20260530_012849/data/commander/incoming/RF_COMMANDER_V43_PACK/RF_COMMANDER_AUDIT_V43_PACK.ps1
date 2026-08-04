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
$ReportDir = Join-Path $Root "data\commander\reports"
$Report = Join-Path $ReportDir "RF_COMMANDER_AUDIT_V43_PACK_$stamp.md"

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

New-Item -ItemType Directory -Force -Path $ReportDir | Out-Null

$files = foreach($name in $Expected){
  $p = Join-Path $SrcAhk $name
  if(Test-Path $p){
    $item = Get-Item $p
    [pscustomobject]@{
      Name = $name
      Exists = $true
      Bytes = $item.Length
      Lines = (Get-Content -LiteralPath $p -ErrorAction Stop).Count
      Sha256 = (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash
    }
  } else {
    [pscustomobject]@{
      Name = $name
      Exists = $false
      Bytes = 0
      Lines = 0
      Sha256 = "MISSING"
    }
  }
}

$ahkExe = Get-AhkExe
$dirs = [ordered]@{
  Root = $Root
  App = Join-Path $Root "app"
  Scripts = Join-Path $Root "scripts"
  AhkTarget = Join-Path $Root "scripts\ahk"
  CommanderData = Join-Path $Root "data\commander"
  CommanderExports = Join-Path $Root "data\commander\exports"
  CommanderSnippets = Join-Path $Root "data\commander\snippets"
}

$dirRows = foreach($k in $dirs.Keys){
  [pscustomobject]@{Name=$k; Path=$dirs[$k]; Exists=(Test-Path $dirs[$k])}
}

$md = @()
$md += "# RF_COMMANDER_AUDIT_V43_PACK"
$md += ""
$md += "- Fecha: $ts"
$md += "- Root: ``$Root``"
$md += "- Source: ``$SrcAhk``"
$md += "- AutoHotkey: " + ($(if($ahkExe){ "``$ahkExe``" } else { "PENDIENTE / NO DETECTADO" }))
$md += ""
$md += "## Directorios"
$md += ""
$md += "| Name | Exists | Path |"
$md += "|---|---:|---|"
foreach($r in $dirRows){ $md += "| $($r.Name) | $($r.Exists) | ``$($r.Path)`` |" }
$md += ""
$md += "## Archivos AHK"
$md += ""
$md += "| Name | Exists | Bytes | Lines | SHA256 |"
$md += "|---|---:|---:|---:|---|"
foreach($f in $files){ $md += "| $($f.Name) | $($f.Exists) | $($f.Bytes) | $($f.Lines) | ``$($f.Sha256)`` |" }
$md += ""
$md += "## Veredicto"
$ok = (($files | Where-Object { -not $_.Exists }).Count -eq 0) -and [bool]$ahkExe -and (Test-Path $Root)
if($ok){
  $md += "OK_AUDIT: paquete listo para instalación."
} else {
  $md += "PENDIENTE: revisar Root, AutoHotkey o archivos faltantes antes de instalar."
}

$md -join "`r`n" | Set-Content -LiteralPath $Report -Encoding UTF8

Write-Host "[RF_COMMANDER_AUDIT_V43_PACK][$ts]"
[pscustomobject]@{
  OkAudit = $ok
  RootExists = Test-Path $Root
  SourceAhkExists = Test-Path $SrcAhk
  AutoHotkeyExe = $ahkExe
  MissingFiles = @($files | Where-Object { -not $_.Exists } | Select-Object -ExpandProperty Name) -join ", "
  Report = $Report
} | Format-List
