
# RUNEFORGE_AutoDiagnostico_PRO.ps1 - v10 PRO
# Auto-responde las 5 preguntas pendientes para EXE PRO
# Ejecutar en RUNEFORGE-PC como Admin: powershell -ExecutionPolicy Bypass -File .\RUNEFORGE_AutoDiagnostico_PRO.ps1

$ErrorActionPreference = "Continue"
$ManifestPath = "C:\RUNEFORGE_V2_CORE\docs\ESP32-PROJECT.json"
if (-not (Test-Path $ManifestPath)) { $ManifestPath = "C:\RUNEFORGE_V2_CORE\Proyecto_ESP32_ScannerPRO_Manifiesto_JSON.json" }
$ProjectRoot = "C:\RUNEFORGE_V2_CORE"

Write-Host "=== RUNEFORGE PRO v10 - Auto-Diagnóstico ===" -ForegroundColor Cyan
Write-Host "Fecha: $(Get-Date -Format yyyy-MM-dd HH:mm)" -ForegroundColor Gray
Write-Host ""

# 1. FlotaKW CUDA size
Write-Host "[1/5] FlotaKW Python + CUDA DLLs" -ForegroundColor Yellow
$reqPath = Get-ChildItem -Path $ProjectRoot -Recurse -Filter "requirements.txt" -ErrorAction SilentlyContinue | Select-Object -First 1
$pyDeps = ""
if ($reqPath) { $pyDeps = Get-Content $reqPath.FullName -Raw }
$hasTorch = $pyDeps -match "torch" -or $pyDeps -match "cuda"
$gpuInfo = ""
try { $gpuInfo = nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader 2>$null } catch {}
$cudaDllSize = "No calculado - requiere PyInstaller build test"
if ($hasTorch) {
    $cudaDllSize = "ALERTA: torch+CUDA ~400-800 MB empaquetado. Recomendado: migrar a onnxruntime (15 MB) o separar modelos en carpeta externalBin"
} else {
    $cudaDllSize = "OK: sin torch, PyInstaller ~25-55 MB estimado"
}
$resp1 = @{
    pregunta="FlotaKW CUDA size"
    torch_detectado=$hasTorch
    gpu=$gpuInfo
    estimacion=$cudaDllSize
    accion="Ejecutar: pyinstaller --onefile --collect-submodules whisper --exclude-module torch si usas faster-whisper"
}
$resp1 | ConvertTo-Json -Depth 3 | Write-Host -ForegroundColor White

# 2. Fastify native addons
Write-Host "`n[2/5] Fastify native addons (better-sqlite3)" -ForegroundColor Yellow
$pkgJson = Get-ChildItem -Path $ProjectRoot -Recurse -Filter "package.json" | Where-Object { $_.FullName -notmatch "node_modules" } | Select-Object -First 1
$hasNative = $false
$nativeList = @()
if ($pkgJson) {
    $content = Get-Content $pkgJson.FullName -Raw
    if ($content -match "better-sqlite3") { $hasNative = $true; $nativeList += "better-sqlite3" }
    if ($content -match "sqlite3") { $hasNative = $true; $nativeList += "sqlite3" }
    if ($content -match "node-pty") { $hasNative = $true; $nativeList += "node-pty" }
    if ($content -match "sharp") { $hasNative = $true; $nativeList += "sharp" }
}
$resp2 = @{
    pregunta="Fastify native addons"
    package_json=$pkgJson.FullName
    detectados=$nativeList
    pkg_compatible= -not $hasNative
    accion= if ($hasNative) { "Usar Node SEA con asarUnpack o Tauri sidecar con externalBin + @yao-pkg/pkg --no-bytecode requiere rebuild" } else { "OK: @yao-pkg/pkg directo" }
}
$resp2 | ConvertTo-Json -Depth 4 | Write-Host -ForegroundColor White

# 3. Licencia
Write-Host "`n[3/5] Licencia RUNEFORGE" -ForegroundColor Yellow
$licenseFile = Get-ChildItem -Path $ProjectRoot -Filter "LICENSE*" | Select-Object -First 1
$lic = if ($licenseFile) { Get-Content $licenseFile.FullName -Raw | Select-Object -First 1 } else { "NO LICENSE file - asumido CERRADO/PROPIETARIO" }
$esOSS = $lic -match "MIT" -or $lic -match "Apache"
$resp3 = @{
    pregunta="Licencia final"
    archivo=$licenseFile.FullName
    contenido_preview=$lic.Substring(0,[Math]::Min(200,$lic.Length))
    es_oss=$esOSS
    firma_recomendada= if ($esOSS) { "SignPath Foundation GRATIS (publisher=SignPath Foundation)" } else { "Azure Trusted Signing $9.99/mes o OV cert $200-400/año + HSM" }
}
$resp3 | ConvertTo-Json -Depth 3 | Write-Host -ForegroundColor White

# 4. WebView2
Write-Host "`n[4/5] WebView2 en PCs destino" -ForegroundColor Yellow
$wv2 = Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}" -ErrorAction SilentlyContinue
$wv2Installed = $null -ne $wv2 -or (Test-Path "C:\Program Files (x86)\Microsoft\EdgeWebView\Application")
$resp4 = @{
    pregunta="WebView2 instalado"
    instalado_local=$wv2Installed
    estrategia= if ($wv2Installed) { "Usar downloadBootstrapper (0 MB extra) - tu PC ya tiene WebView2" } else { "Si distribuyes offline: embedBootstrapper +1.8 MB o offlineInstaller +127 MB" }
    recomendacion_torreon="Torreon PCs: asumir WebView2 presente en Win10 21H2+ y Win11. Usar downloadBootstrapper para instalador ligero 7.7 MB"
}
$resp4 | ConvertTo-Json -Depth 3 | Write-Host -ForegroundColor White

# 5. Microsoft Store
Write-Host "`n[5/5] Microsoft Store vs winget" -ForegroundColor Yellow
$resp5 = @{
    pregunta="Store"
    tauri_msix="Tauri no tiene bundler MSIX oficial, requiere wrapper manual"
    winget="Acepta NSIS .exe directo, sin firma obligatoria, ideal para PRO"
    recomendacion="Fase PRO: solo winget. Fase PRO+STORE: usar electron-builder appx target o envolver Tauri en MSIX con makeappx.exe"
    accion="wingetcreate new para RUNEFORGE_PRO -- acepta tu NSIS"
}
$resp5 | ConvertTo-Json -Depth 3 | Write-Host -ForegroundColor White

# Resumen final JSON
$final = @{
    fecha=Get-Date -Format o
    host=$env:COMPUTERNAME
    gpu=(nvidia-smi --query-gpu=name --format=csv,noheader 2>$null)
    respuestas=@($resp1,$resp2,$resp3,$resp4,$resp5)
    decision_exe="Tauri v2 + sidecars (PyInstaller + @yao-pkg/pkg) + NSIS + embedBootstrapper"
}
$outPath = "$ProjectRoot\docs\RUNEFORGE_PRO_AutoRespuesta_$(Get-Date -Format yyyyMMdd).json"
$final | ConvertTo-Json -Depth 6 | Out-File -Encoding utf8 $outPath
Write-Host "`n=== Auto-respuesta guardada en $outPath ===" -ForegroundColor Green
Write-Host "Listo para construir EXE PRO v10" -ForegroundColor Cyan
