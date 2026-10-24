# =====================================================================
# RUNEFORGE_FIX_BACKEND_DUP.ps1
# Resuelve el duplicado del backend (huerfano vs PM2)
# =====================================================================

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

$Buf = New-Object System.Collections.Generic.List[string]
function W($m) { $Buf.Add([string]$m) | Out-Null; Write-Host $m }

W "==================================================================="
W " RUNEFORGE · FIX BACKEND DUPLICADO · $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
W "==================================================================="

Set-Location C:\RUNEFORGE_V2_CORE

# ---------- 1. Quien tiene el :3100 ----------
W "`n[1] Quien tiene el :3100"
$conn = Get-NetTCPConnection -LocalPort 3100 -State Listen -ErrorAction SilentlyContinue
$orphanPid = $null
foreach ($c in $conn) {
    $proc = Get-Process -Id $c.OwningProcess -ErrorAction SilentlyContinue
    if ($proc) {
        W "    PID $($proc.Id)  $($proc.ProcessName)  $([math]::Round($proc.WorkingSet/1MB,1))MB"
        $orphanPid = $proc.Id
    }
}

# ---------- 2. Matar huerfano ----------
W "`n[2] Deteniendo huerfano"
if ($orphanPid) {
    try {
        Stop-Process -Id $orphanPid -Force
        W "    PID $orphanPid detenido"
        Start-Sleep -Seconds 2
    } catch {
        W "    No se pudo detener PID $orphanPid : $_"
    }
} else {
    W "    Sin huerfano en :3100"
}

# ---------- 3. Verificar puerto libre ----------
W "`n[3] Puerto :3100 despues"
$still = Get-NetTCPConnection -LocalPort 3100 -State Listen -ErrorAction SilentlyContinue
if ($still) {
    W "    Aun ocupado por PID $($still.OwningProcess)"
} else {
    W "    Libre"
}

# ---------- 4. Limpiar PM2 ----------
W "`n[4] Reset de PM2"
& pm2 delete runeforge-backend 2>&1 | ForEach-Object { W "    $_" }
Start-Sleep -Seconds 1
& pm2 save --force 2>&1 | ForEach-Object { W "    $_" }

# ---------- 5. Levantar limpio desde ecosystem ----------
W "`n[5] Levantando desde ecosystem.config.js"
$eco = Join-Path (Get-Location) 'ecosystem.config.js'
if (Test-Path $eco) {
    & pm2 start $eco 2>&1 | ForEach-Object { W "    $_" }
    Start-Sleep -Seconds 5
    & pm2 save --force 2>&1 | ForEach-Object { W "    $_" }
} else {
    W "    ecosystem.config.js NO existe"
    W "    Levantando server.js directo..."
    & pm2 start server.js --name runeforge-backend 2>&1 | ForEach-Object { W "    $_" }
    Start-Sleep -Seconds 5
    & pm2 save --force 2>&1 | ForEach-Object { W "    $_" }
}

# ---------- 6. Verificacion ----------
W "`n[6] Verificacion"
try {
    $r = Invoke-RestMethod -Uri 'http://localhost:3100/health' -TimeoutSec 5 -ErrorAction Stop
    W "    /health OK: $($r | ConvertTo-Json -Compress)"
} catch {
    W "    /health OFFLINE: $_"
}

W "`n    PM2 list:"
& pm2 list 2>&1 | Select-Object -First 8 | ForEach-Object { W "    $_" }

# ---------- 7. Nota sobre Tailscale ----------
W "`n[7] Tailscale"
W "    El winsock reset requiere REINICIO de Windows."
W "    Despues del reboot:"
W "      tailscale up"
W "    Si sigue en NoState tras el reboot:"
W "      reinstalar Tailscale desde https://tailscale.com/download/windows"

W "`n==================================================================="
W " FIN"
W "==================================================================="

Set-Clipboard -Value ($Buf -join "`r`n")
Write-Host "`n[OK] Salida copiada al portapapeles."