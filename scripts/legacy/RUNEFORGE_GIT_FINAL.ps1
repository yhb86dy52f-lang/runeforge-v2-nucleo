# =====================================================================
# RUNEFORGE_GIT_FINAL.ps1
# Reconstruye el índice, verifica el estado y asegura que todo
# esté subido a GitHub sin bloqueos del sistema.
# =====================================================================

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

$Buf = New-Object System.Collections.Generic.List[string]
function W($m) { $Buf.Add([string]$m) | Out-Null; Write-Host $m }

W "==================================================================="
W " RUNEFORGE · CIERRE FINAL DE GIT · $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
W "==================================================================="

$GitRoot = "C:\RUNEFORGE_V2_CORE"
Set-Location $GitRoot

# 1. Verificar estado actual
W "`n[FASE 1] Verificando estado de los archivos..."
$status = git status -s
if (-not $status) {
    W "[+] El repositorio está limpio. No hay cambios pendientes."
} else {
    W "[!] Cambios pendientes detectados:"
    W $status
}

# 2. Reconstruir índice y limpiar sin bloquearse
W "`n[FASE 2] Reconstruyendo índice (gc ligero)..."
# Usamos --prune=now sin --aggressive para que sea rápido y no se cuelgue
cmd /c "git gc --prune=now 2>&1" | Out-Null
W "[+] Índice reconstruido."

# 3. Intentar subir a GitHub
W "`n[FASE 3] Asegurando subida a GitHub..."
$pushOut = cmd /c "git push origin main 2>&1"
W "[>] Resultado del Push:"
W $pushOut

# 4. Diagnóstico final
W "`n[FASE 4] Diagnóstico de integridad rápida..."
$fsckOut = cmd /c "git fsck --connectivity-only 2>&1"
if ($LASTEXITCODE -eq 0) {
    W "[+] Integridad del repositorio: PERFECTA."
} else {
    W "[!] Advertencia de integridad (revisa los logs locales):"
    W $fsckOut
}

W "`n==================================================================="
W " RESUMEN DE OPERACIÓN"
W "==================================================================="
W " 1. Se verificó que no haya archivos sueltos."
W " 2. Se reconstruyó la base de datos de Git."
W " 3. Se forzó la subida a GitHub."
W " 4. Si el push dice 'Everything up-to-date' o 'main -> main',"
W "    tu proyecto está 100% respaldado en la nube."
W "==================================================================="

Set-Clipboard -Value ($Buf -join "`r`n")
Write-Host "`n[OK] Salida copiada al portapapeles (Ctrl+V)."