# =====================================================================
# RUNEFORGE_GIT_FORCE_SYNC.ps1
# Diagnostica el estado de Git, verifica archivos clave y fuerza la
# sincronización con GitHub creando un commit vacío si es necesario.
# =====================================================================

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

$Buf = New-Object System.Collections.Generic.List[string]
function W($m) { $Buf.Add([string]$m) | Out-Null; Write-Host $m }

W "==================================================================="
W " RUNEFORGE · DIAGNÓSTICO Y SINCRONIZACIÓN FORZADA · $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
W "==================================================================="

$RepoDir = "C:\RUNEFORGE_V2_CORE"
$TargetUrl = "https://github.com/yhb86dy52f-lang/runeforge-v2-nucleo.git"
Set-Location $RepoDir

# 1. Verificar archivos clave
W "`n[FASE 1] Verificando existencia de módulos críticos..."
$criticalFiles = @(
    "scripts\brain_hub.py",
    "whisper-backend\server.py",
    "nexus-dashboard",
    "nexus-tactical",
    "RUNEFORGE_BOOT.ps1",
    "AUDIT.ps1",
    "STOP.ps1"
)
foreach ($f in $criticalFiles) {
    if (Test-Path $f) {
        W "  [+] Existe: $f"
    } else {
        W "  [!] FALTA: $f"
    }
}

# 2. Estado actual de Git
W "`n[FASE 2] Estado actual de Git..."
$status = cmd /c "git status -s 2>&1"
if ($status) {
    W "  [>] Archivos pendientes:"
    W $status
} else {
    W "  [=] Árbol de trabajo limpio (sin cambios pendientes)."
}

# 3. Último commit
W "`n[FASE 3] Último commit local..."
$lastCommit = cmd /c "git log -1 --oneline 2>&1"
W "  $lastCommit"

# 4. Forzar commit de actualización (--allow-empty por si no hay cambios)
W "`n[FASE 4] Forzando commit de actualización..."
$commitMsg = "Update V2.6.2: Sincronización forzada de arquitectura"
cmd /c "git commit --allow-empty -m `"$commitMsg`" 2>&1" | ForEach-Object { W $_ }

# 5. Push forzado
W "`n[FASE 5] Push forzado a GitHub..."
cmd /c "git config --global http.postBuffer 1048576000" | Out-Null
cmd /c "git config --global http.version HTTP/1.1" | Out-Null
$pushOut = cmd /c "git push origin main -f --verbose 2>&1"
W "  [>] Resultado del Push:"
foreach ($line in ($pushOut -split "`n")) {
    if ($line -match "error|fatal|forced update|Writing objects|Total|Everything up-to-date") {
        W "    $line"
    }
}

# 6. Verificación final
W "`n[FASE 6] Verificando estado del remoto..."
$remoteLog = cmd /c "git log origin/main -1 --oneline 2>&1"
W "  Último commit remoto: $remoteLog"

W "`n==================================================================="
W " RESUMEN DE OPERACIÓN"
W "==================================================================="
W " Si el push mostró 'forced update', el repositorio remoto"
W " ahora refleja la arquitectura V2.6.2 completa."
W "==================================================================="

Set-Clipboard -Value ($Buf -join "`r`n")
Write-Host "`n[OK] Salida copiada al portapapeles (Ctrl+V)."
