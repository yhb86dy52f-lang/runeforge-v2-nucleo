# =====================================================================
# RUNEFORGE_GIT_AMNESIA.ps1
# Destruye la carpeta .git (borrando los 2.3 GB de basura y LFS), 
# crea un repositorio nuevo desde cero y hace un push limpio.
# =====================================================================

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

$Buf = New-Object System.Collections.Generic.List[string]
function W($m) { $Buf.Add([string]$m) | Out-Null; Write-Host $m }

W "==================================================================="
W " RUNEFORGE · AMNESIA TOTAL DE GIT · $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
W "==================================================================="

$GitRoot = "C:\RUNEFORGE_V2_CORE"
Set-Location $GitRoot

# 1. Matar procesos
W "`n[FASE 1] Matando procesos de Git..."
Stop-Process -Name "git" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "git-lfs" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
W "[+] Listo."

# 2. Destruir la carpeta .git
W "`n[FASE 2] Destruyendo carpeta .git (Eliminando 2.3 GB de basura)..."
if (Test-Path "$GitRoot\.git") {
    # Quitar atributos de solo lectura antes de borrar
    cmd /c "attrib -r -h -s .git /s /d" 2>$null
    cmd /c "rd /s /q .git" 2>$null
    if (Test-Path "$GitRoot\.git") {
        W "[!] No se pudo borrar completamente. Intentando con .NET..."
        [System.IO.Directory]::Delete("$GitRoot\.git", $true)
    }
    W "[+] Carpeta .git destruida. El historial y LFS han sido eliminados."
} else {
    W "[=] La carpeta .git ya no existía."
}

# 3. Reinicializar Git
W "`n[FASE 3] Creando un repositorio Git completamente nuevo..."
cmd /c "git init -b main" | Out-Null
cmd /c "git remote add origin https://github.com/yhb86dy52f-lang/runeforge-v2-nucleo.git" | Out-Null
W "[+] Repositorio inicializado y conectado a GitHub."

# 4. Preparar archivos
W "`n[FASE 4] Preparando archivos para el primer commit..."
cmd /c "git add ." | Out-Null
cmd /c "git commit -m `"RUNEFORGE: Initial Clean Commit - Código base estable`"" | Out-Null
W "[+] Archivos preparados."

# 5. Push
W "`n[FASE 5] Subiendo el repositorio virgen a GitHub..."
$pushOut = cmd /c "git push origin main --force 2>&1"
W "  [>] Resultado del Push:"
W $pushOut

W "`n==================================================================="
W " RESUMEN DE OPERACIÓN"
W "==================================================================="
W " 1. Se borró el repositorio local y sus 2.3 GB de basura."
W " 2. Se inició un repositorio nuevo (sin LFS, sin historial)."
W " 3. Si el push dice 'forced update', GitHub está finalmente limpio."
W "==================================================================="

Set-Clipboard -Value ($Buf -join "`r`n")
Write-Host "`n[OK] Salida copiada al portapapeles (Ctrl+V)."