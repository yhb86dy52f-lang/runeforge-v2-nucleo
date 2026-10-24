#Requires -Version 5.1
# Runeforge-Init.ps1 - Bootstrap del taller RUNEFORGE (una sola vez)

$ErrorActionPreference = 'Stop'
$ROOT = 'C:\RUNEFORGE_V2_CORE'
if(-not (Test-Path -LiteralPath $ROOT)){ throw "No existe $ROOT" }

Write-Host "=== RUNEFORGE INIT ===" -ForegroundColor Cyan

# ---------- 1. Estructura base ----------
$dirs = @(
  "$ROOT\scripts",
  "$ROOT\scripts\_canonical",
  "$ROOT\scripts\_quarantine",
  "$ROOT\apps\_template\src-tauri\src",
  "$ROOT\apps\_template\src-tauri\.cargo",
  "$ROOT\apps\_template\src",
  "$ROOT\registry",
  "$ROOT\target\_shipped"
)
foreach($d in $dirs){
  if(-not (Test-Path -LiteralPath $d)){ New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

# ---------- 2. Cuarentena de duplicados (no borra, mueve) ----------
$ts = Get-Date -Format 'yyyyMMdd_HHmmss'
$q  = "$ROOT\scripts\_quarantine\$ts"
New-Item -ItemType Directory -Path $q -Force | Out-Null

$dup = @(
  "$ROOT\canon\Nexus-Forge.ps1",
  "$ROOT\canon\Nexus-Forge-PATCHED.ps1",
  "$env:USERPROFILE\Downloads\Nexus-Forge-PATCHED.ps1",
  "$env:USERPROFILE\Downloads\Nexus-Forge-v2-OPTIMIZADO.ps1"
)
foreach($f in $dup){
  if(Test-Path -LiteralPath $f){
    Move-Item -LiteralPath $f -Destination $q -Force
    Write-Host "  [QUAR] $f"
  }
}

# ---------- 3. Canonical Nexus-Forge ----------
$nf = "$ROOT\scripts\Nexus-Forge.ps1"
$canon = "$ROOT\scripts\_canonical\Nexus-Forge.ps1"
if((Test-Path $nf) -and -not (Test-Path $canon)){
  Copy-Item $nf $canon -Force
  Write-Host "  [CANON] $canon"
}

# ---------- 4. Template base (Tauri v2 mínima) ----------
$tpl = "$ROOT\apps\_template"

$cargoToml = @'
[package]
name = "__APPNAME__"
version = "0.1.0"
edition = "2021"

[build-dependencies]
tauri-build = { version = "2", features = [] }

[dependencies]
tauri   = { version = "2", features = [] }
serde   = { version = "1", features = ["derive"] }
serde_json = "1"
'@

$buildRs = @'
fn main() { tauri_build::build() }
'@

$mainRs = @'
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

fn main() {
    tauri::Builder::default()
        .run(tauri::generate_context!())
        .expect("error al arrancar");
}
'@

$tauriCfg = @'
{
  "$schema": "https://schema.tauri.app/config/2",
  "productName": "__APPNAME__",
  "version": "0.1.0",
  "identifier": "com.runeforge.__APPNAME__",
  "build": { "frontendDist": "../src" },
  "app": {
    "windows": [{ "title": "__APPNAME__", "width": 900, "height": 640 }],
    "security": { "csp": null }
  }
}
'@

$indexHtml = @'
<!doctype html>
<html lang="es">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width,initial-scale=1" />
  <title>__APPNAME__</title>
  <style>
    body{font-family:system-ui,sans-serif;background:#0b0d10;color:#e6e6e6;
         display:grid;place-items:center;height:100vh;margin:0}
    h1{margin:0 0 .3em 0;letter-spacing:.05em}
    p{opacity:.6;margin:0}
  </style>
</head>
<body>
  <main>
    <h1>__APPNAME__</h1>
    <p>RUNEFORGE Workshop</p>
  </main>
</body>
</html>
'@

$tplCargoCfg = @'
[build]
# target-dir se reescribe en `forge build` con la ruta absoluta por app.
'@

Set-Content -LiteralPath "$tpl\src-tauri\Cargo.toml"     -Value $cargoToml    -Encoding UTF8
Set-Content -LiteralPath "$tpl\src-tauri\build.rs"       -Value $buildRs      -Encoding UTF8
Set-Content -LiteralPath "$tpl\src-tauri\src\main.rs"    -Value $mainRs       -Encoding UTF8
Set-Content -LiteralPath "$tpl\src-tauri\tauri.conf.json"-Value $tauriCfg     -Encoding UTF8
Set-Content -LiteralPath "$tpl\src-tauri\.cargo\config.toml" -Value $tplCargoCfg -Encoding UTF8
Set-Content -LiteralPath "$tpl\src\index.html"           -Value $indexHtml    -Encoding UTF8
Set-Content -LiteralPath "$tpl\README.md" -Value "# __APPNAME__`n`nApp RUNEFORGE generada desde _template." -Encoding UTF8

# ---------- 5. forge.json (config global) ----------
$forgeCfg = [ordered]@{
  core              = $ROOT
  version           = '1.0.0'
  target_isolation  = $true
  sccache_enabled   = $false
  desktop           = [Environment]::GetFolderPath('Desktop')
  default_profile   = 'release'
  updated           = (Get-Date).ToString('o')
}
$forgeCfg | ConvertTo-Json -Depth 6 | Set-Content "$ROOT\forge.json" -Encoding UTF8

# ---------- 6. registry/apps.json (con las apps ya existentes) ----------
$apps = @()
Get-ChildItem "$ROOT\apps" -Directory -ErrorAction SilentlyContinue |
  Where-Object { $_.Name -ne '_template' } |
  ForEach-Object {
    $name = $_.Name
    $exeLegacy  = "$ROOT\target\release\$name.exe"
    $exeLocal   = "$($_.FullName)\src-tauri\target\release\$name.exe"
    $exeActual  = if(Test-Path $exeLocal){$exeLocal} elseif(Test-Path $exeLegacy){$exeLegacy} else {$null}
    $apps += [ordered]@{
      name           = $name
      path           = $_.FullName
      src_tauri      = "$($_.FullName)\src-tauri"
      target_dir     = "$($_.FullName)\src-tauri\target"
      exe            = $exeActual
      migrated       = Test-Path $exeLocal
      last_build     = if($exeActual){ (Get-Item $exeActual).LastWriteTime.ToString('o') } else { $null }
    }
  }

$registry = [ordered]@{
  version = '1.0.0'
  core    = $ROOT
  updated = (Get-Date).ToString('o')
  apps    = $apps
}
$registry | ConvertTo-Json -Depth 8 | Set-Content "$ROOT\registry\apps.json" -Encoding UTF8

Write-Host ""
Write-Host "[OK] Bootstrap completo." -ForegroundColor Green
Write-Host "     registry   -> $ROOT\registry\apps.json  ($($apps.Count) apps)"
Write-Host "     forge.json -> $ROOT\forge.json"
Write-Host "     template   -> $tpl"
Write-Host "     quarantine -> $q"