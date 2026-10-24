# =====================================================================
# RUNEFORGE_FIX_ARRANQUE_UNICO.ps1
# Deja a PM2 como unico dueño del backend :3100
# Desactiva: tarea RUNEFORGE_Cerebro_3001 + Startup Runeforge.lnk
# Preserva:  PM2 + tarea RUNEFORGE_Musculo_8000 (:8000)
# =====================================================================

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

$Buf = New-Object System.Collections.Generic.List[string]
function W($m) { $Buf.Add([string]$m) | Out-Null; Write-Host $m }

W "==================================================================="
W " RUNEFORGE · ARRANQUE UNICO · $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
W "==================================================================="

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
W "`nAdmin: $isAdmin"
if (-not $isAdmin) {
    W "ERROR: se requiere PowerShell como Administrador para desactivar la tarea."
    Set-Clipboard -Value ($Buf -join "`r`n"); return
}

# ---------- 1. Desactivar tarea RUNEFORGE_Cerebro_3001 ----------
W "`n[1] Desactivando tarea RUNEFORGE_Cerebro_3001"
$task = Get-ScheduledTask -TaskName "RUNEFORGE_Cerebro_3001" -ErrorAction SilentlyContinue
if ($task) {
    if ($task.State -eq 'Disabled') {
        W "    Ya estaba desactivada"
    } else {
        Stop-ScheduledTask -TaskName "RUNEFORGE_Cerebro_3001" -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
        Disable-ScheduledTask -TaskName "RUNEFORGE_Cerebro_3001" -ErrorAction SilentlyContinue | Out-Null
        $state = (Get-ScheduledTask -TaskName "RUNEFORGE_Cerebro_3001").State
        W "    Estado ahora: $state"
    }
} else {
    W "    Tarea no existe"
}

# ---------- 2. Mover Runeforge.lnk del Startup ----------
W "`n[2] Startup folder Runeforge.lnk"
$startup = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
$lnk = Join-Path $startup "Runeforge.lnk"
$backupDir = Join-Path $startup "_disabled"
if (Test-Path $lnk) {
    if (-not (Test-Path $backupDir)) {
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    }
    $dest = Join-Path $backupDir ("Runeforge.lnk.disabled_" + (Get-Date -Format 'yyyyMMdd-HHmmss'))
    Move-Item -LiteralPath $lnk -Destination $dest -Force
    W "    Movido a: $dest"
} else {
    W "    No existe (ya estaba fuera)"
}

# ---------- 3. Backup del .bat ----------
W "`n[3] Backup de runeforge_start.bat"
$bat = "C:\RUNEFORGE_V2_CORE\runeforge_start.bat"
if (Test-Path $bat) {
    $bak = "$bat.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
    Copy-Item -LiteralPath $bat -Destination $bak -Force
    W "    Backup: $bak"
    # Reemplazar contenido por orquestador minimo (no toca :3100)
    $newContent = @'
@echo off
cd /d C:\RUNEFORGE_V2_CORE
echo [RUNEFORGE] Orquestador de arranque
echo [RUNEFORGE] PM2 se encarga del backend :3100
echo [RUNEFORGE] Verificando PM2...
call pm2 resurrect
echo [RUNEFORGE] Estado:
call pm2 list
pause
'@
    Set-Content -LiteralPath $bat -Value $newContent -Encoding ASCII
    W "    runeforge_start.bat reescrito (solo orquestacion)"
} else {
    W "    No existe el .bat"
}

# ---------- 4. Verificar estado final ----------
W "`n[4] Estado final de tareas RUNEFORGE_*"
Get-ScheduledTask -TaskName "RUNEFORGE_*" -ErrorAction SilentlyContinue | ForEach-Object {
    W "    [$($_.State)] $($_.TaskName)"
}

# ---------- 5. PM2 ----------
W "`n[5] PM2 actual"
& pm2 list 2>&1 | Select-Object -First 10 | ForEach-Object { W "    $_" }

# ---------- 6. Puerto :3100 ----------
W "`n[6] Quien tiene :3100"
$conn = Get-NetTCPConnection -LocalPort 3100 -State Listen -ErrorAction SilentlyContinue
if ($conn) {
    foreach ($c in $conn) {
        $p = Get-Process -Id $c.OwningProcess -ErrorAction SilentlyContinue
        if ($p) { W "    PID $($p.Id)  $($p.ProcessName)" }
    }
} else {
    W "    (libre - se levantara al reiniciar)"
}

W "`n==================================================================="
W " FIN"
W "==================================================================="
W ""
W " Proximo paso: REINICIAR Windows para confirmar arranque limpio"
W " (recuerda: Tailscale tambien requiere reboot por el winsock reset)"
W "==================================================================="

Set-Clipboard -Value ($Buf -join "`r`n")
Write-Host "`n[OK] Salida copiada al portapapeles."