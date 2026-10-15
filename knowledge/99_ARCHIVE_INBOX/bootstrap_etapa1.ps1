# Bootstrap Etapa 1 - Prototipo Bitácora WhatsApp
# Ubicación: C:\RUNEFORGE_V2_CORE\scripts\bootstrap_etapa1.ps1
# Ejecutar: PowerShell 7.6.3 como Admin en C:\RUNEFORGE_V2_CORE

Write-Host "⚙ [CINER] Ingeniero Tinkerbell Activo - Bootstrap Etapa 1" -ForegroundColor Cyan
Write-Host "🛡  [NÚCLEO] Runeforge Estable | Filosofía Local First" -ForegroundColor Green

$CORE = "C:\RUNEFORGE_V2_CORE"
$INBOX = "$CORE\knowledge\00_INBOX\whatsapp_raw"
$RAW = "$CORE\data\raw\whatsapp"
$PROCESSED = "$CORE\data\processed"
$BACKUP_ROOT = "C:\RUNEFORGE_BACKUPS"

# 1. Limpiar duplicación crítica
Write-Host "`n[1/5] Limpiando duplicación RUNEFORGE_KNOWLEDGE..." -ForegroundColor Yellow
$dup = "$CORE\knowledge\RUNEFORGE_KNOWLEDGE"
if (Test-Path $dup) {
    $dest = "$BACKUP_ROOT\RUNEFORGE_KNOWLEDGE_$(Get-Date -Format yyyyMMdd_HHmmss)"
    Move-Item -Path $dup -Destination $dest -Force
    Write-Host "  ✅ Movido a $dest" -ForegroundColor Green
} else {
    Write-Host "  ℹ️ No hay duplicado" -ForegroundColor Gray
}

# 2. Corregir estructura headscale duplicada
Write-Host "`n[2/5] Verificando infra/headscale..." -ForegroundColor Yellow
$hs1 = "$CORE\infra\headscale\config\data"
$hs2 = "$CORE\infra\headscale\data"
if ((Test-Path $hs1) -and (Test-Path $hs2)) {
    Write-Host "  ⚠️ Duplicado detectado: config/data y data" -ForegroundColor Red
    Write-Host "  → Revisar manualmente, no auto-borro por seguridad" -ForegroundColor Gray
    Get-ChildItem $hs1, $hs2 | Format-Table Name, LastWriteTime
}

# 3. Preparar carpetas Etapa 1
Write-Host "`n[3/5] Creando estructura Etapa 1..." -ForegroundColor Yellow
@($RAW, $PROCESSED, "$CORE\data\commander", "$CORE\knowledge\01_normalized\PROJECTS") | ForEach-Object {
    if (-not (Test-Path $_)) { New-Item -ItemType Directory -Path $_ -Force | Out-Null }
    Write-Host "  ✅ $_" -ForegroundColor Green
}

# 4. Descomprimir whatsapp_raw si existe zip
Write-Host "`n[4/5] Procesando whatsapp_raw 2026-05-02..." -ForegroundColor Yellow
$zipFile = Get-ChildItem $INBOX -Filter "*.zip" -Recurse | Select-Object -First 1
if ($zipFile) {
    Write-Host "  📦 Encontrado: $($zipFile.FullName)" -ForegroundColor Cyan
    try {
        Expand-Archive -Path $zipFile.FullName -DestinationPath $RAW -Force
        Write-Host "  ✅ Descomprimido a $RAW" -ForegroundColor Green
        Get-ChildItem $RAW -Recurse | Measure-Object | ForEach-Object { Write-Host "  📊 Archivos: $($_.Count)" }
    } catch {
        Write-Host "  ❌ Error descomprimiendo: $_" -ForegroundColor Red
    }
} else {
    Write-Host "  ℹ️ No hay zip en $INBOX, buscando carpetas raw..." -ForegroundColor Gray
    Get-ChildItem $INBOX -Recurse | Format-Table Name, Length -AutoSize
}

# 5. Validar núcleo
Write-Host "`n[5/5] Validando núcleo Runeforge..." -ForegroundColor Yellow
try {
    $status = Invoke-RestMethod http://localhost:3100/api/ollama/status -TimeoutSec 3
    Write-Host "  ✅ Ollama status: ok=$($status.ok) count=$($status.count)" -ForegroundColor Green
} catch {
    Write-Host "  ⚠️ Ollama no responde en :3100 - ejecuta .\runeforge_launcher.ps1" -ForegroundColor Red
}

try {
    pm2 list
} catch {
    Write-Host "  ⚠️ pm2 no encontrado en PATH" -ForegroundColor Red
}

# 6. Crear ROADMAP y .gitignore sugerido
Write-Host "`n[Bonus] Verificando ROADMAP y .gitignore..." -ForegroundColor Yellow
$roadmap = "$CORE\ROADMAP.md"
if (-not (Test-Path $roadmap)) {
    Write-Host "  ℹ️ Copia ROADMAP_ETAPAS_Runeforge.md a $roadmap" -ForegroundColor Gray
}

$gitignore = "$CORE\.gitignore"
$entries = @("node_modules/", "data/raw/", "knowledge/00_INBOX/", "*.zip", ".env")
if (Test-Path $gitignore) {
    $content = Get-Content $gitignore
    $entries | ForEach-Object { if ($content -notcontains $_) { Add-Content $gitignore $_; Write-Host "  ✅ Añadido a .gitignore: $_" -ForegroundColor Green } }
}

Write-Host "`n✅ Bootstrap Etapa 1 completado" -ForegroundColor Green
Write-Host "Siguiente: Configurar WhatsApp Business Cloud en forgerrune.app.n8n.cloud" -ForegroundColor Cyan
Write-Host "Data Table bitacoras: fecha | tipo | proyecto | texto | estado | origen" -ForegroundColor White
