# NEXUS-FORGE v2.0 - OPTIMIZADO RAPIDO
param(
    [Parameter(Mandatory=$true)][string]$Name,
    [Parameter(Mandatory=$true)][string]$Html,
    [string]$Title = $Name,
    [int]$Width = 1440,
    [int]$Height = 900,
    [switch]$Run,
    [switch]$FastHtmlOnly
)

$ErrorActionPreference="Stop"
$ROOT = "C:\RUNEFORGE_V2_CORE"
$NameSnake = $Name -replace "-", "_"
$NameSnakeLib = "${NameSnake}_lib"
$sharedTarget = "C:\RUNEFORGE_V2_CORE\target"

# --- ENV OPTIMIZADO ---
$env:CARGO_TARGET_DIR = $sharedTarget
# CARGO_BUILD_JOBS eliminado (dejar auto-detect por cargo)
$env:CARGO_HTTP_MULTIPLEXING = "false"
$env:CARGO_NET_RETRY = "5"
$env:CARGO_REGISTRIES_CRATES_IO_PROTOCOL = "sparse"
$env:RUSTC_WRAPPER = "$env:USERPROFILE\.cargo\bin\sccache.exe"
if (-not (Test-Path $env:RUSTC_WRAPPER)) { Remove-Item Env:RUSTC_WRAPPER -ErrorAction SilentlyContinue }

Write-Host "`n[FORGE v2.0 RAPIDO] $Name <- $Html" -ForegroundColor Cyan

if (-not (Test-Path $Html)) { Write-Host "[X] HTML no existe: $Html" -ForegroundColor Red; return }

$appDir = "$ROOT\apps\$Name"
$srcTauri = "$appDir\src-tauri"
$distDir = "$appDir\dist"

# FAST PATH: Si solo cambio HTML y exe ya existe, no recompila Rust
if ($FastHtmlOnly -and (Test-Path "$srcTauri\target\release\$Name.exe")) {
    Write-Host "[FAST] HTML-only -> copiando dist\index.html sin cargo build" -ForegroundColor Green
    Copy-Item $Html "$distDir\index.html" -Force
    if ($Run) { Start-Process "$srcTauri\target\release\$Name.exe" }
    return
}

# Si exe existe y solo cambio HTML (detecta automaticamente)
$existingExe = Get-ChildItem "$ROOT\target\release\$Name.exe","$srcTauri\target\release\$Name.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($existingExe -and (Test-Path $distDir)) {
    $htmlTime = (Get-Item $Html).LastWriteTime
    $exeTime = $existingExe.LastWriteTime
    if ($htmlTime -gt $exeTime.AddMinutes(-5)) {
        Write-Host "[FAST DETECT] HTML modificado recientemente, usando fast path..." -ForegroundColor Yellow
        Copy-Item $Html "$distDir\index.html" -Force
        Write-Host "[OK] HTML actualizado en 2s, exe reutilizado: $($existingExe.FullName)" -ForegroundColor Green
        if ($Run) { Start-Process $existingExe.FullName }
        return
    }
}

# --- FORJA COMPLETA (cold o Rust cambiado) ---
New-Item -ItemType Directory -Path $appDir,$srcTauri,$distDir -Force | Out-Null
Copy-Item $Html "$distDir\index.html" -Force
Write-Host "[OK] HTML -> dist\index.html" -ForegroundColor Green

# Cargo.toml optimizado
@"
[package]
name = "$Name"
version = "1.0.0"
edition = "2021"

[lib]
name = "$NameSnakeLib"
crate-type = ["staticlib", "cdylib", "rlib"]

[build-dependencies]
tauri-build = { version = "2", features = [] }

[dependencies]
tauri = { version = "2", features = ["devtools"] }`ntauri-plugin-http = "2"
serde = { version = "1", features = ["derive"] }
serde_json = "1"

[profile.release]
opt-level = 1
lto = false
codegen-units = 16
incremental = true
strip = true
"@ | Set-Content "$srcTauri\Cargo.toml" -Encoding UTF8
Add-Content "$srcTauri\Cargo.toml" -Value "`n`n[profile.release.package.$Name]`nopt-level = 0`n" -Encoding UTF8

# main.rs y lib.rs (igual que v1.0.1)
@"
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]
fn main() { ${NameSnakeLib}::run() }
"@ | Set-Content "$srcTauri\src\main.rs" -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path "$srcTauri\src" -Force | Out-Null
@"
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]
fn main() { ${NameSnakeLib}::run() }
"@ | Set-Content "$srcTauri\src\main.rs" -Encoding UTF8

@"
use tauri::Manager;

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()`n        .plugin(tauri_plugin_http::init())
        .setup(|app| {
            let window = app.get_webview_window("main").unwrap();
            window.set_title("$Title").unwrap();
            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
"@ | Set-Content "$srcTauri\src\lib.rs" -Encoding UTF8
"fn main() { tauri_build::build() }" | Set-Content "$srcTauri\build.rs" -Encoding UTF8

# tauri.conf.json
@"
{
  "build": { "beforeBuildCommand": "", "beforeDevCommand": "", "frontendDist": "../dist" },
  "identifier": "com.runeforge.$NameSnake",
  "productName": "$Title",
  "version": "1.0.0",
  "app": {`n    "withGlobalTauri": true, "windows": [{ "title": "$Title", "width": $Width, "height": $Height }] }
,
  "plugins": {
    "http": {
      "scopeRedirects": true
    }
  }
}
"@ | Set-Content "$srcTauri\tauri.conf.json" -Encoding UTF8

# --- ICONOS (auto) ---
$_iconDir = "$srcTauri\icons"
New-Item -ItemType Directory -Path $_iconDir -Force | Out-Null
Add-Type -AssemblyName System.Drawing
$_iconSizes = @{ "32x32.png"=32; "128x128.png"=128; "128x128@2x.png"=256; "icon.png"=512 }
foreach ($_iconKv in $_iconSizes.GetEnumerator()) {
    $_iconS = $_iconKv.Value
    $_iconBmp = New-Object System.Drawing.Bitmap $_iconS, $_iconS
    $_iconG = [System.Drawing.Graphics]::FromImage($_iconBmp)
    $_iconG.SmoothingMode = 'AntiAlias'
    $_iconRect = New-Object System.Drawing.Rectangle 0, 0, $_iconS, $_iconS
    $_iconBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($_iconRect, [System.Drawing.Color]::FromArgb(0,245,255), [System.Drawing.Color]::FromArgb(255,0,255), 45.0)
    $_iconG.FillRectangle($_iconBrush, $_iconRect)
    $_iconDark = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(8,10,18))
    $_iconM = [int]($_iconS * 0.2)
    $_iconG.FillEllipse($_iconDark, $_iconM, $_iconM, $_iconS - 2*$_iconM, $_iconS - 2*$_iconM)
    $_iconCyan = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(0,245,255))
    $_iconI = [int]($_iconS * 0.4)
    $_iconG.FillEllipse($_iconCyan, $_iconI, $_iconI, $_iconS - 2*$_iconI, $_iconS - 2*$_iconI)
    $_iconBmp.Save("$_iconDir\$($_iconKv.Key)", [System.Drawing.Imaging.ImageFormat]::Png)
    $_iconBmp.Dispose(); $_iconG.Dispose(); $_iconBrush.Dispose(); $_iconDark.Dispose(); $_iconCyan.Dispose()
}
$_iconPng = [IO.File]::ReadAllBytes("$_iconDir\32x32.png")
$_iconMs = New-Object IO.MemoryStream
$_iconBw = New-Object IO.BinaryWriter($_iconMs)
$_iconBw.Write([UInt16]0); $_iconBw.Write([UInt16]1); $_iconBw.Write([UInt16]1)
$_iconBw.Write([Byte]32); $_iconBw.Write([Byte]32); $_iconBw.Write([Byte]0); $_iconBw.Write([Byte]0)
$_iconBw.Write([UInt16]1); $_iconBw.Write([UInt16]32)
$_iconBw.Write([UInt32]$_iconPng.Length); $_iconBw.Write([UInt32]22)
$_iconBw.Write($_iconPng); $_iconBw.Flush()
[IO.File]::WriteAllBytes("$_iconDir\icon.ico", $_iconMs.ToArray())
$_iconBw.Dispose(); $_iconMs.Dispose()
Write-Host "[OK] Iconos generados" -ForegroundColor Green
Write-Host "[*] cargo build --release --offline (target compartido $sharedTarget)..." -ForegroundColor Yellow
Set-Location $srcTauri
$start = Get-Date
try {
    # Intenta offline primero (usa cache)
    & cargo build --release --offline 2>&1 | Tee-Object build.log
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[*] Offline fallo, intentando online..." -ForegroundColor Yellow
        & cargo build --release 2>&1 | Tee-Object build.log -Append
    }
} catch {
    & cargo build --release 2>&1 | Tee-Object build.log
}
$elapsed = (Get-Date) - $start

if ($LASTEXITCODE -eq 0) {
    $exe = Get-ChildItem "$sharedTarget\release\$Name.exe","$srcTauri\target\release\$Name.exe" -ErrorAction SilentlyContinue | Select -First 1
    if (-not $exe) { $exe = Get-ChildItem "$sharedTarget\release\$Name.exe" -ErrorAction SilentlyContinue }
    Write-Host "[OK] $($exe.Name) $([math]::Round($exe.Length/1MB,2)) MB en $([math]::Round($elapsed.TotalMinutes,1)) min" -ForegroundColor Green
    if ($Run) { Start-Process $exe.FullName }
} else {
    Write-Host "[X] Build fallo, ver build.log" -ForegroundColor Red
}
