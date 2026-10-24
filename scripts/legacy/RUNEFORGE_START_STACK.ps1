# =====================================================================
# RUNEFORGE_START_STACK.ps1
# Levanta/repara el stack: PM2, Ollama, Tailscale, backend
# =====================================================================

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

$Buf = New-Object System.Collections.Generic.List[string]
function W($m) { $Buf.Add([string]$m) | Out-Null; Write-Host $m }

W "==================================================================="
W " RUNEFORGE · START STACK · $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
W "==================================================================="

Set-Location C:\RUNEFORGE_V2_CORE

# ---------- 1. PM2 ----------
W "`n[1] PM2"
$pm2Cmd = Get-Command pm2 -ErrorAction SilentlyContinue
if (-not $pm2Cmd) {
    W "    pm2 NO esta en PATH. Instalando global..."
    & npm install -g pm2 2>&1 | ForEach-Object { W "    $_" }
    $env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path','User')
} else {
    W "    pm2 encontrado: $($pm2Cmd.Source)"
}

# Listar procesos con salida simple (no JSON)
W "`n    pm2 list:"
& pm2 list 2>&1 | ForEach-Object { W "    $_" }

# ---------- 2. Ollama ----------
W "`n[2] Ollama"
$ollamaProc = Get-Process ollama -ErrorAction SilentlyContinue
if ($ollamaProc) {
    W "    Ollama ya corriendo (pid $($ollamaProc.Id -join ','))"
} else {
    W "    Ollama NO corriendo. Buscando ejecutable..."
    $ollamaExe = $null
    $candidates = @(
        "$env:LOCALAPPDATA\Programs\Ollama\ollama.exe",
        "$env:ProgramFiles\Ollama\ollama.exe",
        "${env:ProgramFiles(x86)}\Ollama\ollama.exe"
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) { $ollamaExe = $c; break }
    }

    if ($ollamaExe) {
        W "    Iniciando: $ollamaExe"
        Start-Process -FilePath $ollamaExe -ArgumentList "serve" -WindowStyle Hidden
        Start-Sleep -Seconds 3
    } else {
        W "    Ollama.exe NO encontrado. Instalalo desde https://ollama.com/download"
    }
}

# Verificar API
Start-Sleep -Seconds 2
try {
    $r = Invoke-RestMethod -Uri 'http://127.0.0.1:11434/api/tags' -TimeoutSec 5 -ErrorAction Stop
    W "    OK. Modelos: $($r.models.Count)"
    $r.models | ForEach-Object { W "      - $($_.name) ($([math]::Round($_.size/1MB,0))MB)" }
} catch {
    W "    API no responde aun: $_"
}

# ---------- 3. Tailscale ----------
W "`n[3] Tailscale"
$tsCmd = Get-Command tailscale -ErrorAction SilentlyContinue
if (-not $tsCmd) {
    W "    tailscale NO esta en PATH"
    $tsExe = "$env:ProgramFiles\Tailscale\tailscale.exe"
    if (Test-Path $tsExe) {
        W "    Encontrado en: $tsExe"
        $tsCmd = $tsExe
    }
}

if ($tsCmd) {
    # Iniciar servicio si no corre
    $tsSvc = Get-Service Tailscale -ErrorAction SilentlyContinue
    if ($tsSvc -and $tsSvc.Status -ne 'Running') {
        W "    Servicio Tailscale $($tsSvc.Status). Iniciando..."
        Start-Service Tailscale -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 3
    }

    W "    tailscale status:"
    & $tsCmd status 2>&1 | Select-Object -First 5 | ForEach-Object { W "    $_" }

    # Si dice Stopped, hacer up
    $status = & $tsCmd status 2>&1 | Out-String
    if ($status -match 'stopped|not logged in|NeedsLogin') {
        W "    Tailscale caido. Ejecutando 'tailscale up'..."
        & $tsCmd up 2>&1 | ForEach-Object { W "    $_" }
    }
} else {
    W "    tailscale NO encontrado"
}

# ---------- 4. Backend Fastify ----------
W "`n[4] Fastify backend :3100"
try {
    $r = Invoke-RestMethod -Uri 'http://localhost:3100/health' -TimeoutSec 3 -ErrorAction Stop
    W "    /health OK: $($r | ConvertTo-Json -Compress)"
} catch {
    W "    OFFLINE. Intentando levantar con PM2..."
    $eco = Join-Path (Get-Location) 'ecosystem.config.js'
    if (Test-Path $eco) {
        & pm2 start $eco 2>&1 | ForEach-Object { W "    $_" }
        Start-Sleep -Seconds 5
        try {
            $r2 = Invoke-RestMethod -Uri 'http://localhost:3100/health' -TimeoutSec 5 -ErrorAction Stop
            W "    Backend levantado: $($r2 | ConvertTo-Json -Compress)"
        } catch { W "    Aun OFFLINE: $_" }
    } else {
        W "    ecosystem.config.js no existe. Backend no se puede levantar."
    }
}

# ---------- 5. Resumen ----------
W "`n==================================================================="
W " RESUMEN FINAL"
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

$ts = & tailscale status 2>$null
if ($LASTEXITCODE -eq 0) { W "  [ONLINE]  Tailscale" } else { W "  [OFFLINE] Tailscale" }

W ""
& pm2 list 2>&1 | ForEach-Object { W "  $_" }

W "`n==================================================================="
W " FIN"
W "==================================================================="

Set-Clipboard -Value ($Buf -join "`r`n")
Write-Host "`n[OK] Salida copiada al portapapeles."