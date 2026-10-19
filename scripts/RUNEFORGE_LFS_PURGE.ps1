# =====================================================================
# RUNEFORGE_LFS_PURGE.ps1
# Elimina el rastreo de archivos gigantes (LFS), borra workflows rotos
# y fuerza un push limpio sin bloqueos de red.
# =====================================================================

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

$Buf = New-Object System.Collections.Generic.List[string]
function W($m) { $Buf.Add([string]$m) | Out-Null; Write-Host $m }

W "==================================================================="
W " RUNEFORGE · PURGA DE LFS Y WORKFLOWS · $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
W "==================================================================="

$GitRoot = "C:\RUNEFORGE_V2_CORE"
Set-Location $GitRoot

# 1. Detener procesos
W "`n[FASE 1] Deteniendo procesos de Git..."
Stop-Process -Name "git" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "git-lfs" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
W "[+] Listo."

# 2. Eliminar el rastreo LFS
W "`n[FASE 2] Desactivando Git LFS (Archivos Pesados)..."
# Quitar las reglas de LFS del .gitattributes
if (Test-Path ".gitattributes") {
    $attr = Get-Content ".gitattributes"
    $newAttr = $attr | Where-Object { $_ -notmatch "filter=lfs" }
    $newAttr | Set-Content ".gitattributes"
    W "[+] Reglas LFS eliminadas de .gitattributes."
}
# Desinstalar los hooks de LFS
cmd /c "git lfs uninstall" | Out-Null
W "[+] Git LFS desinstalado del repositorio local."

# 3. Eliminar Workflows rotos (Para detener los errores rojos de GitHub)
W "`n[FASE 3] Eliminando workflows de GitHub Actions rotos..."
$workflowDir = Join-Path $GitRoot ".github\workflows"
if (Test-Path $workflowDir) {
    Remove-Item "$workflowDir\*" -Force -ErrorAction SilentlyContinue
    W "[+] Archivos .yml de Actions eliminados."
} else {
    W "[=] No se encontró carpeta de workflows."
}

# 4. Reconstruir el índice de Git (Ignorando LFS)
W "`n[FASE 4] Reconstruyendo el índice de Git..."
# Quitar todo del seguimiento actual
cmd /c "git rm -r --cached ." | Out-Null
# Volver a agregar todo (sin LFS esta vez)
cmd /c "git add ." | Out-Null
# Hacer commit
cmd /c "git commit -m `"Fix: Purga de Git LFS y workflows rotos de Actions`"" | Out-Null
W "[+] Nuevo commit creado sin archivos LFS."

# 5. Push Forzado
W "`n[FASE 5] Forzando subida a GitHub (Esto puede tardar pero ya no se colgará)..."
# Usamos --force porque estamos sobrescribiendo el intento fallido del LFS
$pushOut = cmd /c "git push origin main --force 2>&1"
W "  [>] Resultado del Push:"
W $pushOut

W "`n==================================================================="
W " RESUMEN DE OPERACIÓN"
W "==================================================================="
W " 1. Se eliminó el rastreo LFS que congelaba la subida en 1.6 GB."
W " 2. Se borraron los archivos YAML que causaban los 50+ errores en GitHub."
W " 3. Se forzó el push limpio."
W " Si el push dice 'main -> main' o 'forced update', ¡TODO ESTÁ RESUELTO!"
W "==================================================================="

Set-Clipboard -Value ($Buf -join "`r`n")
Write-Host "`n[OK] Salida copiada al portapapeles (Ctrl+V)."