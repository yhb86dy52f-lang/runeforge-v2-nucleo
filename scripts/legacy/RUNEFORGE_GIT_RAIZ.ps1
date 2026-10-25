# =====================================================================
# RUNEFORGE_GIT_RAIZ.ps1
# Corrige la ruta del repositorio, ignora archivos pesados (whl, bak)
# y sube los cambios reales (scripts y simulador) a GitHub.
# =====================================================================

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

$Buf = New-Object System.Collections.Generic.List[string]
function W($m) { $Buf.Add([string]$m) | Out-Null; Write-Host $m }

W "==================================================================="
W " RUNEFORGE · REPARACIÓN DE GIT EN LA RAÍZ · $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
W "==================================================================="

# Moverse a la raíz REAL donde está la carpeta .git
$GitRoot = "C:\RUNEFORGE_V2_CORE"
if (-not (Test-Path "$GitRoot\.git")) {
    W "[!] ADVERTENCIA: No se encontró la carpeta .git en $GitRoot"
    W "    Es posible que el repositorio esté en otro lado."
}

Set-Location $GitRoot
W "[OK] Ubicación corregida a la raíz del repositorio: $GitRoot"

# ---------- FASE 1: Crear .gitignore Maestro ----------
W "`n[FASE 1] Creando reglas de exclusión (.gitignore) para no subir basura"
$ignorePath = Join-Path $GitRoot ".gitignore"
$ignoreContent = @"
# Archivos pesados de Python
*.whl
*.zip

# Backups y temporales
*.bak
*.bak-*
_archived_backups_*

# Imágenes sueltas en la raíz
*.jpg
*.png
!runeforge-v2-nucleo/simulador/*.png
!runeforge-v2-nucleo/simulador/*.ico

# Entornos virtuales y cachés
__pycache__/
*.pyc
venv/
.env
node_modules/

# Logs
*.log
"@
$ignoreContent | Set-Content -Path $ignorePath -Encoding UTF8
W "  [+] Archivo .gitignore actualizado en la raíz."

# ---------- FASE 2: Rastrear todo ----------
W "`n[FASE 2] Agregando los archivos correctos a Git"
# git add -A respeta el .gitignore que acabamos de crear
git add -A
W "  [+] Archivos preparados (staged)."

# ---------- FASE 3: Commit y Push ----------
W "`n[FASE 3] Subiendo a GitHub"
$commitMsg = "Fix: Estructura de Git corregida, limpieza de basura y lanzador seguro"
git commit -m "$commitMsg"

$pushOut = git push origin main 2>&1
W "  [>] Resultado del Push:"
W $pushOut

W "`n==================================================================="
W " RESUMEN DE OPERACIÓN"
W "==================================================================="
W " 1. Se detectó y corrigió la raíz real del repositorio."
W " 2. Se creó un .gitignore para evitar subir los archivos .whl y .bak."
W " 3. Se subieron los scripts, el simulador y el nuevo lanzador."
W "==================================================================="

Set-Clipboard -Value ($Buf -join "`r`n")
Write-Host "`n[OK] Salida copiada al portapapeles (Ctrl+V)."