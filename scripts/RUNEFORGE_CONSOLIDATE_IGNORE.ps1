# =====================================================================
# RUNEFORGE_CONSOLIDATE_IGNORE.ps1
# Elimina los .gitignore redundantes (.v2.1, .v2.2), restaura el maestro
# y limpia el índice de Git para evitar ruidos en el repositorio.
# =====================================================================

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

$Buf = New-Object System.Collections.Generic.List[string]
function W($m) { $Buf.Add([string]$m) | Out-Null; Write-Host $m }

W "==================================================================="
W " RUNEFORGE · CONSOLIDACIÓN DE .GITIGNORE · $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
W "==================================================================="

$GitRoot = "C:\RUNEFORGE_V2_CORE"
Set-Location $GitRoot

# 1. Eliminar .gitignore redundantes del disco y de Git
W "`n[FASE 1] Erradicando archivos .gitignore redundantes..."
$redundantFiles = @(".gitignore.v2.1", ".gitignore.v2.2", ".gitignore.v2.2.bak")
foreach ($f in $redundantFiles) {
    if (Test-Path $f) {
        Remove-Item $f -Force -ErrorAction SilentlyContinue
        W "  [+] Eliminado del disco: $f"
    }
    # Eliminar del rastreo de Git si estaban indexados
    cmd /c "git rm --cached $f 2>nul" | Out-Null
}

# 2. Restaurar el .gitignore Maestro
W "`n[FASE 2] Inyectando el .gitignore maestro definitivo..."
$ignoreContent = @"
# SISTEMA
desktop.ini
Thumbs.db
.DS_Store

# ENTORNOS
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

# BINARIOS Y PESADOS
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

# BASURA
backups/
_archived_backups_*
logs/
"@
$ignoreContent | Set-Content -Path "$GitRoot\.gitignore" -Encoding UTF8
W "  [+] .gitignore maestro restaurado."

# 3. Reconstruir índice de Git para aplicar limpieza
W "`n[FASE 3] Limpiando el índice de Git..."
cmd /c "git rm -r --cached . 2>nul" | Out-Null
cmd /c "git add ." | Out-Null
W "  [+] Índice reconstruido."

# 4. Commit y Push final
W "`n[FASE 4] Sincronizando con GitHub..."
$commitOut = cmd /c "git commit -m `"Cleanup: Unificación de .gitignore y limpieza de redundancias`" 2>&1"
W "  [>] Commit:"
W $commitOut

W "  [>] Push..."
$pushOut = cmd /c "git push origin main 2>&1"
W $pushOut

W "`n==================================================================="
W " RESUMEN DE OPERACIÓN"
W "==================================================================="
W " 1. Se eliminaron los .gitignore duplicados (.v2.1, .v2.2)."
W " 2. Se restauró el .gitignore maestro con reglas de exclusión."
W " 3. Se limpió el índice de Git y se subió el cambio."
W "==================================================================="

Set-Clipboard -Value ($Buf -join "`r`n")
Write-Host "`n[OK] Salida copiada al portapapeles (Ctrl+V)."
