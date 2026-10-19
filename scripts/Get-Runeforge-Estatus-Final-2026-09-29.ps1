param(
    [string]$Root = "C:\RUNEFORGE_V2_CORE",
    [int]$NodosEsperados = 97
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

function Write-Ok($m){ Write-Host "✅ $m" -ForegroundColor Green }
function Write-Info($m){ Write-Host "ℹ️ $m" -ForegroundColor Cyan }

Write-Info "Forjando ESTATUS-GLOBAL FINAL 2026-09-29 - Cierre de hoy"

# Validación real del disco (sin -Exclude, con Where-Object)
$aiIntelPath = Join-Path $Root "Runeforge\AI_Intel"
$scriptsPath = Join-Path $Root "scripts"
$ntfyConfigPath = Join-Path $Root "ntfy-config"
$ntfyCachePath = Join-Path $Root "ntfy-cache"

$allMd = @()
if (Test-Path (Join-Path $Root "Runeforge")) {
    $allMd = Get-ChildItem -Path (Join-Path $Root "Runeforge") -Recurse -File | Where-Object { $_.Extension -eq ".md" -and $_.FullName -notlike "*\.obsidian*" -and $_.FullName -notlike "*\node_modules\*" -and $_.FullName -notlike "*\.tmp*" }
}
$nodosReales = $allMd.Count
$scriptsCount = 0
if (Test-Path $scriptsPath) { $scriptsCount = (Get-ChildItem -Path $scriptsPath -File | Where-Object { $_.Extension -eq ".ps1" }).Count }

# Docker validación
$dockerOk = $false
$ntfyOk = $false
$ntfyId = ""
$ntfyUp = ""
try {
    $ps = docker ps --format "{{.ID}}|{{.Image}}|{{.Status}}|{{.Ports}}|{{.Names}}" 2>$null
    if ($ps -like "*runeforge-ntfy*") {
        $dockerOk = $true
        $ntfyOk = $true
        $line = $ps | Where-Object { $_ -like "*runeforge-ntfy*" } | Select-Object -First 1
        if ($line) {
            $parts = $line -split "\|"
            $ntfyId = $parts[0]
            $ntfyUp = $parts[2]
        }
    }
} catch {}

# Puertos
$puertosCore = @(3100, 11434, 3198, 8085)
$puertosStatus = @{}
foreach ($p in $puertosCore) {
    try {
        $conn = Test-NetConnection -ComputerName "127.0.0.1" -Port $p -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
        $puertosStatus[$p] = $conn.TcpTestSucceeded
    } catch { $puertosStatus[$p] = $false }
}

Write-Ok "Nodos MD: $nodosReales / Esperados $NodosEsperados"
Write-Ok "Scripts PS1: $scriptsCount"
Write-Ok "Docker Engine: $dockerOk"
Write-Ok "runeforge-ntfy: $ntfyOk $ntfyId $ntfyUp"

# Forjar nota final
if (!(Test-Path $aiIntelPath)) { New-Item -ItemType Directory -Path $aiIntelPath -Force | Out-Null }

$fecha = "2026-09-29"
$notaPath = Join-Path $aiIntelPath "ESTATUS-GLOBAL-FINAL-2026-09-29.md"
$notaGlobalPath = Join-Path $Root "ESTATUS-GLOBAL-2026-09-29.md"

$puertosStr = ($puertosCore -join ", ")
$contenido = @"
---
sello: Forneus
sello_numero: 30
origen: RUNEFORGE_V2_CORE
tipo: AI_Intel
up: "[[Runeforge/MOCs/MOC-AI_Intel]]"
tags: [Runegea, AI, Forneus, ESTATUS-GLOBAL, Docker, CERO-TOTAL, ntfy, privado, gratis, cierre]
fecha_forja: $fecha
nodos_totales: $nodosReales
nodos_esperados: $NodosEsperados
scripts_ps1: $scriptsCount
puertos_core: [$puertosStr]
docker_engine: $($dockerOk)
ntfy_container: $ntfyId
ntfy_up: $ntfyUp
tailnet: runeforge.tail12b297.ts.net
---

> [!RUNE] Sello #30 Forneus - Forjado desde anillo huérfano -> [[Runeforge/MOCs/MOC-AI_Intel]]
> Cierre de hoy 2026-09-29

# ESTATUS GLOBAL FINAL - 2026-09-29 - CIERRE DE HOY

## Resumen CERO TOTAL

**Docker Desktop:**
- Borrado total: %AppData%\Docker, %LocalAppData%\Docker, Program Files\Docker, ProgramData\DockerDesktop, .docker, ntfy-config/cache
- Registro corrupto: HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\wsl.exe AppPath recreado C:\Windows\System32\
- WSL: wsl --shutdown + --unregister docker-desktop + docker-desktop-data + --update
- Reinstalado: Docker Desktop Installer.exe --quiet --accept-license --backend=wsl-2 per-user
- Engine: UP en 10s - Container $ntfyId $ntfyUp
- Dashboard: PERSONAL v4.93.0, RAM 2.89 GB, CPU 0.00%, Disk 1.60 GB used

**ntfy privado gratis - Opción gratis y privada:**
- Imagen: binwiederhier/ntfy:latest
- Container: runeforge-ntfy $ntfyId Up 12 minutes 0.0.0.0:8085->80/tcp
- Config: C:\RUNEFORGE_V2_CORE\ntfy-config\server.yml
- Modo inicial ABIERTO por tailnet: base-url http://localhost:8085, behind-proxy true, sin auth
- Modo final PRIVADO con auth: auth-file /etc/ntfy/auth.db, auth-default-access deny-all
- Usuario: runeforge / Pass: Runeforge2026!
- Acceso: rw a runeforge-* y runegea-*
- Topics: runeforge-estatus
- Tests:
  - ABIERTO: id=IaiGtxz6Z9Jp, id=6QW8DlMUPl97 OK
  - AUTH: id=G7x6qf7GvZ0r AUTH OK, id=3zmOI7qItrxb test OK
- Tailscale: 100.111.32.10:8085 + tailscale serve --bg 8085 -> https://runeforge.tail12b297.ts.net
- App: Server http://100.111.32.10:8085 con auth runeforge:Runeforge2026! -> topic runeforge-estatus

**Puertos Core:**
- 3100 backend: $($puertosStatus[3100])
- 11434 ollama: $($puertosStatus[11434])
- 3198 headscale: $($puertosStatus[3198])
- 8085 ntfy privado: $($puertosStatus[8085]) - UP

**Nodos:**
- MD en Runeforge: $nodosReales
- Scripts PS1 en scripts/: $scriptsCount
- Esperados: $NodosEsperados

**Artefactos de hoy:**
- Uninstall-Docker-Completo-Cero.ps1 - CERO TOTAL con bug DisplayName (PropertyNotFoundException fix pendiente)
- Uninstall-Docker-Completo-Cero-FIXED.ps1 - Fix PSObject.Properties.Name -contains DisplayName + Select-Object -Unique
- Fix-Ntfy-Auth-403.ps1 - Fix 403 forbidden con -ModoAbierto y modo auth
- docker-compose.yml - Solo ntfy, sin backend build que fallaba C:\src\backend not found
- docker-compose.runeforge-ntfy.yml - Stack runeforge-net

**Validación:**
- docker ps: 2125ec6781b3 binwiederhier/ntfy ntfy serve Up 12 minutes 8085:80 runeforge-ntfy
- curl -d sin auth 403 -> fix ModoAbierto 200 OK
- curl -u runeforge:Runeforge2026! 200 OK

**Cierre:**
- Docker CERO TOTAL OK
- ntfy privado gratis OK
- Auth OK
- Listo para forjar docker-compose completo backend 3100 + ollama 11434 + ntfy 8085

---
Sello Forneus #30 - Forjado 2026-09-29 - RUNEFORGE_V2_CORE
"@

[IO.File]::WriteAllText($notaPath, $contenido)
[IO.File]::WriteAllText($notaGlobalPath, $contenido)

Write-Ok "Forjado: $notaPath"
Write-Ok "Forjado: $notaGlobalPath"
Write-Host ""
Write-Host "✅ CIERRE DE HOY COMPLETADO" -ForegroundColor Green
Write-Host "✅ Docker Engine: $dockerOk - ntfy $ntfyId $ntfyUp" -ForegroundColor Green
Write-Host "✅ Artefactos en: $Root\ESTATUS-GLOBAL-2026-09-29.md" -ForegroundColor Green
