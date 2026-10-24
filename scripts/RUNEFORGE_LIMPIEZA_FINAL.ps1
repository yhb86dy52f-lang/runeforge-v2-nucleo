# =====================================================================
# RUNEFORGE_LIMPIEZA_FINAL.ps1
# Archiva herramientas de desarrollo, repara el lanzador y audita
# secretos expuestos (API Keys/Tokens) en los archivos del simulador.
# =====================================================================

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

$Buf = New-Object System.Collections.Generic.List[string]
function W($m) { $Buf.Add([string]$m) | Out-Null; Write-Host $m }

W "==================================================================="
W " RUNEFORGE · LIMPIEZA FINAL Y AUDITORÍA · $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
W "==================================================================="

$SimuladorDir = "C:\RUNEFORGE_V2_CORE\runeforge-v2-nucleo\simulador"
$ArchiveDir = Join-Path $SimuladorDir "_archive_dev_tools"

if (-not (Test-Path $SimuladorDir)) {
    W "[ERROR] No se encontró la carpeta en $SimuladorDir"
    Set-Clipboard -Value ($Buf -join "`r`n")
    exit 1
}

Set-Location $SimuladorDir

# ---------- FASE 1: Limpieza de Archivos de Desarrollo ----------
W "`n[FASE 1] Archivando herramientas de desarrollo"
New-Item -ItemType Directory -Force -Path $ArchiveDir | Out-Null

# Eliminar el lanzador roto generado previamente
if (Test-Path "start_runeforge.bat") {
    Remove-Item "start_runeforge.bat" -Force
    W "  [+] Eliminado lanzador roto anterior (start_runeforge.bat)."
}

# Mover archivos .zip y scripts de despliegue masivo
$filesToMove = @("*.zip", "Deploy-*.ps1", "publicar_github.ps1")
foreach ($pattern in $filesToMove) {
    $files = Get-ChildItem -Path $SimuladorDir -Filter $pattern -File -ErrorAction SilentlyContinue
    foreach ($f in $files) {
        try {
            Move-Item -Path $f.FullName -Destination $ArchiveDir -Force -ErrorAction Stop
            W "  [+] Archivado: $($f.Name)"
        } catch {
            W "  [!] No se pudo mover $($f.Name)"
        }
    }
}

# ---------- FASE 2: Auditoría del Lanzador Real ----------
W "`n[FASE 2] Examinando el lanzador real del sistema"
$batPath = Join-Path $SimuladorDir "iniciar_servidor.bat"
if (Test-Path $batPath) {
    W "  [+] Se encontró 'iniciar_servidor.bat'. Contenido:"
    $batContent = Get-Content $batPath
    foreach ($line in $batContent) {
        if ($line.Trim() -ne "") {
            W "      | $line"
        }
    }
} else {
    W "  [!] No se encontró 'iniciar_servidor.bat'. Tendrás que abrir el index.html manualmente."
}

# ---------- FASE 3: Escaneo de Secretos Expuestos ----------
W "`n[FASE 3] Escaneando posibles fugas de API Keys/Tokens"
$scanPatterns = @("ghp_", "sk-", "api_key", "password", "token", "bearer")
$scanFiles = Get-ChildItem -Path $SimuladorDir -Include *.ps1, *.js, *.html, *.tsx -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch "node_modules|_archive_dev_tools" }

$secretsFound = $false
foreach ($file in $scanFiles) {
    $content = Get-Content $file.FullName -Raw
    foreach ($pattern in $scanPatterns) {
        # Búsqueda simple de coincidencias
        if ($content -match "(?i)$pattern") {
            # Validar que no sea una palabra de código normal (ej. variable 'token')
            if ($content -match "(?i)(ghp_[a-zA-Z0-9]{20,}|sk-[a-zA-Z0-9]{20,})") {
                W "  [!!!] PELIGRO: Posible token duro (hardcoded) en: $($file.Name)"
                $secretsFound = $true
                break
            }
        }
    }
}

if (-not $secretsFound) {
    W "  [+] No se detectaron API Keys críticas expuestas en el código fuente."
}

# ---------- RESUMEN ----------
W "`n==================================================================="
W " RESUMEN DE OPERACIÓN"
W "==================================================================="
W " 1. Se archivaron los .zip y scripts de deploy en '_archive_dev_tools'."
W " 2. Se revisó el comando de inicio real (iniciar_servidor.bat)."
W " 3. Se auditó el código en busca de contraseñas expuestas."
W "==================================================================="

Set-Clipboard -Value ($Buf -join "`r`n")
Write-Host "`n[OK] Salida copiada al portapapeles (Ctrl+V)."