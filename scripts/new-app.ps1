param([Parameter(Mandatory=$true)][string]$Name)
$ErrorActionPreference = "Stop"
Set-Location "C:\RUNEFORGE_V2_CORE"
if (Test-Path "apps\$Name") { Write-Host "Ya existe apps\$Name" -ForegroundColor Red; exit 1 }
Write-Host "Clonando _template -> $Name..." -ForegroundColor Cyan
Copy-Item -Recurse "apps\_template" "apps\$Name"
(Get-Content "apps\$Name\src-tauri\Cargo.toml" -Raw) -replace '__APPNAME__', $Name | Set-Content "apps\$Name\src-tauri\Cargo.toml" -Encoding UTF8
(Get-Content "apps\$Name\src-tauri\tauri.conf.json" -Raw) -replace '__APPNAME__', $Name | Set-Content "apps\$Name\src-tauri\tauri.conf.json" -Encoding UTF8
if (Test-Path "apps\$Name\src\index.html") { (Get-Content "apps\$Name\src\index.html" -Raw) -replace '__APPNAME__', $Name | Set-Content "apps\$Name\src\index.html" -Encoding UTF8 }
if (-not (Test-Path "apps\$Name\src-tauri\icons")) { Copy-Item -Recurse "apps\dictate-studio-v2\src-tauri\icons" "apps\$Name\src-tauri\icons" }
Write-Host "Compilando $Name (primera vez 2m, segunda 7s)..." -ForegroundColor Yellow
cargo check -p $Name
Write-Host "Listo: apps\$Name - cargo check -p $Name = 7s" -ForegroundColor Green
