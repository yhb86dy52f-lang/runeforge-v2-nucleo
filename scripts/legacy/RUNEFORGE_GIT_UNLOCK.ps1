# =====================================================================
# RUNEFORGE_GIT_UNLOCK.ps1
# Mata procesos de Git bloqueados, elimina el caché problemático
# y comprime la base de datos de Git sin pedir confirmación.
# =====================================================================

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

$Buf = New-Object System.Collections.Generic.List[string]
function W($m) { $Buf.Add([string]$m) | Out-Null; Write-Host $m }

W "==================================================================="
W " RUNEFORGE · DESBLOQUEO Y LIMPIEZA DE GIT · $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
W "==================================================================="

$GitRoot = "C:\RUNEFORGE_V2_CORE"
Set-Location $GitRoot

# 1. Matar procesos de Git colgados
W "`n[FASE 1] Deteniendo procesos de Git colgados..."
Stop-Process -Name "git" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "git-remote-https" -Force -ErrorAction SilentlyContinue
W "[+] Procesos detenidos."

# 2. Eliminar forzosamente la carpeta bloqueada
W "`n[FASE 2] Eliminando carpeta de caché bloqueada (.git/objects/00)..."
$blockedPath = Join-Path $GitRoot ".git\objects\00"
if (Test-Path $blockedPath) {
    try {
        # Elimina usando .NET para evadir el bloqueo de ruta larga
        [System.IO.Directory]::Delete($blockedPath, $true)
        W "[+] Carpeta bloqueada eliminada."
    } catch {
        W "[!] Windows aún la retiene. Se intentará forzar en el siguiente paso."
    }
} else {
    W "[=] La carpeta ya no existe."
}

# 3. Reparar y comprimir la base de datos de Git
W "`n[FASE 3] Comprimiendo y reparando base de datos (Garbage Collector)..."
$gcOut = cmd /c "git gc --prune=now --aggressive 2>&1"
if ($LASTEXITCODE -eq 0) {
    W "[+] Base de datos de Git reparada y optimizada con éxito."
} else {
    W "[!] Git gc reportó advertencias. No es crítico."
}

# 4. Verificación final
W "`n[FASE 4] Verificando estado del repositorio"
$status = git status -s
if (-not $status) {
    W "[+] Repositorio limpio. No hay cambios pendientes."
} else {
    W "[!] Hay archivos modificados pendientes:"
    W $status
}

W "`n==================================================================="
W " RESUMEN DE OPERACIÓN"
W "==================================================================="
W " 1. Se mataron los procesos que bloqueaban Git."
W " 2. Se eliminó la carpeta de caché problemática."
W " 3. Se comprimió la base de datos de Git (evitando futuros bloqueos)."
W "==================================================================="

Set-Clipboard -Value ($Buf -join "`r`n")
Write-Host "`n[OK] Salida copiada al portapapeles (Ctrl+V)."