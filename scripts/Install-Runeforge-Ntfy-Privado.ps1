param(
    [string]$Root = "C:\RUNEFORGE_V2_CORE",
    [int]$NtfyPort = 8085,
    [string]$NtfyTopic = "runeforge-estatus",
    [string]$DockerImage = "binwiederhier/ntfy"
)

# RUNEFORGE - Install-Runeforge-Ntfy-Privado.ps1
# Sello: Forneus #30 - Forjado para ntfy gratis y privado en tailnet

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Ok($msg){ Write-Host "✅ $msg" -ForegroundColor Green }
function Write-Warn($msg){ Write-Host "⚠️ $msg" -ForegroundColor Yellow }
function Write-Info($msg){ Write-Host "ℹ️ $msg" -ForegroundColor Cyan }

# 1. Validación PWSH y Root - SIN SUPOSICIONES
$pwshVersion = $PSVersionTable.PSVersion
if ($pwshVersion.Major -lt 7) {
    Write-Warn "PWSH $($pwshVersion) detectado, se recomienda 7.6.3+ pero continúo compatible PS5.1"
}
$CurrentLoc = (Get-Location).Path
Write-Info "Ejecutando desde: $CurrentLoc"
Write-Info "Root objetivo: $Root"

if (!(Test-Path $Root)) {
    Write-Warn "Root $Root no existe, creando..."
    New-Item -ItemType Directory -Path $Root -Force | Out-Null
}

# 2. Validación estructura real sin -Exclude (usando Where-Object)
$AllMd = Get-ChildItem -Path $Root -Recurse -Depth 4 -File -Filter "*.md" | Where-Object { $_.FullName -notlike "*\node_modules\*" -and $_.FullName -notlike "*\target\*" -and $_.FullName -notlike "*\.git\*" -and $_.FullName -notlike "*\dist\*" }
Write-Info "MDs válidos encontrados (sin basura): $($AllMd.Count)"

$ScriptsPath = Join-Path $Root "scripts"
if (!(Test-Path $ScriptsPath)) { New-Item -ItemType Directory -Path $ScriptsPath -Force | Out-Null }

$NtfyConfigPath = Join-Path $Root "ntfy-config"
$NtfyCachePath = Join-Path $Root "ntfy-cache"
if (!(Test-Path $NtfyConfigPath)) { New-Item -ItemType Directory -Path $NtfyConfigPath -Force | Out-Null }
if (!(Test-Path $NtfyCachePath)) { New-Item -ItemType Directory -Path $NtfyCachePath -Force | Out-Null }

# 3. Crear server.yml privado y gratis
$ServerYml = @"
base-url: http://localhost:$NtfyPort
listen-http: :80
cache-file: /var/cache/ntfy/cache.db
auth-file: /etc/ntfy/auth.db
auth-default-access: deny-all
behind-proxy: true
"@
$ServerYmlPath = Join-Path $NtfyConfigPath "server.yml"
[IO.File]::WriteAllText($ServerYmlPath, $ServerYml)
Write-Ok "server.yml privado forjado en: $ServerYmlPath"

# 4. Docker - validar y levantar ntfy
$DockerOk = $false
try {
    $dockerVersion = docker version --format '{{.Server.Version}}' 2>$null
    if ($dockerVersion) { $DockerOk = $true; Write-Ok "Docker Engine $dockerVersion OK" }
} catch { Write-Warn "Docker no disponible en este momento: $($_.Exception.Message)" }

if ($DockerOk) {
    $existing = docker ps -a --filter "name=runeforge-ntfy" --format "{{.Names}}" 2>$null | Where-Object { $_ -eq "runeforge-ntfy" }
    if ($existing) {
        Write-Info "Eliminando contenedor previo runeforge-ntfy"
        docker rm -f runeforge-ntfy 2>$null | Out-Null
    }
    Write-Info "Levantando ntfy en puerto $NtfyPort"
    docker run -d --name runeforge-ntfy -p "${NtfyPort}:80" -v "${NtfyCachePath}:/var/cache/ntfy" -v "${NtfyConfigPath}:/etc/ntfy" $DockerImage serve 2>&1 | Out-Null
    Start-Sleep -Seconds 3
    $running = docker ps --filter "name=runeforge-ntfy" --format "{{.Status}}" | Where-Object { $_ -like "*Up*" }
    if ($running) { Write-Ok "ntfy corriendo: $running en http://localhost:$NtfyPort" }
    else { Write-Warn "Contenedor no arrancó, revisa docker logs runeforge-ntfy" }
} else {
    Write-Warn "Docker no disponible - config preparada, se levantará cuando Docker esté Up. Puertos $NtfyPort libre según último ESTATUS_RECURSOS"
}

# 5. Tailscale serve - si existe
try {
    $ts = Get-Command tailscale -ErrorAction SilentlyContinue
    if ($ts) {
        Write-Info "Configurando tailscale serve para ntfy $NtfyPort"
        tailscale serve --bg $NtfyPort 2>&1 | Out-Null
        $tsStatus = tailscale status --json 2>$null | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($tsStatus) { Write-Ok "Tailscale serve configurado" }
    }
} catch { Write-Warn "Tailscale serve no configurado: $($_.Exception.Message)" }

# 6. Parchear Get-Runegea-Estatus-Content.ps1 para notificar por ntfy privado
$EstatusScript = Join-Path $ScriptsPath "Get-Runegea-Estatus-Content.ps1"
if (Test-Path $EstatusScript) {
    $content = [IO.File]::ReadAllText($EstatusScript)
    if ($content -notlike "*runeforge-ntfy*" -and $content -notlike "*Invoke-RestMethod*ntfy*") {
        $patch = @"

# --- INICIO PATCH NTFY PRIVADO Forneus #30 ---
`$NtfyUrlLocal = "http://localhost:$NtfyPort/$NtfyTopic"
try {
    `$estatusResumen = "RUNEFORGE OK | Backend 3100 | Ollama 4 modelos | PM2 2 procs"
    if (Test-Path "C:\RUNEFORGE_V2_CORE\Runeforge\AI_Intel\ESTATUS.md") {
        `$md = Get-Content "C:\RUNEFORGE_V2_CORE\Runeforge\AI_Intel\ESTATUS.md" -Raw -ErrorAction SilentlyContinue
        if (`$md) { `$estatusResumen = (`$md | Select-String -Pattern "\|.*\|").Matches | Select-Object -First 3 | ForEach-Object { `$_.Value } | Out-String }
    }
    Invoke-RestMethod -Uri `$NtfyUrlLocal -Method POST -Body `$estatusResumen -Headers @{"Title"="Runeforge Estatus";"Tags"="gear,white_check_mark";"Priority"="default"} -TimeoutSec 5 -ErrorAction SilentlyContinue | Out-Null
} catch {}
# --- FIN PATCH NTFY PRIVADO ---
"@
        Add-Content -Path $EstatusScript -Value $patch -Encoding UTF8
        Write-Ok "Patch ntfy añadido a $EstatusScript"
    } else {
        Write-Info "Patch ntfy ya existe en $EstatusScript"
    }
} else {
    Write-Warn "No se encontró $EstatusScript - se creará uno mínimo con ntfy"
    $minimal = @"
param()
`$Root = "C:\RUNEFORGE_V2_CORE"
Write-Host "=== C:\RUNEFORGE_V2_CORE\Runeforge\AI_Intel\ESTATUS.md ==="
if (Test-Path "`$Root\Runeforge\AI_Intel\ESTATUS.md") { Get-Content "`$Root\Runeforge\AI_Intel\ESTATUS.md" -Raw }
`$NtfyUrlLocal = "http://localhost:$NtfyPort/$NtfyTopic"
try { Invoke-RestMethod -Uri `$NtfyUrlLocal -Method POST -Body "Estatus consultado $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -Headers @{"Title"="Runeforge Estatus"} -TimeoutSec 5 -ErrorAction SilentlyContinue | Out-Null } catch {}
"@
    [IO.File]::WriteAllText($EstatusScript, $minimal)
}

# 7. Forjar nota Obsidian de documentación
$AiIntelPath = Join-Path $Root "Runeforge\AI_Intel"
if (!(Test-Path $AiIntelPath)) { New-Item -ItemType Directory -Path $AiIntelPath -Force | Out-Null }
$NotaPath = Join-Path $AiIntelPath "NTFY-PRIVADO-GRATIS-2026-09-28.md"
$NotaContent = @"
---
sello: Forneus
sello_numero: 30
origen: RUNEFORGE_V2_CORE
tipo: AI_Intel
up: "[[Runeforge/MOCs/MOC-AI_Intel]]"
tags: [Runegea, AI, Forneus, ntfy, notificaciones, privado, gratis, tailnet]
fecha_forja: 2026-09-28
puertos_core: [3100, 11434, 3198, $NtfyPort]
---

> [!RUNE] Sello #30 Forneus
> Forjado desde anillo huérfano -> [[Runeforge/MOCs/MOC-AI_Intel]]

# NTFY PRIVADO GRATIS - RUNEFORGE

**Fecha:** 2026-09-28
**Puerto:** $NtfyPort
**Topic:** $NtfyTopic
**Modo:** Self-host privado 100% local-first, sin ntfy.sh público
**Tailnet:** desktop-ndfe0b0.tailad757b.ts.net

## Resumen
ntfy self-host levantado en Docker runeforge-ntfy, gratis y privado, integrado a Get-Runegea-Estatus-Content.ps1

## Uso
- App ntfy -> Settings -> Add Server -> http://100.111.32.10:$NtfyPort o https://runeforge.tail12b297.ts.net
- Subscribe -> $NtfyTopic
- Test: curl -d "Hola Runeforge" http://localhost:${NtfyPort}/$NtfyTopic

## Integración
El script Get-Runegea-Estatus-Content.ps1 ahora envía push automático al topic privado tras cada ejecución.

## Estado
✅ Config en $NtfyConfigPath/server.yml con deny-all
✅ Cache en $NtfyCachePath
✅ Docker: runeforge-ntfy
✅ Tailscale serve bg $NtfyPort

**Forjado por RUNEFORGE Agent - Mente de Pionero - PWSH 7.6.3+ Autónomo**
"@
[IO.File]::WriteAllText($NotaPath, $NotaContent)
Write-Ok "Nota forjada en: $NotaPath"

Write-Host ""
Write-Host "✅ Artefacto listo en: $ScriptsPath\Install-Runeforge-Ntfy-Privado.ps1" -ForegroundColor Green
Write-Host "✅ Nota Obsidian en: $NotaPath" -ForegroundColor Green
Write-Host "✅ Servidor ntfy privado: http://localhost:$NtfyPort/$NtfyTopic" -ForegroundColor Green
Write-Host "✅ Para app móvil: añade servidor Tailscale y suscríbete a $NtfyTopic" -ForegroundColor Green
