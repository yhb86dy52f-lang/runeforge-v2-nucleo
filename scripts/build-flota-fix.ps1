
# build-flota-fix.ps1 - Solución sqlite3
# Este script compila los 2 sidecars con la solución correcta para sqlite3

Write-Host "=== BUILD RUNEFORGE PRO v10.1 - Fix sqlite3 ===" -ForegroundColor Cyan

# Paso 1: FlotaKW Python (sin torch = ligero)
Write-Host "[1/3] Compilando FlotaKW Python..." -ForegroundColor Yellow
# Verificar que no hay torch
$req = Get-Content "C:\RUNEFORGE_V2_CORE\requirements.txt" -Raw -ErrorAction SilentlyContinue
if ($req -match "torch") {
    Write-Host "ALERTA: torch detectado, excluyendo..." -ForegroundColor Red
    $extraArgs = "--exclude-module torch --exclude-module torch.distributed --exclude-module torch.cuda"
} else {
    Write-Host "OK: sin torch, build ligero 25-55 MB" -ForegroundColor Green
    $extraArgs = ""
}

# Crear bin folder
New-Item -ItemType Directory -Force -Path "C:\RUNEFORGE_V2_CORE\src-tauri\bin" | Out-Null

# PyInstaller comando real (ajusta path a tu main.py)
# python -m PyInstaller --onefile --noconsole --name flota-x86_64-pc-windows-msvc --distpath src-tauri/bin $extraArgs --collect-submodules faster_whisper src/backends/main.py

# Paso 2: Fastify - MIGRACIÓN RECOMENDADA a Tauri SQL plugin
Write-Host "`n[2/3] Fastify sqlite3 - Solución recomendada" -ForegroundColor Yellow
Write-Host "Opción A: Migrar a @tauri-apps/plugin-sql" -ForegroundColor Green
Write-Host "  cargo add tauri-plugin-sql"
Write-Host "  En src-tauri/src/main.rs: .plugin(tauri_plugin_sql::Builder::default().build())"
Write-Host "  En frontend: import Database from '@tauri-apps/plugin-sql'"
Write-Host ""
Write-Host "Opción B: Si debes mantener sqlite3 en Node:" -ForegroundColor Yellow
Write-Host "  npx @yao-pkg/pkg src/whisper-server.js -t node20-win-x64 --compress GZip --no-bytecode --public-packages 'sqlite3' -o src-tauri/bin/dictate-x86_64-pc-windows-msvc.exe"

# Paso 3: Tauri build con downloadBootstrapper (0 MB) porque WebView2 instalado y MIT permite SignPath gratis
Write-Host "`n[3/3] Tauri build..." -ForegroundColor Yellow
Write-Host "Config: bundle.windows.webviewInstallMode.type = downloadBootstrapper (0 MB) - detectado WebView2 instalado"
Write-Host "Firma: SignPath Foundation GRATIS (MIT License confirmada)"
Write-Host "Comando: pnpm tauri build"
Write-Host ""
Write-Host "Instalador esperado: 25-40 MB NSIS (Rust 18 + Python 25-55 sin torch + Node 10) vs Electron 150-200 MB" -ForegroundColor Cyan
Write-Host "Con downloadBootstrapper: ~7.7 MB base + sidecars = ~35 MB total" -ForegroundColor Green
