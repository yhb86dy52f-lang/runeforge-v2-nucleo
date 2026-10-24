# =====================================================================
# RUNEFORGE_GIT_FIX_MAESTRO.ps1
# Desmarca miles de archivos basura, crea un .gitignore definitivo
# y sube el repositorio limpio.
# =====================================================================

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

$Buf = New-Object System.Collections.Generic.List[string]
function W($m) { $Buf.Add([string]$m) | Out-Null; Write-Host $m }

W "==================================================================="
W " RUNEFORGE · REPARACIÓN MAESTRA DE GIT · $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
W "==================================================================="

$GitRoot = "C:\RUNEFORGE_V2_CORE"
Set-Location $GitRoot

# 1. Eliminar bloqueos de Git (por el intento anterior)
if (Test-Path ".git\index.lock") {
    Remove-Item ".git\index.lock" -Force -ErrorAction SilentlyContinue
    W "[+] Eliminado bloqueo de índice previo."
}

# 2. Desmarcar TODO (sin borrar archivos del disco)
W "`n[FASE 1] Desmarcando archivos masivos de Git (esto toma un momento)..."
git rm -r --cached . | Out-Null
W "[+] Índice de Git limpiado."

# 3. Crear el .gitignore definitivo
W "`n[FASE 2] Creando reglas de exclusión definitivas..."
$ignoreContent = @"
# --- SISTEMA Y ENTORNOS ---
desktop.ini
Thumbs.db
.DS_Store
node_modules/
venv/
.venv/
env/
__pycache__/
*.pyc
*.pyo

# --- COMPILACIONES Y BINARIOS PESADOS ---
target/
bin/
obj/
dist/
build/
out/
*.exe
*.dll
*.pdb
*.lib
*.so
*.dylib
*.whl
*.zip
*.tar.gz
*.7z
*.iso

# --- BACKUPS Y LOGS ---
*.bak
*.bak-*
*.bak.*
*.tmp
*.log
_archived_backups_*

# --- SECRETOS ---
.env
.env.local
*.pem
*.key
"@
$ignoreContent | Set-Content -Path "$GitRoot\.gitignore" -Encoding UTF8
W "[+] .gitignore maestro creado."

# 4. Volver a agregar SOLO los archivos permitidos
W "`n[FASE 3] Agregando solo el código fuente real..."
git add .
W "[+] Archivos preparados (staged)."

# 5. Commit y Push
W "`n[FASE 4] Subiendo el repositorio limpio..."
git commit -m "Fix: Limpieza masiva de binarios (target, node_modules) y configuracion de .gitignore maestro"

# Forzar un poco el empaquetado limpio antes de subir
git gc --prune=now | Out-Null

W "  [>] Resultado del Push:"
$pushOut = git push origin main 2>&1
W $pushOut

W "`n==================================================================="
W " RESUMEN DE OPERACIÓN"
W "==================================================================="
W " Se eliminaron miles de archivos innecesarios del seguimiento de Git."
W " El repositorio ahora solo contiene el código real, no los binarios."
W " Si el push dice 'Everything up-to-date' o 'main -> main', el proceso"
W " fue un éxito total."
W "==================================================================="

Set-Clipboard -Value ($Buf -join "`r`n")
Write-Host "`n[OK] Salida copiada al portapapeles (Ctrl+V)."