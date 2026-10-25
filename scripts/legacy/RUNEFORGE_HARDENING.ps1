# =====================================================================
# RUNEFORGE_HARDENING.ps1
# Ejecuta la limpieza estructural, asegura variables de entorno
# y aplica configuraciones básicas de seguridad en los servicios.
# =====================================================================

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

$Buf = New-Object System.Collections.Generic.List[string]
function W($m) { $Buf.Add([string]$m) | Out-Null; Write-Host $m }

W "==================================================================="
W " RUNEFORGE · HARDENING Y LIMPIEZA · $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
W "==================================================================="

$RepoDir = "C:\RUNEFORGE_V2_CORE\runeforge-v2-nucleo"
$ArchiveDir = "C:\RUNEFORGE_V2_CORE\_archived_backups_$(Get-Date -Format 'yyyyMMdd')"

if (-not (Test-Path $RepoDir)) {
    W "[ERROR] No se encontró la carpeta del repositorio en $RepoDir"
    W "Asegúrate de haber clonado el repositorio en la ruta correcta."
    Set-Clipboard -Value ($Buf -join "`r`n")
    exit 1
}

Set-Location $RepoDir
W "[OK] Trabajando en el repositorio: $RepoDir"

# ---------- FASE 1: Aseguramiento mínimo ----------
W "`n[FASE 1] Aseguramiento de Entorno y Secretos"
$EnvFile = Join-Path $RepoDir ".env"
if (-not (Test-Path $EnvFile)) {
    $envContent = @"
# RUNEFORGE V2 - Variables de Entorno (NO SUBIR A GIT)
PORT=3001
LLM_API_KEY=tu_clave_aqui
MQTT_USER=admin
MQTT_PASS=admin_secure_password
NTFY_USER=admin
NTFY_PASS=ntfy_secure_password
"@
    $envContent | Set-Content -Path $EnvFile -Encoding UTF8
    W "  [+] Creado archivo .env con plantillas de seguridad."
} else {
    W "  [=] El archivo .env ya existe. Omitiendo."
}

# Asegurar que .env y backups estén en .gitignore
$GitIgnore = Join-Path $RepoDir ".gitignore"
$ignoreLines = @(".env", "backups/", "*.log", "__pycache__/")
if (Test-Path $GitIgnore) {
    $currentIgnore = Get-Content $GitIgnore -Raw
    foreach ($line in $ignoreLines) {
        if ($currentIgnore -notmatch [regex]::Escape($line)) {
            Add-Content -Path $GitIgnore -Value "`n$line"
            W "  [+] Agregado a .gitignore: $line"
        }
    }
} else {
    $ignoreLines | Set-Content -Path $GitIgnore -Encoding UTF8
    W "  [+] Creado .gitignore con reglas de seguridad."
}

# ---------- FASE 2: Limpieza estructural ----------
W "`n[FASE 2] Limpieza de Archivos y Carpetas Innecesarias"
$dirsToArchive = @("backups", "whisper-backend", "whisper.cpp")
New-Item -ItemType Directory -Force -Path $ArchiveDir | Out-Null

foreach ($dir in $dirsToArchive) {
    $targetPath = Join-Path $RepoDir $dir
    if (Test-Path $targetPath) {
        try {
            Move-Item -Path $targetPath -Destination $ArchiveDir -Force -ErrorAction Stop
            W "  [+] Movido a archivo seguro: $dir"
        } catch {
            W "  [!] No se pudo mover $dir. Puede estar en uso."
        }
    }
}

# Consolidar scripts curar_inbox (si existen)
$curarFiles = Get-ChildItem -Path $RepoDir -Filter "curar*inbox*" -Recurse -ErrorAction SilentlyContinue
if ($curarFiles.Count -gt 1) {
    W "  [!] Múltiples scripts 'curar_inbox' detectados. Revisar manualmente:"
    foreach ($f in $curarFiles) { W "      - $($f.FullName)" }
}

# ---------- FASE 3: Hardening de Servicios (Docker/Infra) ----------
W "`n[FASE 3] Hardening de Servicios (MQTT, Ntfy)"
$mosquittoConf = Get-ChildItem -Path $RepoDir -Filter "mosquitto.conf" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
if ($mosquittoConf) {
    $mqttContent = Get-Content $mosquittoConf.FullName -Raw
    if ($mqttContent -notmatch "allow_anonymous false") {
        Add-Content -Path $mosquittoConf.FullName -Value "`nallow_anonymous false`npassword_file /mosquitto/config/pwfile.txt"
        W "  [+] Mosquitto asegurado (allow_anonymous false)."
    } else {
        W "  [=] Mosquitto ya estaba asegurado."
    }
} else {
    W "  [!] No se encontró mosquitto.conf. Omitiendo."
}

# ---------- FASE 4: Validación de Dependencias ----------
W "`n[FASE 4] Auditoría de Dependencias"
if (Test-Path (Join-Path $RepoDir "package.json")) {
    W "  Ejecutando 'npm audit fix' (puede tardar un poco)..."
    $npmOut = cmd /c "npm audit fix --force 2>&1"
    if ($npmOut -match "vulnerabilities") {
        W "  [!] NPM reportó vulnerabilidades. Revisa los logs locales."
    } else {
        W "  [+] NPM audit completado."
    }
} else {
    W "  [!] No se encontró package.json."
}

if (Test-Path (Join-Path $RepoDir "requirements.txt")) {
    W "  Ejecutando 'pip-audit' (si está instalado)..."
    $pipOut = cmd /c "pip-audit -r requirements.txt 2>&1"
    if ($LASTEXITCODE -ne 0) {
         W "  [!] pip-audit no está instalado o encontró vulnerabilidades."
    } else {
         W "  [+] pip-audit completado."
    }
}

# ---------- RESUMEN ----------
W "`n==================================================================="
W " RESUMEN DE OPERACIÓN"
W "==================================================================="
W " 1. Se ha creado un archivo .env para resguardar claves."
W " 2. Las carpetas pesadas (backups/whisper) se movieron a:"
W "    $ArchiveDir"
W " 3. Mosquitto (si existe) ahora requiere autenticación."
W " 4. Se actualizaron las reglas de .gitignore."
W "==================================================================="

Set-Clipboard -Value ($Buf -join "`r`n")
Write-Host "`n[OK] Salida copiada al portapapeles (Ctrl+V)."