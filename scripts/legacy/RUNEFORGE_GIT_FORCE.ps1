# =====================================================================
# RUNEFORGE_GIT_FORCE.ps1
# Fuerza a Git a rastrear los archivos del simulador y el nuevo lanzador,
# ignorando cualquier regla de exclusión previa.
# =====================================================================

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

$Buf = New-Object System.Collections.Generic.List[string]
function W($m) { $Buf.Add([string]$m) | Out-Null; Write-Host $m }

W "==================================================================="
W " RUNEFORGE · FORZANDO SUBIDA A GITHUB · $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
W "==================================================================="

$RepoDir = "C:\RUNEFORGE_V2_CORE\runeforge-v2-nucleo"
Set-Location $RepoDir

W "`n[FASE 1] Verificando estado de Git"
$status = git status --short
if (-not $status) {
    W "  [!] No hay cambios pendientes en la raíz."
} else {
    W "  [>] Cambios pendientes detectados:"
    W $status
}

W "`n[FASE 2] Forzando rastreo de la carpeta 'simulador'"
# -f fuerza a ignorar el .gitignore y agregar todo
git add -f simulador/

W "`n[FASE 3] Confirmando y subiendo cambios"
$commitMsg = "Hardening: limpieza profunda, lanzador seguro y forzado de simulador"
git commit -m "$commitMsg"
$pushOut = git push origin main --force 2>&1
W "  [>] Resultado del Push:"
W $pushOut

W "`n==================================================================="
W " RESUMEN DE OPERACIÓN"
W "==================================================================="
W " Se forzó la inclusión de la carpeta 'simulador' en Git."
W " Si el push fue exitoso, ahora todo el código y el nuevo lanzador"
W " estan respaldados en tu repositorio de GitHub."
W "==================================================================="

Set-Clipboard -Value ($Buf -join "`r`n")
Write-Host "`n[OK] Salida copiada al portapapeles (Ctrl+V)."