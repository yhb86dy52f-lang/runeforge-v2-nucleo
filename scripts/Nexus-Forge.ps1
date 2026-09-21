# =====================================================================
# RUNEFORGE :: NEXUS-FORGE v1.0 - FABRICA CANONICA
# 12 Mandamientos - Un solo HTML -> .exe nativo ~3MB
# Ubicacion canonica: C:\RUNEFORGE_V2_CORE\scripts\Nexus-Forge.ps1
# Uso: powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Nexus-Forge.ps1 -Name "mi-app" -Html "C:\ruta\index.html"
# =====================================================================
param(
    [Parameter(Mandatory=$true)][string]$Name,
    [Parameter(Mandatory=$true)][string]$Html,
    [string]$Title = "",
    [int]$Width = 1440,
    [int]$Height = 900,
    [string]$Identifier = "",
    [switch]$Bundle,
    [switch]$Run
)

$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# --- MANDAMIENTO VI: Rutas absolutas siempre ---
$ROOT = "C:\RUNEFORGE_V2_CORE"
$APP_ROOT = Join-Path $ROOT "apps\$Name"
$DIST_DIR = Join-Path $APP_ROOT "dist"
$SRC_TAURI = Join-Path $APP_ROOT "src-tauri"
$TARGET_EXE = Join-Path $SRC_TAURI "target\release\$Name.exe"

if (-not $Title) { $Title = $Name }
if (-not $Identifier) { $Identifier = "com.runeforge.$Name" }

# Validar HTML fuente
if (-not (Test-Path $Html)) { Write-Host "[X] HTML no existe: $Html" -ForegroundColor Red; exit 1 }
$Html = (Resolve-Path $Html).Path
$HtmlSizeKB = [math]::Round((Get-Item $Html).Length/1KB,1)
Write-Host "`n[RUNEFORGE FORGE v1.0] $Name <- $Html ($HtmlSizeKB KB)" -ForegroundColor Cyan
Write-Host "[CANON] 12 mandamientos - Sin Node, solo cargo build --release" -ForegroundColor DarkGray

# --- MANDAMIENTO VII: Limpieza de procesos antes de reescribir ---
$procName = $Name
Write-Host "[*] Limpiando procesos $procName..." -ForegroundColor Yellow
Get-Process -Name $procName -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 400
if (Test-Path $TARGET_EXE) {
    & cmd /c "attrib -R -H -S ""$TARGET_EXE"" >nul 2>&1"
    Remove-Item $TARGET_EXE -Force -ErrorAction SilentlyContinue
}

# Crear estructura canonica
New-Item -ItemType Directory -Path $DIST_DIR, "$SRC_TAURI\src", "$SRC_TAURI\capabilities", "$SRC_TAURI\icons" -Force | Out-Null

# --- MANDAMIENTO I: Un solo HTML autocontenido ---
Write-Host "[*] Copiando HTML autocontenido -> dist\index.html" -ForegroundColor Yellow
Copy-Item $Html (Join-Path $DIST_DIR "index.html") -Force
# Unblock si viene de otro equipo
Unblock-File (Join-Path $DIST_DIR "index.html") -ErrorAction SilentlyContinue

# --- MANDAMIENTO IV: Cargo config global permanente ---
$cargoCfgDir = "$env:USERPROFILE\.cargo"
New-Item -ItemType Directory -Path $cargoCfgDir -Force | Out-Null
@'
[http]
multiplexing = false
timeout = 300
low-speed-limit = 1

[net]
retry = 10
git-fetch-with-cli = true

[registries.crates-io]
protocol = "sparse"
'@ | Set-Content "$cargoCfgDir\config.toml" -Encoding UTF8
Write-Host "[OK] $cargoCfgDir\config.toml canonico (HTTP/1.1 + retry 10 + sparse)" -ForegroundColor Green

$env:CARGO_HTTP_MULTIPLEXING = "false"
$env:CARGO_NET_RETRY = "10"
$env:CARGO_HTTP_TIMEOUT = "300"
$env:CARGO_REGISTRIES_CRATES_IO_PROTOCOL = "sparse"
$env:Path = "$env:USERPROFILE\.cargo\bin;$env:Path"

# --- Cargo.toml con perfil release optimizado (Mandamiento X) ---
@"
[package]
name = "$Name"
version = "1.0.0"
description = "$Title - RUNEFORGE Canon v1.0"
edition = "2021"

[lib]
name = "${Name}_lib"
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
"@ | Set-Content "$SRC_TAURI\Cargo.toml" -Encoding UTF8

"fn main() { tauri_build::build() }" | Set-Content "$SRC_TAURI\build.rs" -Encoding UTF8

@"
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]
fn main() { ${Name}_lib::run() }
"@ | Set-Content "$SRC_TAURI\src\main.rs" -Encoding UTF8

@"
#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
"@ | Set-Content "$SRC_TAURI\src\lib.rs" -Encoding UTF8

# tauri.conf.json
@"
{
  "`$schema": "https://schema.tauri.app/config/2",
  "productName": "$Title",
  "version": "1.0.0",
  "identifier": "$Identifier",
  "build": {
    "frontendDist": "../dist",
    "beforeBuildCommand": "",
    "beforeDevCommand": ""
  },
  "app": {
    "windows": [{ "title": "$Title", "width": $Width, "height": $Height, "resizable": true }],
    "security": { "csp": null }
  },
  "bundle": {
    "active": $(if ($Bundle) { "true" } else { "false" }),
    "targets": "all",
    "icon": ["icons/32x32.png","icons/128x128.png","icons/128x128@2x.png","icons/icon.png","icons/icon.ico"]
  }
}
"@ | Set-Content "$SRC_TAURI\tauri.conf.json" -Encoding UTF8

@"
{
  "`$schema": "../gen/schemas/desktop-schema.json",
  "identifier": "default",
  "description": "Default capability",
  "windows": ["main"],
  "permissions": ["core:default"]
}
"@ | Set-Content "$SRC_TAURI\capabilities\default.json" -Encoding UTF8

# --- MANDAMIENTO VIII: Iconos generados in-situ con System.Drawing ---
Write-Host "[*] Generando iconos cyan #00F5FF -> magenta #FF00FF 45° + nucleo #080A12" -ForegroundColor Yellow
Add-Type -AssemblyName System.Drawing
$sizes = @{ "32x32.png"=32; "128x128.png"=128; "128x128@2x.png"=256; "icon.png"=512 }
foreach ($kv in $sizes.GetEnumerator()) {
    $size = $kv.Value
    $bmp = New-Object System.Drawing.Bitmap $size, $size
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    # Gradiente 45° cyan -> magenta
    $rect = New-Object System.Drawing.Rectangle 0,0,$size,$size
    $brushGrad = New-Object System.Drawing.Drawing2D.LinearGradientBrush $rect, ([System.Drawing.Color]::FromArgb(0,245,255)), ([System.Drawing.Color]::FromArgb(255,0,255)), 45
    $g.FillRectangle($brushGrad, $rect)
    # Nucleo oscuro #080A12
    $coreSize = [int]($size * 0.55)
    $corePos = [int](($size - $coreSize)/2)
    $brushCore = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(8,10,18))
    $g.FillEllipse($brushCore, $corePos, $corePos, $coreSize, $coreSize)
    # Dot cyan central
    $dotSize = [int]($size * 0.18)
    $dotPos = [int](($size - $dotSize)/2)
    $brushDot = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(0,245,255))
    $g.FillEllipse($brushDot, $dotPos, $dotPos, $dotSize, $dotSize)
    $bmp.Save((Join-Path $SRC_TAURI "icons\$($kv.Key)"), [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose(); $g.Dispose(); $brushGrad.Dispose(); $brushCore.Dispose(); $brushDot.Dispose()
}
Write-Host "[OK] Iconos PNG generados" -ForegroundColor Green

# --- MANDAMIENTO IX: icon.ico escrito a mano ICONDIR + PNG ---
Write-Host "[*] Generando icon.ico (ICONDIR + PNG embebido)" -ForegroundColor Yellow
$pngPath = Join-Path $SRC_TAURI "icons\icon.png"
$icoPath = Join-Path $SRC_TAURI "icons\icon.ico"
$pngBytes = [IO.File]::ReadAllBytes($pngPath)
$fs = [IO.File]::Create($icoPath)
$bw = New-Object IO.BinaryWriter $fs
$bw.Write([UInt16]0) # reserved
$bw.Write([UInt16]1) # type 1 = ico
$bw.Write([UInt16]1) # count
$bw.Write([Byte]0) # width 0 = 256
$bw.Write([Byte]0) # height 0 = 256
$bw.Write([Byte]0) # color count
$bw.Write([Byte]0) # reserved
$bw.Write([UInt16]1) # planes
$bw.Write([UInt16]32) # bpp
$bw.Write([UInt32]$pngBytes.Length) # size
$bw.Write([UInt32]22) # offset
$bw.Write($pngBytes)
$bw.Close(); $fs.Close()
Write-Host "[OK] icon.ico generado" -ForegroundColor Green

# --- MANDAMIENTO III: Solo cargo build --release + V: fallback espejo ---
Write-Host "`n[RUNEFORGE] Compilando $Name con cargo build --release" -ForegroundColor Cyan
Set-Location $SRC_TAURI
$ok = $false
for ($i=1; $i -le 2; $i++) {
    if ($i -eq 1) {
        Write-Host "[Intento 1] CDN oficial crates.io HTTP/1.1" -ForegroundColor Yellow
    } else {
        Write-Host "[Intento 2] Espejo USTC" -ForegroundColor Yellow
        @'
[http]
multiplexing = false
timeout = 300
[net]
retry = 10
git-fetch-with-cli = true
[source.crates-io]
replace-with = "ustc"
[source.ustc]
registry = "sparse+https://mirrors.ustc.edu.cn/crates.io-index/"
'@ | Set-Content "$cargoCfgDir\config.toml" -Encoding UTF8
    }
    & cmd /c "cargo build --release > build.log 2>&1"
    $logTail = Get-Content "build.log" -Tail 5 -ErrorAction SilentlyContinue
    $logTail | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
    if ($LASTEXITCODE -eq 0 -and (Test-Path $TARGET_EXE)) {
        $ok = $true
        break
    }
    Write-Host "[!] Fallo intento $i, reintentando..." -ForegroundColor DarkYellow
    Start-Sleep -Seconds 3
}

if (-not $ok) {
    Write-Host "[X] Build fallo tras 2 intentos. Ver $SRC_TAURI\build.log" -ForegroundColor Red
    Get-Content "$SRC_TAURI\build.log" -Tail 30
    exit 1
}

# Restaurar config sin espejo
@'
[http]
multiplexing = false
timeout = 300
low-speed-limit = 1
[net]
retry = 10
git-fetch-with-cli = true
[registries.crates-io]
protocol = "sparse"
'@ | Set-Content "$cargoCfgDir\config.toml" -Encoding UTF8

$sizeMB = [math]::Round((Get-Item $TARGET_EXE).Length/1MB,2)
Write-Host "`n[OK] $TARGET_EXE ($sizeMB MB)" -ForegroundColor Green
Write-Host "[CANON] 12 mandamientos cumplidos - Binario offline-first" -ForegroundColor DarkGray

if ($Bundle) {
    Write-Host "[*] Bundle MSI/NSIS..." -ForegroundColor Yellow
    & cmd /c "cargo build --release --features custom-protocol > bundle.log 2>&1"
}

if (-not $Bundle -or $Run) {
    Write-Host "[RUNEFORGE] Lanzando $Name..." -ForegroundColor Green
    Start-Process $TARGET_EXE
}

Write-Host "`n[RUNEFORGE] Forja completada: $Name -> $TARGET_EXE" -ForegroundColor Cyan
