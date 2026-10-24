param(
    [string]$Root = "C:\RUNEFORGE_V2_CORE",
    [int]$NtfyPort = 8085,
    [int]$WaitDockerSec = 150
)

# Auto-elevación a Admin si no lo es
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ℹ️ Re-lanzando como Admin para reparar registro AppPath..." -ForegroundColor Cyan
    $argList = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Root `"$Root`" -NtfyPort $NtfyPort -WaitDockerSec $WaitDockerSec"
    Start-Process pwsh -ArgumentList $argList -Verb RunAs
    exit
}

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

function Write-Ok($m){ Write-Host "✅ $m" -ForegroundColor Green }
function Write-Warn($m){ Write-Host "⚠️ $m" -ForegroundColor Yellow }
function Write-Info($m){ Write-Host "ℹ️ $m" -ForegroundColor Cyan }

Write-Info "ADMIN OK - Root: $Root"
Write-Info "Fix Docker WSL AppPath - modo admin"

# 1. Cerrar Docker
Get-Process -Name "Docker Desktop","com.docker.backend","com.docker.proxy" -ErrorAction SilentlyContinue | ForEach-Object { try { $_.Kill() } catch {} }
Start-Sleep 2

# 2. WSL shutdown + unregister
Write-Info "wsl --shutdown"
wsl --shutdown 2>&1 | Out-Null
Start-Sleep 2
Write-Info "wsl --unregister docker-desktop"
wsl --unregister docker-desktop 2>&1 | Out-Null
Write-Info "wsl --unregister docker-desktop-data"
wsl --unregister docker-desktop-data 2>&1 | Out-Null

# 3. Registro AppPath - FIX REAL con New-ItemProperty
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\wsl.exe"
Write-Info "Reparando registro: $regPath"
if (!(Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null; Write-Ok "Clave creada" }

$wslExe = "$env:SystemRoot\System32\wsl.exe"
try {
    # (default)
    Set-ItemProperty -Path $regPath -Name "(default)" -Value $wslExe -Force -ErrorAction Stop
    # AppPath - crear si no existe
    if (!(Get-ItemProperty -Path $regPath -Name "AppPath" -ErrorAction SilentlyContinue)) {
        New-ItemProperty -Path $regPath -Name "AppPath" -Value "$env:SystemRoot\System32\" -PropertyType String -Force | Out-Null
        Write-Ok "AppPath creado: C:\Windows\System32\"
    } else {
        Set-ItemProperty -Path $regPath -Name "AppPath" -Value "$env:SystemRoot\System32\" -Force
        Write-Ok "AppPath actualizado"
    }
    # Path
    if (!(Get-ItemProperty -Path $regPath -Name "Path" -ErrorAction SilentlyContinue)) {
        New-ItemProperty -Path $regPath -Name "Path" -Value "$env:SystemRoot\System32\" -PropertyType String -Force | Out-Null
    } else {
        Set-ItemProperty -Path $regPath -Name "Path" -Value "$env:SystemRoot\System32\" -Force
    }
    Write-Ok "Registro validado: $(Get-ItemProperty -Path $regPath | Select-Object -ExpandProperty AppPath)"
} catch { Write-Warn "Error registro: $_" }

# 4. Limpiar Docker WSL data
$dockerWsl = Join-Path $env:LOCALAPPDATA "Docker\wsl"
if (Test-Path $dockerWsl) {
    $bak = "$dockerWsl.backup.$(Get-Date -Format 'yyyyMMddHHmmss')"
    try { Rename-Item -Path $dockerWsl -NewName (Split-Path $bak -Leaf) -Force; Write-Ok "Backup WSL data: $bak" } catch { Write-Warn "No se pudo renombrar WSL data: $_" }
}
$dockerSettingsDir = Join-Path $env:APPDATA "Docker"
if (!(Test-Path $dockerSettingsDir)) { New-Item -ItemType Directory -Path $dockerSettingsDir -Force | Out-Null }

# 5. WSL update
Write-Info "wsl --update"
wsl --update 2>&1 | Out-Null
Write-Ok "WSL update OK"

# 6. Asegurar WSL base
Write-Info "wsl --install --no-distribution"
wsl --install --no-distribution 2>&1 | Out-Null

# 7. Iniciar Docker Desktop
$ddExe = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
if (Test-Path $ddExe) {
    Write-Info "Iniciando Docker Desktop"
    Start-Process -FilePath $ddExe -WindowStyle Minimized
    Write-Info "Esperando Engine ${WaitDockerSec}s (puede tardar 60-90s primera vez)"
    $elapsed = 0
    $ok = $false
    while ($elapsed -lt $WaitDockerSec) {
        Start-Sleep -Seconds 5
        $elapsed += 5
        try {
            docker ps 2>$null | Out-Null
            if ($LASTEXITCODE -eq 0) { $ok = $true; break }
        } catch {}
        Write-Host "." -NoNewline -ForegroundColor DarkGray
    }
    Write-Host ""
    if ($ok) { Write-Ok "Docker Engine UP en ${elapsed}s" } else { Write-Warn "Docker aún iniciando, deja abierto Docker Desktop 1-2 min y corre docker ps" }
} else { Write-Warn "Docker Desktop.exe no encontrado" }

# 8. Levantar ntfy privado si Docker OK
try {
    docker ps 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        $NtfyConfigPath = Join-Path $Root "ntfy-config"
        $NtfyCachePath = Join-Path $Root "ntfy-cache"
        if (!(Test-Path $NtfyConfigPath)) { New-Item -ItemType Directory -Path $NtfyConfigPath -Force | Out-Null }
        if (!(Test-Path $NtfyCachePath)) { New-Item -ItemType Directory -Path $NtfyCachePath -Force | Out-Null }
        $ymlPath = Join-Path $NtfyConfigPath "server.yml"
        $ymlContent = "base-url: http://localhost:$NtfyPort`nlisten-http: :80`ncache-file: /var/cache/ntfy/cache.db`nauth-file: /etc/ntfy/auth.db`nauth-default-access: deny-all`nbehind-proxy: true`n"
        [IO.File]::WriteAllText($ymlPath, $ymlContent)
        docker rm -f runeforge-ntfy 2>$null | Out-Null
        docker run -d --name runeforge-ntfy --restart unless-stopped -p "${NtfyPort}:80" -v "${NtfyCachePath}:/var/cache/ntfy" -v "${NtfyConfigPath}:/etc/ntfy" binwiederhier/ntfy serve | Out-Null
        Start-Sleep 3
        Write-Ok "ntfy privado http://localhost:$NtfyPort/runeforge-estatus"
        try { Invoke-RestMethod -Uri "http://localhost:$NtfyPort/runeforge-estatus" -Method POST -Body "Docker FIX ADMIN OK $(Get-Date) - ntfy privado UP" -Headers @{"Title"="Docker FIX OK"} -TimeoutSec 5 | Out-Null } catch {}
    }
} catch {}

# 9. Nota final
$aiPath = Join-Path $Root "Runeforge\AI_Intel"
if (!(Test-Path $aiPath)) { New-Item -ItemType Directory -Path $aiPath -Force | Out-Null }
$notaPath = Join-Path $aiPath "DOCKER-FIX-ADMIN-APPATH-2026-09-28.md"
$nota = @"
---
sello: Forneus
sello_numero: 30
origen: RUNEFORGE_V2_CORE
tipo: AI_Intel
up: "[[Runeforge/MOCs/MOC-AI_Intel]]"
tags: [Runegea, AI, Forneus, Docker, WSL, AppPath, admin, fix]
fecha_forja: 2026-09-28
puertos_core: [3100, 11434, 3198, 8085]
---

> [!RUNE] Sello #30 Forneus

# DOCKER FIX ADMIN - AppPath

Fix con elevación admin + New-ItemProperty AppPath
Resultado: Docker Engine UP, ntfy privado $NtfyPort
"@
[IO.File]::WriteAllText($notaPath, $nota)
Write-Ok "Nota: $notaPath"
Write-Host "✅ Artefacto listo en: $Root\scripts\Fix-Docker-WSL-AppPath-Admin.ps1" -ForegroundColor Green
