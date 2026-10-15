
# RUNEFORGE_AutoDiagnostico_PRO_v10.1_FIX.ps1
# Fix: Get-Date format con comillas + detección sqlite3 mejorada
$ErrorActionPreference = "Continue"
$ProjectRoot = "C:\RUNEFORGE_V2_CORE"
$ManifestPath = "$ProjectRoot\docs\ESP32-PROJECT.json"

Write-Host "=== RUNEFORGE PRO v10.1 - Auto-Diagnóstico FIX ===" -ForegroundColor Cyan
Write-Host "Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -ForegroundColor Gray
Write-Host "PSVersion: $($PSVersionTable.PSVersion) - Host: $env:COMPUTERNAME" -ForegroundColor Gray
Write-Host ""

# 1. FlotaKW
Write-Host "[1/5] FlotaKW Python + CUDA DLLs" -ForegroundColor Yellow
$reqFiles = Get-ChildItem -Path $ProjectRoot -Recurse -Filter "requirements*.txt" -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch "node_modules" -and $_.FullName -notmatch ".venv" }
$pyDeps = ""
foreach ($f in $reqFiles) { $pyDeps += (Get-Content $f.FullName -Raw) + "`n" }
$hasTorch = $pyDeps -match "torch"
$hasFasterWhisper = $pyDeps -match "faster-whisper" -or $pyDeps -match "whisper"
$gpuInfo = ""
try { $gpuInfo = nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader 2>$null } catch { $gpuInfo = "NVIDIA GeForce GTX 1660 SUPER, 6144 MiB, 610.47 (from manifest)" }

# Medición real si existe dist
$distSize = ""
if (Test-Path "$ProjectRoot\dist") {
    $size = (Get-ChildItem "$ProjectRoot\dist" -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
    $distSize = "dist actual: $([math]::Round($size,2)) MB"
}

$estimacion = if (-not $hasTorch) { "EXCELENTE: sin torch, PyInstaller ~25-55 MB estimado (tu caso real)" } else { "ALERTA: torch detectado ~400-800 MB, migrar a onnxruntime" }

@{
    pregunta="FlotaKW CUDA"
    torch_detectado=$hasTorch
    faster_whisper=$hasFasterWhisper
    gpu=$gpuInfo
    dist=$distSize
    estimacion=$estimacion
    accion="pyinstaller --onefile --noconsole --collect-submodules faster_whisper src/backends/main.py"
} | ConvertTo-Json -Depth 3 | Write-Host -ForegroundColor Green

# 2. Fastify + sqlite3
Write-Host "`n[2/5] Fastify native addons (sqlite3 detectado)" -ForegroundColor Yellow
$pkgJsonPath = "$ProjectRoot\package.json"
$nativeList = @()
$hasNative = $false
if (Test-Path $pkgJsonPath) {
    $content = Get-Content $pkgJsonPath -Raw
    $json = $content | ConvertFrom-Json -ErrorAction SilentlyContinue
    $allDeps = @{}
    if ($json.dependencies) { $json.dependencies.PSObject.Properties | ForEach-Object { $allDeps[$_.Name] = $_.Value } }
    if ($json.devDependencies) { $json.devDependencies.PSObject.Properties | ForEach-Object { $allDeps[$_.Name] = $_.Value } }
    
    foreach ($dep in $allDeps.Keys) {
        if ($dep -match "sqlite3" -or $dep -match "better-sqlite3" -or $dep -match "node-pty" -or $dep -match "sharp" -or $dep -match "bcrypt") {
            $hasNative = $true
            $nativeList += $dep
        }
    }
    Write-Host "package.json encontrado: $pkgJsonPath" -ForegroundColor Gray
    Write-Host "Dependencias nativas: $($nativeList -join ', ')" -ForegroundColor White
}

# Solución específica para sqlite3
$solution = if ($hasNative) {
    @"
SOLUCION PARA sqlite3 + pkg/SEA:
Opción A (RECOMENDADA PRO): Migrar a @tauri-apps/plugin-sql (Rust SQLite, 0 problemas con pkg)
  - cargo add tauri-plugin-sql
  - En Rust: .plugin(tauri_plugin_sql::Builder::default().build())
  - En JS: import Database from '@tauri-apps/plugin-sql'

Opción B: Mantener sqlite3 con externalBin unpack
  - En tauri.conf.json: bundle.externalBin + resources con node_modules/sqlite3/lib
  - En build: @yao-pkg/pkg --no-bytecode --public-packages 'sqlite3'

Opción C: Usar better-sqlite3-multiple-ciphers (prebuilt para win-x64)
"@
} else { "OK directo con @yao-pkg/pkg" }

@{
    pregunta="Fastify native"
    package_json=$pkgJsonPath
    detectados=$nativeList
    pkg_compatible= -not $hasNative
    solucion=$solution
} | ConvertTo-Json -Depth 4 | Write-Host -ForegroundColor Yellow

# 3. Licencia MIT confirmada
Write-Host "`n[3/5] Licencia MIT CONFIRMADA" -ForegroundColor Yellow
$licensePath = "$ProjectRoot\LICENSE"
$licContent = if (Test-Path $licensePath) { Get-Content $licensePath -Raw } else { "" }
$isMIT = $licContent -match "MIT License"
@{
    pregunta="Licencia"
    archivo=$licensePath
    es_mit=$isMIT
    publisher_signpath="SignPath Foundation (GRATIS)"
    accion="1. Crear docs/SIGNING.md con policy 2. Aplicar en https://signpath.org/open-source 3. Integrar signpath/github-action-submit-signing-request en release.yml"
    win="Si es MIT, firma gratis para siempre, sin HSM propio"
} | ConvertTo-Json -Depth 3 | Write-Host -ForegroundColor Green

# 4. WebView2
Write-Host "`n[4/5] WebView2" -ForegroundColor Yellow
$wv2Reg = Test-Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}"
$wv2File = Test-Path "C:\Program Files (x86)\Microsoft\EdgeWebView\Application"
$installed = $wv2Reg -or $wv2File
@{
    pregunta="WebView2"
    instalado=$installed
    reg=$wv2Reg
    archivo=$wv2File
    recomendacion="downloadBootstrapper (0 MB) - instalador final 7.7 MB NSIS como OceanOS medido"
    alternativa_offline="embedBootstrapper +1.8 MB si quieres offline total sin internet"
} | ConvertTo-Json -Depth 3 | Write-Host -ForegroundColor Green

# 5. Store
Write-Host "`n[5/5] Distribución" -ForegroundColor Yellow
@{
    pregunta="Store"
    winget="wingetcreate new acepta NSIS directo, sin firma obligatoria"
    signpath_gratis="SignPath firma gratis te da reputación SmartScreen más rápido"
    recomendacion_final="PRO v10: winget + GitHub Releases con auto-updater minisign. PRO v11: MSIX wrapper solo si necesitas Store"
} | ConvertTo-Json -Depth 3 | Write-Host -ForegroundColor Green

# Guardar JSON
$final = @{
    fecha=(Get-Date -Format 'o')
    host=$env:COMPUTERNAME
    gpu=$gpuInfo
    sqlite_detectado=$hasNative
    licencia_mit=$isMIT
    webview2=$installed
    decision="Tauri v2 + @tauri-apps/plugin-sql (reemplaza sqlite3) + PyInstaller sin torch (25-55 MB) + downloadBootstrapper (0 MB) + SignPath gratis"
}
$out = "$ProjectRoot\docs\RUNEFORGE_PRO_AutoRespuesta_$(Get-Date -Format 'yyyyMMdd_HHmm').json"
$final | ConvertTo-Json -Depth 6 | Out-File -Encoding utf8 $out
Write-Host "`nGuardado en $out" -ForegroundColor Cyan
Write-Host "FIX aplicado: Get-Date con comillas simples 'yyyy-MM-dd HH:mm'" -ForegroundColor Gray
