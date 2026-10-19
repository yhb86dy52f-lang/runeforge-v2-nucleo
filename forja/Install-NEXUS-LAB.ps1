# =====================================================================
# RUNEFORGE :: NEXUS LAB :: BOOTSTRAP v9  (ZERO-NPM)
# Envuelve laboratorio.html como app de escritorio Tauri nativa
# Sin npm, sin node_modules, sin Vite, sin Tailwind install.
# Solo cargo. Inmune al bug ERR_SSL_CIPHER_OPERATION_FAILED.
# Ejecutar desde: C:\RUNEFORGE_V2_CORE\forja
#   powershell -ExecutionPolicy Bypass -File .\Install-NEXUS-LAB.ps1
# =====================================================================

$ErrorActionPreference = "Stop"
$ProgressPreference    = "SilentlyContinue"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# --- Localizar laboratorio.html (acepta varias rutas) ---
$candidates = @(
    "C:\RUNEFORGE_V2_CORE\forja\laboratorio.html",
    "C:\RUNEFORGE_V2_CORE\apps\forja-lab\laboratorio.html",
    (Join-Path $PWD "laboratorio.html"),
    (Join-Path $PWD "NEXUS_LAB.html")
)
$LAB_SRC = $null
foreach ($c in $candidates) { if (Test-Path $c) { $LAB_SRC = $c; break } }
if (-not $LAB_SRC) { Write-Host "[X] No se encontró laboratorio.html en rutas conocidas." -ForegroundColor Red; exit 1 }
Write-Host "[OK] Fuente: $LAB_SRC" -ForegroundColor Green

$APP_ROOT  = "C:\RUNEFORGE_V2_CORE\apps\nexus-lab"
$TAURI_DIR = "$APP_ROOT\src-tauri"

# --- Rust / Cargo ---
$rustBin = "$env:USERPROFILE\.cargo\bin"
if ($env:Path -notlike "*$rustBin*") { $env:Path = "$rustBin;$env:Path" }
if (-not (Get-Command cargo -ErrorAction SilentlyContinue)) {
    Write-Host "[X] cargo no disponible. Instala Rust: https://rustup.rs" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] $(rustc --version) | $(cargo --version)" -ForegroundColor Green

Write-Host "`n[RUNEFORGE] NEXUS LAB Desktop (zero-npm)`n" -ForegroundColor Cyan

# --- Limpieza ---
if (Test-Path $APP_ROOT) {
    Get-Process -Name "nexus-lab" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 500
    Remove-Item $APP_ROOT -Recurse -Force -ErrorAction SilentlyContinue
}

# --- Estructura ---
New-Item -ItemType Directory -Path "$APP_ROOT\dist"                  -Force | Out-Null
New-Item -ItemType Directory -Path "$TAURI_DIR\src"                  -Force | Out-Null
New-Item -ItemType Directory -Path "$TAURI_DIR\capabilities"         -Force | Out-Null
New-Item -ItemType Directory -Path "$TAURI_DIR\icons"                -Force | Out-Null

Set-Location $APP_ROOT

# --- HTML (copiar tal cual) ---
Copy-Item $LAB_SRC "$APP_ROOT\dist\index.html" -Force
$htmlSize = (Get-Item "$APP_ROOT\dist\index.html").Length
Write-Host "[OK] dist/index.html ($([math]::Round($htmlSize/1KB,1)) KB)" -ForegroundColor Green

# --- Cargo.toml ---
@'
[package]
name = "nexus-lab"
version = "1.0.0"
description = "NEXUS LAB - ESP32 Circuit Designer"
edition = "2021"
rust-version = "1.77"

[lib]
name = "nexus_lab_lib"
crate-type = ["staticlib", "cdylib", "rlib"]

[build-dependencies]
tauri-build = { version = "2", features = [] }

[dependencies]
tauri = { version = "2", features = [] }
serde = { version = "1", features = ["derive"] }
serde_json = "1"

[profile.release]
opt-level = "s"
lto = true
strip = true
codegen-units = 1
panic = "abort"
'@ | Set-Content "$TAURI_DIR\Cargo.toml" -Encoding UTF8

@'
fn main() { tauri_build::build() }
'@ | Set-Content "$TAURI_DIR\build.rs" -Encoding UTF8

@'
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]
fn main() { nexus_lab_lib::run() }
'@ | Set-Content "$TAURI_DIR\src\main.rs" -Encoding UTF8

@'
#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .setup(|_app| Ok(()))
        .run(tauri::generate_context!())
        .expect("error while running NEXUS LAB");
}
'@ | Set-Content "$TAURI_DIR\src\lib.rs" -Encoding UTF8

# --- tauri.conf.json (sin devUrl, sin beforeDev/BeforeBuild) ---
@'
{
  "$schema": "https://schema.tauri.app/config/2",
  "productName": "NEXUS LAB",
  "version": "1.0.0",
  "identifier": "com.runeforge.nexus-lab",
  "build": {
    "frontendDist": "../dist"
  },
  "app": {
    "withGlobalTauri": true,
    "windows": [
      {
        "label": "main",
        "title": "NEXUS LAB - ESP32 Circuit Designer",
        "width": 1440,
        "height": 900,
        "minWidth": 900,
        "minHeight": 600,
        "resizable": true,
        "fullscreen": false,
        "decorations": true,
        "transparent": false,
        "theme": "Dark",
        "center": true
      }
    ],
    "security": { "csp": null }
  },
  "bundle": {
    "active": true,
    "targets": ["msi", "nsis"],
    "publisher": "RUNEFORGE",
    "shortDescription": "ESP32 Circuit Designer - Offline",
    "longDescription": "NEXUS LAB: disena circuitos ESP32, simula en vivo y genera sketches .ino sin conexion.",
    "icon": [
      "icons/32x32.png",
      "icons/128x128.png",
      "icons/128x128@2x.png",
      "icons/icon.ico"
    ]
  }
}
'@ | Set-Content "$TAURI_DIR\tauri.conf.json" -Encoding UTF8

@'
{
  "$schema": "../gen/schemas/desktop-schema.json",
  "identifier": "default",
  "description": "Default capability for NEXUS LAB",
  "windows": ["main"],
  "permissions": ["core:default"]
}
'@ | Set-Content "$TAURI_DIR\capabilities\default.json" -Encoding UTF8

# --- Iconos (gradiente cyan→magenta con nucleo oscuro y dot cyan) ---
Add-Type -AssemblyName System.Drawing

$iconSizes = [ordered]@{
    "32x32.png"     = 32
    "128x128.png"   = 128
    "128x128@2x.png"= 256
    "icon.png"      = 512
}

foreach ($kv in $iconSizes.GetEnumerator()) {
    $size = $kv.Value
    $bmp  = New-Object System.Drawing.Bitmap $size, $size
    $g    = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode     = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

    $rect  = New-Object System.Drawing.Rectangle 0, 0, $size, $size
    $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        $rect,
        [System.Drawing.Color]::FromArgb(0, 245, 255),
        [System.Drawing.Color]::FromArgb(255, 0, 255),
        45.0
    )
    $g.FillRectangle($brush, $rect)

    $darkBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(8, 10, 18))
    $m = [int]($size * 0.20)
    $g.FillEllipse($darkBrush, $m, $m, $size - 2*$m, $size - 2*$m)

    $cyanBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(0, 245, 255))
    $i = [int]($size * 0.40)
    $g.FillEllipse($cyanBrush, $i, $i, $size - 2*$i, $size - 2*$i)

    $bmp.Save("$TAURI_DIR\icons\$($kv.Key)", [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose(); $g.Dispose(); $brush.Dispose(); $darkBrush.Dispose(); $cyanBrush.Dispose()
}

# --- ICO (formato ICONDIR + PNG embebido de 32x32) ---
$pngBytes = [IO.File]::ReadAllBytes("$TAURI_DIR\icons\32x32.png")
$ms = New-Object IO.MemoryStream
$bw = New-Object IO.BinaryWriter($ms)
$bw.Write([UInt16]0)                    # reserved
$bw.Write([UInt16]1)                    # type = ICO
$bw.Write([UInt16]1)                    # count
$bw.Write([Byte]32)                     # width
$bw.Write([Byte]32)                     # height
$bw.Write([Byte]0)                      # palette
$bw.Write([Byte]0)                      # reserved
$bw.Write([UInt16]1)                    # planes
$bw.Write([UInt16]32)                   # bitcount
$bw.Write([UInt32]$pngBytes.Length)     # size
$bw.Write([UInt32]22)                   # offset (6 + 16)
$bw.Write($pngBytes)
$bw.Flush()
[IO.File]::WriteAllBytes("$TAURI_DIR\icons\icon.ico", $ms.ToArray())
$bw.Dispose(); $ms.Dispose()

Write-Host "[OK] Iconos: 32, 128, 256, 512 PNG + icon.ico" -ForegroundColor Green

# --- Compilar ---
Write-Host ""
Write-Host "[RUNEFORGE] Compilando NEXUS LAB (primera vez: 3-8 min)..." -ForegroundColor Cyan
Write-Host ""

Set-Location $TAURI_DIR
cargo build --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "[X] Falló la compilación de cargo." -ForegroundColor Red
    exit 1
}

$exe = "$TAURI_DIR\target\release\nexus-lab.exe"
if (-not (Test-Path $exe)) {
    Write-Host "[X] No se generó nexus-lab.exe." -ForegroundColor Red
    exit 1
}
$exeSize = [math]::Round((Get-Item $exe).Length / 1MB, 2)

Write-Host ""
Write-Host "[OK] Ejecutable: $exe ($exeSize MB)" -ForegroundColor Green
Write-Host "[RUNEFORGE] Lanzando NEXUS LAB..." -ForegroundColor Green
Write-Host ""

Start-Process $exe