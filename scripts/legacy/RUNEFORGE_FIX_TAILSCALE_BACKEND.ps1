# =====================================================================
# RUNEFORGE_FIX_TAILSCALE_BACKEND.ps1
# Arregla Tailscale NoState + resuelve backend huerfano en :3100
# =====================================================================

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

$Buf = New-Object System.Collections.Generic.List[string]
function W($m) { $Buf.Add([string]$m) | Out-Null; Write-Host $m }

W "==================================================================="
W " RUNEFORGE · FIX TAILSCALE + BACKEND · $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
W "==================================================================="

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
W "`nAdmin: $isAdmin"

Set-Location C:\RUNEFORGE_V2_CORE

# ---------- 1. Ver quien ocupa el :3100 ----------
W "`n[1] Quien ocupa el puerto 3100"
$conn = Get-NetTCPConnection -LocalPort 3100 -State Listen -ErrorAction SilentlyContinue
if ($conn) {
    foreach ($c in $conn) {
        $proc = Get-Process -Id $c.OwningProcess -ErrorAction SilentlyContinue
        if ($proc) {
            W "    PID $($proc.Id)  $($proc.ProcessName)  $([math]::Round($proc.WorkingSet/1MB,1))MB"
        } else {
            W "    PID $($c.OwningProcess)  (proceso no encontrado)"
        }
    }
} else {
    W "    Nada escuchando en :3100"
}

# ---------- 2. Ver procesos Node y su linea de comandos ----------
W "`n[2] Procesos node.exe activos"
$nodes = @(Get-CimInstance Win32_Process -Filter "Name='node.exe'" -ErrorAction SilentlyContinue)
foreach ($n in $nodes) {
    $cmd = $n.CommandLine
    if ($cmd.Length -gt 100) { $cmd = $cmd.Substring(0,100) + '...' }
    W "    PID $($n.ProcessId): $cmd"
}

# ---------- 3. Backend: reiniciar si esta huerfano ----------
W "`n[3] Backend Fastify"
$healthOk = $false
try {
    $r = Invoke-RestMethod -Uri 'http://localhost:3100/health' -TimeoutSec 3 -ErrorAction Stop
    W "    /health OK: $($r | ConvertTo-Json -Compress)"
    $healthOk = $true
} catch {
    W "    /health OFFLINE"
}

if ($healthOk) {
    W "    Backend respondiendo. Verificando si PM2 lo controla..."

    $pm2List = & pm2 jlist 2>$null | Out-String
    if ($pm2List -match 'runeforge-backend') {
        try {
            $apps = $pm2List | ConvertFrom-Json
            $be = $apps | Where-Object { $_.name -eq 'runeforge-backend' }
            if ($be) {
                W "    PM2 dice: $($be.pm2_env.status)  pid=$($be.pid)"
                if ($be.pm2_env.status -ne 'online') {
                    W "    Reiniciando en PM2..."
                    & pm2 restart runeforge-backend 2>&1 | ForEach-Object { W "    $_" }
                }
            }
        } catch { W "    (no se pudo parsear pm2 jlist)" }
    }
} else {
    W "    Levantando backend..."
    & pm2 restart runeforge-backend 2>&1 | ForEach-Object { W "    $_" }
    Start-Sleep -Seconds 5
}

# ---------- 4. Tailscale fix ----------
W "`n[4] Tailscale"
$tsExe = "$env:ProgramFiles\Tailscale\tailscale.exe"
if (-not (Test-Path $tsExe)) {
    $tsCmd = Get-Command tailscale -ErrorAction SilentlyContinue
    if ($tsCmd) { $tsExe = $tsCmd.Source }
}

if (-not (Test-Path $tsExe)) {
    W "    tailscale.exe NO encontrado. Abortando seccion."
} else {
    W "    Usando: $tsExe"

    # Estado actual
    $status = & $tsExe status 2>&1 | Out-String
    W "    Status actual (primeras 3 lineas):"
    ($status -split "`n" | Select-Object -First 3) | ForEach-Object { W "      $_" }

    # Si es NoState, aplicar fix
    if ($status -match 'NoState') {
        W "`n    [!] Detectado NoState. Aplicando fix documentado..."
        W "        (reset winsock + restart servicio)"

        if (-not $isAdmin) {
            W "        ADVERTENCIA: se requiere admin para winsock reset."
            W "        Ejecuta esto en una consola ADMIN:"
            W "          netsh winsock reset"
            W "          Restart-Service Tailscale"
            W "        Luego vuelve a correr este script."
        } else {
            # Reset winsock
            W "        netsh winsock reset..."
            & netsh winsock reset 2>&1 | ForEach-Object { W "        $_" }

            # Restart servicio Tailscale
            W "        Restart-Service Tailscale..."
            $svc = Get-Service Tailscale -ErrorAction SilentlyContinue
            if ($svc) {
                Restart-Service Tailscale -Force -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 5
                W "        Servicio: $((Get-Service Tailscale).Status)"
            } else {
                W "        Servicio Tailscale no existe"
            }

            # Intentar up
            W "        tailscale up..."
            & $tsExe up --reset 2>&1 | Select-Object -First 5 | ForEach-Object { W "        $_" }
            Start-Sleep -Seconds 3
        }
    } else {
        W "    Tailscale sin NoState. Verificando conexion..."
        & $tsExe up 2>&1 | Select-Object -First 3 | ForEach-Object { W "    $_" }
    }

    # Estado final
    W "`n    Status final:"
    & $tsExe status 2>&1 | Select-Object -First 10 | ForEach-Object { W "    $_" }
}

# ---------- 5. Resumen ----------
W "`n==================================================================="
W " RESUMEN"
W "==================================================================="

$checks = @(
    @{Name='Ollama :11434';   Url='http://127.0.0.1:11434/api/tags'},
    @{Name='Fastify :3100';   Url='http://localhost:3100/health'}
)
foreach ($c in $checks) {
    try {
        Invoke-RestMethod -Uri $c.Url -TimeoutSec 3 -ErrorAction Stop | Out-Null
        W "  [ONLINE]  $($c.Name)"
    } catch { W "  [OFFLINE] $($c.Name)" }
}

if (Test-Path $tsExe) {
    $ts = & $tsExe status 2>$null | Out-String
    if ($ts -match 'NoState|stopped|Logged out') {
        W "  [OFFLINE] Tailscale ($(if($ts -match 'NoState'){'NoState'}else{'caido'}))"
    } else {
        W "  [ONLINE]  Tailscale"
    }
}

W ""
W "  PM2:"
& pm2 list 2>&1 | Select-Object -First 8 | ForEach-Object { W "  $_" }

W "`n==================================================================="
W " FIN"
W "==================================================================="

Set-Clipboard -Value ($Buf -join "`r`n")
Write-Host "`n[OK] Salida copiada al portapapeles."