# =====================================================================
# RUNEFORGE_GIT_ULTRA_CLEAN.ps1
# Destruye el índice local, fuerza compresión máxima, evita timeouts
# de red (HTTP 408) y hace un push limpio a GitHub.
# =====================================================================

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

$Buf = New-Object System.Collections.Generic.List[string]
function W($m) { $Buf.Add([string]$m) | Out-Null; Write-Host $m }

W "==================================================================="
W " RUNEFORGE · ULTRA CLEAN & PUSH · $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
W "==================================================================="

$GitRoot = "C:\RUNEFORGE_V2_CORE"
Set-Location $GitRoot

# 1. Matar procesos
W "`n[FASE 1] Deteniendo procesos de Git..."
Stop-Process -Name "git" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "git-remote-https" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
W "[+] Listo."

# 2. Destruir historial local (borra la basura que causó el 408)
W "`n[FASE 2] Eliminando historial local para empezar de cero..."
if (Test-Path "$GitRoot\.git") {
    cmd /c "rd /s /q .git" 2>$null
    if (Test-Path "$GitRoot\.git") { [System.IO.Directory]::Delete("$GitRoot\.git", $true) }
    W "[+] Carpeta .git destruida."
}

# 3. Crear .gitignore ultra-agresivo (Evita subir logs y basura)
W "`n[FASE 3] Creando .gitignore estricto (Solo código real)..."
$ignoreContent = @"
# --- SISTEMA ---
desktop.ini
Thumbs.db
.DS_Store

# --- ENTORNOS Y COMPILADOS ---
node_modules/
venv/
.env
.venv/
__pycache__/
*.pyc
target/
dist/
build/
out/
bin/
obj/

# --- ARCHIVOS PESADOS Y BACKUPS ---
*.whl
*.zip
*.tar.gz
*.exe
*.dll
*.pdb
*.lib
*.so
*.dylib
*.iso
*.img
*.bak
*.bak.*
*.log
*.tmp

# --- CARPETAS DE BASURA ---
backups/
_archived_backups_*
logs/
"@
$ignoreContent | Set-Content -Path "$GitRoot\.gitignore" -Encoding UTF8

# 4. Reinicializar Git y configurar red para evitar Timeouts
W "`n[FASE 4] Configurando Git para redes lentas..."
cmd /c "git init -b main" | Out-Null
cmd /c "git remote add origin https://github.com/yhb86dy52f-lang/runeforge-v2-nucleo.git" | Out-Null

# HTTP/1.1 evita los errores 408 y 500
cmd /c "git config --global http.version HTTP/1.1" | Out-Null
cmd /c "git config --global http.postBuffer 1048576000" | Out-Null
cmd /c "git config --global core.compression 9" | Out-Null
cmd /c "git config --global http.lowSpeedLimit 0" | Out-Null
cmd /c "git config --global http.lowSpeedTime 999999" | Out-Null
W "[+] Protocolo HTTP/1.1, compresión máxima y buffer de 1GB configurados."

# 5. Preparar archivos
W "`n[FASE 5] Agregando solo el código fuente real..."
cmd /c "git add ." | Out-Null
cmd /c "git commit -m `"RUNEFORGE: Sync limpio (Fix HTTP 408)`"" | Out-Null
W "[+] Commit creado."

# 6. Push
W "`n[FASE 6] Subiendo a GitHub (Puede tardar unos minutos)..."
$pushOut = cmd /c "git push origin main --force 2>&1"
W "  [>] Resultado del Push:"
W $pushOut

W "`n==================================================================="
W " RESUMEN DE OPERACIÓN"
W "==================================================================="
W " 1. Se borró el historial local que causaba el Timeout (408)."
W " 2. Se configuró Git para comprimir al máximo y no cortar la conexión."
W " 3. Se forzó el push omitiendo logs y archivos basura."
W " Si el push dice 'forced update' o 'main -> main', ¡Se ha completado!"
W "==================================================================="

Set-Clipboard -Value ($Buf -join "`r`n")
Write-Host "`n[OK] Salida copiada al portapapeles (Ctrl+V)."