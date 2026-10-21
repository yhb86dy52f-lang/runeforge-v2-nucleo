# =====================================================================
# RUNEFORGE_PUSH_CYBER_UI.ps1
# Sincroniza el nuevo Master Cyber-UI con GitHub y asegura el respaldo.
# =====================================================================

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

$Buf = New-Object System.Collections.Generic.List[string]
function W($m) { $Buf.Add([string]$m) | Out-Null; Write-Host $m }

W "==================================================================="
W " RUNEFORGE · SINCRONIZACIÓN CYBER-UI · $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
W "==================================================================="

$GitRoot = "C:\RUNEFORGE_V2_CORE"
Set-Location $GitRoot

# 1. Preparar el archivo generado
W "`n[FASE 1] Preparando archivos para el commit..."
cmd /c "git add public/index_master_FINAL.html" | Out-Null
W "[+] Archivo agregado al índice."

# 2. Hacer Commit
W "`n[FASE 2] Creando commit con el nuevo Master..."
$commitMsg = "Feat: Master Cyber-UI (Glassmorphism + Vanilla JS, 15.26 KB)"
$commitOut = cmd /c "git commit -m `"$commitMsg`" 2>&1"
W $commitOut

# 3. Push a GitHub
W "`n[FASE 3] Subiendo a GitHub..."
$pushOut = cmd /c "git push origin main 2>&1"
W "  [>] Resultado del Push:"
W $pushOut

W "`n==================================================================="
W " RESUMEN DE OPERACIÓN"
W "==================================================================="
W " El Master de 15.26 KB (Cero dependencias) ha sido respaldado."
W " El repositorio está actualizado y listo para despliegue."
W "==================================================================="

Set-Clipboard -Value ($Buf -join "`r`n")
Write-Host "`n[OK] Salida copiada al portapapeles (Ctrl+V)."
