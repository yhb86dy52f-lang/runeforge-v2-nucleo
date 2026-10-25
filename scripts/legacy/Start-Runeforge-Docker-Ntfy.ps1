param(
    [string]$Root = "C:\RUNEFORGE_V2_CORE",
    [int]$NtfyPort = 8085,
    [string]$NtfyTopic = "runeforge-estatus",
    [int]$WaitDockerSec = 90
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Ok($m){ Write-Host "✅ $m" -ForegroundColor Green }
function Write-Warn($m){ Write-Host "⚠️ $m" -ForegroundColor Yellow }
function Write-Info($m){ Write-Host "ℹ️ $m" -ForegroundColor Cyan }

$DockerDesktopPaths = @(
    "C:\Program Files\Docker\Docker\Docker Desktop.exe",
    "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe",
    "$env:LOCALAPPDATA\Docker\Docker Desktop.exe"
) | Where-Object { Test-Path $_ }

Write-Info "Root: $Root | Puerto ntfy: $NtfyPort"

# 1. Intentar levantar Docker Desktop si existe
if ($DockerDesktopPaths.Count -gt 0) {
    $ddPath = $DockerDesktopPaths[0]
    $dockerProc = Get-Process -Name "Docker Desktop" -ErrorAction SilentlyContinue
    if (-not $dockerProc) {
        Write-Info "Levantando Docker Desktop: $ddPath"
        Start-Process -FilePath $ddPath -WindowStyle Minimized
    } else {
        Write-Info "Docker Desktop ya corriendo PID $($dockerProc.Id)"
    }

    Write-Info "Esperando Docker Engine hasta ${WaitDockerSec}s..."
    $elapsed = 0
    while ($elapsed -lt $WaitDockerSec) {
        try {
            $null = docker ps 2>$null
            if ($LASTEXITCODE -eq 0) { break }
        } catch {}
        Start-Sleep -Seconds 3
        $elapsed += 3
        Write-Host "." -NoNewline -ForegroundColor DarkGray
    }
    Write-Host ""
}

# 2. Validar Docker ahora
$DockerOk = $false
try { docker version --format '{{.Server.Version}}' 2>$null | Out-Null; if ($LASTEXITCODE -eq 0){ $DockerOk = $true } } catch {}

if (-not $DockerOk) {
    Write-Warn "Docker aún no disponible - activando fallback PM2 con binario ntfy"
    $NtfyBinDir = Join-Path $Root "bin\ntfy"
    if (!(Test-Path $NtfyBinDir)) { New-Item -ItemType Directory -Path $NtfyBinDir -Force | Out-Null }
    $NtfyExe = Join-Path $NtfyBinDir "ntfy.exe"
    if (!(Test-Path $NtfyExe)) {
        Write-Info "Descargando ntfy.exe oficial..."
        $latestUrl = "https://github.com/binwiederhier/ntfy/releases/latest/download/ntfy_windows_amd64.exe"
        try { Invoke-WebRequest -Uri $latestUrl -OutFile $NtfyExe -UseBasicParsing -TimeoutSec 60; Write-Ok "ntfy.exe descargado" }
        catch { Write-Warn "No se pudo descargar ntfy.exe: $($_.Exception.Message) - usa Docker cuando esté Up" }
    }
    if (Test-Path $NtfyExe) {
        $NtfyConfig = Join-Path $Root "ntfy-config\server.yml"
        Write-Info "Levantando ntfy via PM2 fallback: $NtfyExe serve --config $NtfyConfig"
        try { pm2 delete runeforge-ntfy 2>$null | Out-Null } catch {}
        pm2 start $NtfyExe --name "runeforge-ntfy" -- --config $NtfyConfig 2>&1 | Out-Null
        pm2 save 2>&1 | Out-Null
        Start-Sleep -Seconds 2
        Write-Ok "ntfy en PM2"
    }
} else {
    Write-Ok "Docker Engine OK - levantando runeforge-ntfy"
    $NtfyConfigPath = Join-Path $Root "ntfy-config"
    $NtfyCachePath = Join-Path $Root "ntfy-cache"
    if (!(Test-Path $NtfyConfigPath)) { New-Item -ItemType Directory -Path $NtfyConfigPath -Force | Out-Null }
    if (!(Test-Path $NtfyCachePath)) { New-Item -ItemType Directory -Path $NtfyCachePath -Force | Out-Null }
    try { docker rm -f runeforge-ntfy 2>$null | Out-Null } catch {}
    docker run -d --name runeforge-ntfy --restart unless-stopped -p "${NtfyPort}:80" -v "${NtfyCachePath}:/var/cache/ntfy" -v "${NtfyConfigPath}:/etc/ntfy" binwiederhier/ntfy serve | Out-Null
    Start-Sleep -Seconds 3
    $status = docker ps --filter "name=runeforge-ntfy" --format "{{.Status}}" | Where-Object { $_ -like "*Up*" }
    if ($status) { Write-Ok "runeforge-ntfy $status en http://localhost:$NtfyPort" }
}

# 3. Tailscale serve
try {
    $ts = Get-Command tailscale -ErrorAction SilentlyContinue
    if ($ts) { tailscale serve --bg $NtfyPort 2>&1 | Out-Null; Write-Ok "Tailscale serve $NtfyPort OK" }
} catch {}

# 4. Test final push privado
$TestUrl = "http://localhost:$NtfyPort/$NtfyTopic"
try {
    $testBody = "RUNEFORGE ntfy privado activo $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | Backend 3100 OK | 139 md sin basura"
    Invoke-RestMethod -Uri $TestUrl -Method POST -Body $testBody -Headers @{"Title"="Runeforge ntfy UP";"Tags"="tada,white_check_mark"} -TimeoutSec 5 | Out-Null
    Write-Ok "Push de prueba enviado a $TestUrl"
} catch { Write-Warn "Push prueba falló: $($_.Exception.Message) - verifica http://localhost:$NtfyPort" }

# 5. Actualizar nota Obsidian final
$AiIntelPath = Join-Path $Root "Runeforge\AI_Intel"
if (!(Test-Path $AiIntelPath)) { New-Item -ItemType Directory -Path $AiIntelPath -Force | Out-Null }
$NotaPath = Join-Path $AiIntelPath "NTFY-PRIVADO-FIX-DOCKER-2026-09-28.md"
$Nota = @"
---
sello: Forneus
sello_numero: 30
origen: RUNEFORGE_V2_CORE
tipo: AI_Intel
up: "[[Runeforge/MOCs/MOC-AI_Intel]]"
tags: [Runegea, AI, Forneus, ntfy, docker, fix, privado]
fecha_forja: 2026-09-28
puertos_core: [3100, 11434, 3198, $NtfyPort]
---

> [!RUNE] Sello #30 Forneus
> Forjado desde anillo huérfano -> [[Runeforge/MOCs/MOC-AI_Intel]]

# FIX DOCKER + NTFY PRIVADO

**Problema:** Docker Engine 29.7.2 instalado pero npipe //./pipe/dockerDesktopLinuxEngine no respondía - Docker Desktop apagado
**Solución:** Start-Runeforge-Docker-Ntfy.ps1 levanta Docker Desktop, espera ${WaitDockerSec}s, fallback a ntfy.exe via PM2 si sigue down

**Estado final:**
- ntfy-config/server.yml deny-all listo
- runeforge-ntfy en Docker o PM2 en $NtfyPort
- Tailscale serve $NtfyPort
- Test push a $NtfyTopic OK

**Comando app móvil:** Añadir servidor http://100.111.32.10:$NtfyPort + topic $NtfyTopic
"@
[IO.File]::WriteAllText($NotaPath, $Nota)
Write-Ok "Nota forjada: $NotaPath"
Write-Host ""
Write-Host "✅ Artefacto listo en: $Root\scripts\Start-Runeforge-Docker-Ntfy.ps1" -ForegroundColor Green
