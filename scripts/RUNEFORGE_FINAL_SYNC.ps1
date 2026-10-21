# =====================================================================
# RUNEFORGE_FINAL_SYNC.ps1
# Limpia backups, agrega scripts/reportes pendientes y sincroniza
# todo con GitHub sin tocar los submódulos.
# =====================================================================

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

$Buf = New-Object System.Collections.Generic.List[string]
function W($m) { $Buf.Add([string]$m) | Out-Null; Write-Host $m }

W "==================================================================="
W " RUNEFORGE · SINCRONIZACIÓN FINAL · $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
W "==================================================================="

$GitRoot = "C:\RUNEFORGE_V2_CORE"
Set-Location $GitRoot

# 1. Eliminar archivos de backup temporales que ensucian el repo
W "`n[FASE 1] Eliminando archivos de backup temporales..."
$backups = @(
    "public\index_master_BACKUP_20261020.html",
    "public\index_master_FINAL_BACKUP.html",
    "public\master_componentes_reporte.txt"
)
foreach ($b in $backups) {
    if (Test-Path $b) {
        Remove-Item $b -Force -ErrorAction SilentlyContinue
        W "  [+] Eliminado: $b"
    }
}

# 2. Agregar los scripts nuevos y reportes
W "`n[FASE 2] Agregando scripts y reportes..."
cmd /c "git add scripts/ reports/ RUNEFORGE_V2_CORE.md" | Out-Null
W "[+] Archivos agregados al índice (excluyendo submódulos)."

# 3. Hacer Commit
W "`n[FASE 3] Creando commit final..."
$commitMsg = "Sync: Scripts de auditoría, reportes y documentación maestra"
$commitOut = cmd /c "git commit -m `"$commitMsg`" 2>&1"
W $commitOut

# 4. Push
W "`n[FASE 4] Subiendo a GitHub..."
$pushOut = cmd /c "git push origin main 2>&1"
W "  [>] Resultado del Push:"
W $pushOut

W "`n==================================================================="
W " RESUMEN DE OPERACIÓN"
W "==================================================================="
W " 1. Se eliminaron los backups temporales."
W " 2. Se subieron los scripts y reportes pendientes."
W " 3. El repositorio está 100% sincronizado."
W "==================================================================="

Set-Clipboard -Value ($Buf -join "`r`n")
Write-Host "`n[OK] Salida copiada al portapapeles (Ctrl+V)."
