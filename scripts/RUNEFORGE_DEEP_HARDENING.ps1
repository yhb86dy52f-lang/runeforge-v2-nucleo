# =====================================================================
# RUNEFORGE_DEEP_HARDENING.ps1
# Escaneo recursivo para encontrar dependencias, configuraciones
# y carpetas basura. Aplica auditoría y limpieza autónoma.
# =====================================================================

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

$Buf = New-Object System.Collections.Generic.List[string]
function W($m) { $Buf.Add([string]$m) | Out-Null; Write-Host $m }

W "==================================================================="
W " RUNEFORGE · DEEP HARDENING · $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
W "==================================================================="

$RepoDir = "C:\RUNEFORGE_V2_CORE\runeforge-v2-nucleo"
$ArchiveDir = "C:\RUNEFORGE_V2_CORE\_archived_backups_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

if (-not (Test-Path $RepoDir)) {
    W "[ERROR] No se encontró el repositorio en $RepoDir"
    Set-Clipboard -Value ($Buf -join "`r`n")
    exit 1
}

Set-Location $RepoDir
W "[OK] Analizando estructura en: $RepoDir"

# ---------- FASE 1: Descubrimiento de Archivos Clave ----------
W "`n[FASE 1] Escaneo profundo de dependencias y configuraciones"
$pkgFiles = Get-ChildItem -Path $RepoDir -Filter "package.json" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch "node_modules" }
$reqFiles = Get-ChildItem -Path $RepoDir -Filter "requirements.txt" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch "venv|__pycache__" }
$mosqFiles = Get-ChildItem -Path $RepoDir -Filter "mosquitto.conf" -Recurse -ErrorAction SilentlyContinue

if ($pkgFiles) { foreach ($f in $pkgFiles) { W "  [>] Node.js detectado en: $($f.DirectoryName)" } }
if ($reqFiles) { foreach ($f in $reqFiles) { W "  [>] Python detectado en: $($f.DirectoryName)" } }
if ($mosqFiles) { foreach ($f in $mosqFiles) { W "  [>] Mosquitto detectado en: $($f.FullName)" } }

if (-not $pkgFiles -and -not $reqFiles) {
    W "  [!] No se encontraron archivos de dependencias estándar."
}

# ---------- FASE 2: Limpieza Estructural Profunda ----------
W "`n[FASE 2] Limpieza de carpetas pesadas (Backups/Whisper)"
$dirsToArchive = @("backups", "whisper.cpp", "whisper-backend")
New-Item -ItemType Directory -Force -Path $ArchiveDir | Out-Null

foreach ($dir in $dirsToArchive) {
    $targets = Get-ChildItem -Path $RepoDir -Filter $dir -Recurse -Directory -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch "node_modules" }
    foreach ($t in $targets) {
        try {
            # Crear un nombre único para el destino basado en la ruta original
            $safeName = $t.FullName.Replace($RepoDir, "").Replace("\", "_").TrimStart("_")
            $destPath = Join-Path $ArchiveDir $safeName
            Move-Item -Path $t.FullName -Destination $destPath -Force -ErrorAction Stop
            W "  [+] Movido: $($t.FullName) -> $destPath"
        } catch {
            W "  [!] No se pudo mover $($t.FullName). Puede estar en uso."
        }
    }
}

# ---------- FASE 3: Hardening de Servicios ----------
W "`n[FASE 3] Hardening de Servicios (MQTT)"
if ($mosqFiles) {
    foreach ($f in $mosqFiles) {
        $mqttContent = Get-Content $f.FullName -Raw
        if ($mqttContent -notmatch "allow_anonymous false") {
            Add-Content -Path $f.FullName -Value "`nallow_anonymous false`npassword_file /mosquitto/config/pwfile.txt"
            W "  [+] Mosquitto asegurado en: $($f.FullName)"
        } else {
            W "  [=] Mosquitto en $($f.FullName) ya estaba asegurado."
        }
    }
} else {
    W "  [=] No se detectó Mosquitto. Omitiendo."
}

# ---------- FASE 4: Auditoría de Dependencias Profunda ----------
W "`n[FASE 4] Auditoría de Dependencias"
if ($pkgFiles) {
    foreach ($f in $pkgFiles) {
        W "  Ejecutando 'npm audit fix' en $($f.DirectoryName)..."
        Push-Location $f.DirectoryName
        $npmOut = cmd /c "npm audit fix 2>&1"
        if ($npmOut -match "vulnerabilities") {
            W "  [!] Vulnerabilidades encontradas en $($f.DirectoryName). Revisa el reporte local."
        } else {
            W "  [+] Sin vulnerabilidades críticas en $($f.DirectoryName)."
        }
        Pop-Location
    }
}

if ($reqFiles) {
    foreach ($f in $reqFiles) {
        W "  Ejecutando 'pip-audit' en $($f.DirectoryName)..."
        Push-Location $f.DirectoryName
        $pipOut = cmd /c "pip-audit -r requirements.txt 2>&1"
        if ($LASTEXITCODE -ne 0) {
             W "  [!] pip-audit no está instalado o encontró vulnerabilidades en $($f.DirectoryName)."
        } else {
             W "  [+] pip-audit completado en $($f.DirectoryName)."
        }
        Pop-Location
    }
}

# ---------- RESUMEN ----------
W "`n==================================================================="
W " RESUMEN DE OPERACIÓN"
W "==================================================================="
W " 1. Se escaneó profundamente la estructura del repositorio."
W " 2. Las carpetas pesadas encontradas se movieron a:"
W "    $ArchiveDir"
W " 3. Se aseguraron los archivos Mosquitto si existían."
W " 4. Se auditaron las dependencias de Node.js y Python."
W "==================================================================="

Set-Clipboard -Value ($Buf -join "`r`n")
Write-Host "`n[OK] Salida copiada al portapapeles (Ctrl+V)."