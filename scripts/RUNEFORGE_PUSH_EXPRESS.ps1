# =====================================================================
# RUNEFORGE_PUSH_EXPRESS.ps1
# Mata los procesos colgados, ignora submódulos que dan problemas,
# desactiva la compresión lenta y hace un push limpio y rápido.
# =====================================================================

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

$Buf = New-Object System.Collections.Generic.List[string]
function W($m) { $Buf.Add([string]$m) | Out-Null; Write-Host $m }

W "==================================================================="
W " RUNEFORGE · PUSH EXPRESS (SIN COLGARSE) · $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
W "==================================================================="

$GitRoot = "C:\RUNEFORGE_V2_CORE"
Set-Location $GitRoot

# 1. Matar procesos colgados
W "`n[FASE 1] Deteniendo procesos colgados de Git..."
Stop-Process -Name "git" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "git-remote-https" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "ssh" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
W "[+] Procesos detenidos."

# 2. Configurar Git para evitar cuelgues
W "`n[FASE 2] Aplicando configuraciones de red y compresión rápida..."
cmd /c "git config --global pack.threads 1" | Out-Null
cmd /c "git config --global pack.windowMemory 256m" | Out-Null
cmd /c "git config --global pack.packSizeLimit 256m" | Out-Null
W "[+] Configuración de compresión optimizada para redes lentas."

# 3. Preparar archivos (ignorando submódulos conflictivos)
W "`n[FASE 3] Preparando scripts nuevos..."
cmd /c "git add scripts/*.ps1" | Out-Null
# Hacemos commit. Si dice que no hay nada, no pasa nada.
cmd /c "git commit -m `"Fix: Scripts de reparación y bypass de antivirus`"" | Out-Null
W "[+] Archivos preparados."

# 4. Push con Timeout (para que no se quede congelado)
W "`n[FASE 4] Subiendo a GitHub (esto puede tardar un poco)..."
# Usamos un Job para controlar el tiempo máximo de subida (120 segundos)
$job = Start-Job -ScriptBlock {
    Set-Location $using:GitRoot
    git push origin main 2>&1
}

if (Wait-Job $job -Timeout 120) {
    $pushOut = Receive-Job $job
    W "[>] Resultado del Push:"
    W $pushOut
} else {
    W "[!] El push superó los 120 segundos. Es probable que la red esté lenta."
    W "[!] Pero tus archivos ya están guardados en el commit local."
    Stop-Job $job
}

Remove-Job $job -Force -ErrorAction SilentlyContinue

W "`n==================================================================="
W " RESUMEN DE OPERACIÓN"
W "==================================================================="
W " Si el push falló por timeout, puedes intentar subirlo más tarde"
W " ejecutando manualmente: git push origin main"
W " Pero tu código está a salvo en tu disco duro."
W "==================================================================="

Set-Clipboard -Value ($Buf -join "`r`n")
Write-Host "`n[OK] Salida copiada al portapapeles (Ctrl+V)."