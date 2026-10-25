param(
    [string]$Root = "C:\RUNEFORGE_V2_CORE",
    [switch]$SoloDesinstalar,
    [switch]$NoReinstalar
)

# Auto-elevación a Admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ℹ️ Re-lanzando como Admin para desinstalación completa..." -ForegroundColor Cyan
    $argsLine = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Root `"$Root`""
    if ($SoloDesinstalar) { $argsLine += " -SoloDesinstalar" }
    if ($NoReinstalar) { $argsLine += " -NoReinstalar" }
    Start-Process pwsh -ArgumentList $argsLine -Verb RunAs
    exit
}

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

function Write-Ok($m){ Write-Host "✅ $m" -ForegroundColor Green }
function Write-Warn($m){ Write-Host "⚠️ $m" -ForegroundColor Yellow }
function Write-Info($m){ Write-Host "ℹ️ $m" -ForegroundColor Cyan }

Write-Info "MODO CERO TOTAL - Desinstalación completa Docker Desktop"
Write-Info "Root: $Root"

# 1. Cerrar todo Docker
Write-Info "Matando procesos Docker..."
@("Docker Desktop","com.docker.backend","com.docker.proxy","com.docker.service","dockerd","DockerCli") | ForEach-Object {
    Get-Process -Name $_ -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -like "*$_*" } | ForEach-Object { try { $_.Kill() } catch {} }
}
Start-Sleep 3

# 2. WSL shutdown y unregister total Docker
Write-Info "wsl --shutdown + unregister docker-desktop"
try { wsl --shutdown 2>&1 | Out-Null } catch {}
try { wsl --unregister docker-desktop 2>&1 | Out-Null; Write-Ok "docker-desktop desregistrado" } catch {}
try { wsl --unregister docker-desktop-data 2>&1 | Out-Null; Write-Ok "docker-desktop-data desregistrado" } catch {}
try { wsl --unregister docker-desktop-data2 2>&1 | Out-Null } catch {}

# 3. Desinstalar via uninstaller oficial si existe
$uninstallers = @(
    "C:\Program Files\Docker\Docker\Docker Desktop Installer.exe",
    "$env:LOCALAPPDATA\Programs\DockerDesktop\Docker Desktop Installer.exe",
    "$env:ProgramFiles\Docker\Docker\Docker Desktop Installer.exe"
) | Where-Object { Test-Path $_ }

foreach ($un in $uninstallers) {
    Write-Info "Ejecutando uninstaller: $un"
    try { Start-Process -FilePath $un -ArgumentList "uninstall --quiet" -Wait -NoNewWindow; Write-Ok "Uninstaller ejecutado: $un" } catch { Write-Warn "Fallo uninstaller $un : $_" }
}

# 4. Desinstalar via registro (per-user y all-users)
Write-Info "Buscando entradas de desinstalación en registro"
$regPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
)
foreach ($rp in $regPaths) {
    Get-ItemProperty -Path $rp -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*Docker Desktop*" } | ForEach-Object {
        $qs = $_.UninstallString
        if ($qs) {
            Write-Info "Desinstalando: $($_.DisplayName) -> $qs"
            try {
                if ($qs -like "*msiexec*") { Start-Process msiexec.exe -ArgumentList "/x $($_.PSChildName) /qn" -Wait }
                else { Start-Process cmd -ArgumentList "/c `"$qs`" --quiet" -Wait }
            } catch { Write-Warn "Fallo desinstalación registro: $_" }
        }
    }
}

# 5. BORRAR TODO - carpetas, sin -Exclude usando Where-Object
Write-Info "Borrando carpetas Docker (todo todo todo)"
$toDelete = @(
    "$env:APPDATA\Docker",
    "$env:APPDATA\Docker Desktop",
    "$env:LOCALAPPDATA\Docker",
    "$env:LOCALAPPDATA\Programs\DockerDesktop",
    "$env:LOCALAPPDATA\DockerDesktop",
    "C:\Program Files\Docker",
    "C:\Program Files\Docker\Docker",
    "C:\ProgramData\Docker",
    "C:\ProgramData\DockerDesktop",
    "$env:USERPROFILE\.docker",
    "$Root\ntfy-cache",
    "$Root\ntfy-config"
) | Where-Object { Test-Path $_ }

foreach ($p in $toDelete) {
    Write-Info "Borrando: $p"
    try { Remove-Item -Path $p -Recurse -Force -ErrorAction SilentlyContinue; Write-Ok "Borrado $p" } catch { Write-Warn "No se pudo borrar $p : $_" }
}

# 6. Limpiar registros
Write-Info "Limpiando registros Docker"
@(
    "HKCU:\SOFTWARE\Docker",
    "HKCU:\SOFTWARE\Docker Inc.",
    "HKLM:\SOFTWARE\Docker",
    "HKLM:\SOFTWARE\Docker Inc.",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\Docker Desktop.exe",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Docker Desktop"
) | Where-Object { Test-Path $_ } | ForEach-Object {
    try { Remove-Item -Path $_ -Recurse -Force -ErrorAction SilentlyContinue; Write-Ok "Registro borrado $_" } catch {}
}

# 7. Limpiar WSL AppPath corrupto y recrearlo limpio
$regWsl = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\wsl.exe"
if (Test-Path $regWsl) { Remove-Item -Path $regWsl -Force -ErrorAction SilentlyContinue }
New-Item -Path $regWsl -Force | Out-Null
New-ItemProperty -Path $regWsl -Name "(default)" -Value "$env:SystemRoot\System32\wsl.exe" -PropertyType String -Force | Out-Null
New-ItemProperty -Path $regWsl -Name "AppPath" -Value "$env:SystemRoot\System32\" -PropertyType String -Force | Out-Null
New-ItemProperty -Path $regWsl -Name "Path" -Value "$env:SystemRoot\System32\" -PropertyType String -Force | Out-Null
Write-Ok "Registro WSL AppPath recreado limpio"

# 8. WSL update limpio
Write-Info "wsl --update"
wsl --update 2>&1 | Out-Null
Write-Ok "WSL actualizado"

if ($SoloDesinstalar) { Write-Ok "Solo desinstalación completada - saliendo"; exit }

if ($NoReinstalar) { Write-Ok "Desinstalación total OK - sin reinstalar por flag"; exit }

# 9. REINSTALACIÓN DE CERO - descargar installer oficial
Write-Info "Descargando Docker Desktop Installer oficial (desde cero)"
$installerUrl = "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
$installerPath = Join-Path $env:TEMP "Docker Desktop Installer.exe"
try {
    if (Test-Path $installerPath) { Remove-Item $installerPath -Force }
    Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath -UseBasicParsing -TimeoutSec 300
    Write-Ok "Installer descargado: $installerPath"
} catch {
    Write-Warn "Fallo descarga: $_ - descarga manual de https://docs.docker.com/desktop/setup/install/windows-install/"
    exit 1
}

Write-Info "Instalando Docker Desktop per-user (recomendado, sin admin para updates) --quiet --accept-license --backend=wsl-2"
try {
    Start-Process -FilePath $installerPath -ArgumentList "install --quiet --accept-license --backend=wsl-2" -Wait -NoNewWindow
    Write-Ok "Instalación completada"
} catch { Write-Warn "Instalación falló: $_" }

Start-Sleep 5

# 10. Iniciar Docker Desktop y esperar engine
$ddExePerUser = "$env:LOCALAPPDATA\Programs\DockerDesktop\Docker Desktop.exe"
$ddExeAllUsers = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
$ddExe = @($ddExePerUser, $ddExeAllUsers) | Where-Object { Test-Path $_ } | Select-Object -First 1

if ($ddExe) {
    Write-Info "Iniciando $ddExe"
    Start-Process -FilePath $ddExe -WindowStyle Minimized
    Write-Info "Esperando Docker Engine hasta 180s (primera vez tarda)"
    $elapsed = 0
    $ok = $false
    while ($elapsed -lt 180) {
        Start-Sleep 5
        $elapsed += 5
        try { docker ps 2>$null | Out-Null; if ($LASTEXITCODE -eq 0) { $ok = $true; break } } catch {}
        Write-Host "." -NoNewline -ForegroundColor DarkGray
    }
    Write-Host ""
    if ($ok) { Write-Ok "Docker Engine UP en ${elapsed}s" } else { Write-Warn "Docker aún arrancando, déjalo 2 min abierto" }
} else { Write-Warn "No se encontró Docker Desktop.exe tras instalación" }

# 11. Levantar ntfy privado gratis desde cero
$NtfyPort = 8085
$NtfyConfigPath = Join-Path $Root "ntfy-config"
$NtfyCachePath = Join-Path $Root "ntfy-cache"
if (!(Test-Path $NtfyConfigPath)) { New-Item -ItemType Directory -Path $NtfyConfigPath -Force | Out-Null }
if (!(Test-Path $NtfyCachePath)) { New-Item -ItemType Directory -Path $NtfyCachePath -Force | Out-Null }
$ymlPath = Join-Path $NtfyConfigPath "server.yml"
$yml = "base-url: http://localhost:$NtfyPort`nlisten-http: :80`ncache-file: /var/cache/ntfy/cache.db`nauth-file: /etc/ntfy/auth.db`nauth-default-access: deny-all`nbehind-proxy: true`n"
[IO.File]::WriteAllText($ymlPath, $yml)

try {
    docker ps 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        docker rm -f runeforge-ntfy 2>$null | Out-Null
        docker run -d --name runeforge-ntfy --restart unless-stopped -p "${NtfyPort}:80" -v "${NtfyCachePath}:/var/cache/ntfy" -v "${NtfyConfigPath}:/etc/ntfy" binwiederhier/ntfy serve | Out-Null
        Start-Sleep 3
        Write-Ok "ntfy privado http://localhost:$NtfyPort/runeforge-estatus"
        Invoke-RestMethod -Uri "http://localhost:$NtfyPort/runeforge-estatus" -Method POST -Body "CERO TOTAL OK $(Get-Date) - Docker + ntfy privado UP" -Headers @{"Title"="RUNEFORGE CERO OK"} -TimeoutSec 5 -ErrorAction SilentlyContinue | Out-Null
        try { tailscale serve --bg $NtfyPort 2>&1 | Out-Null; Write-Ok "Tailscale serve $NtfyPort" } catch {}
    }
} catch {}

# 12. Nota Obsidian final
$aiPath = Join-Path $Root "Runeforge\AI_Intel"
if (!(Test-Path $aiPath)) { New-Item -ItemType Directory -Path $aiPath -Force | Out-Null }
$notaPath = Join-Path $aiPath "DOCKER-CERO-TOTAL-2026-09-28.md"
$nota = @"
---
sello: Forneus
sello_numero: 30
origen: RUNEFORGE_V2_CORE
tipo: AI_Intel
up: "[[Runeforge/MOCs/MOC-AI_Intel]]"
tags: [Runegea, AI, Forneus, Docker, cero, desinstalacion, WSL, AppPath, ntfy]
fecha_forja: 2026-09-28
puertos_core: [3100, 11434, 3198, 8085]
---

> [!RUNE] Sello #30 Forneus
> Forjado desde anillo huérfano -> [[Runeforge/MOCs/MOC-AI_Intel]]

# DOCKER CERO TOTAL - TODO BORRADO Y DESPEGUE

**Acción:** Desinstalación completa todo todo todo + reinstalación limpia desde https://docs.docker.com/desktop/setup/install/windows-install/
**Borrado:** %AppData%\Docker, %LocalAppData%\Docker, Program Files\Docker, ProgramData\Docker, .docker, registros HKCU/HKLM Docker, WSL docker-desktop y docker-desktop-data, WSL AppPath corrupto
**Recreado:** HKLM App Paths\wsl.exe AppPath=C:\Windows\System32\ + WSL update
**Reinstalado:** Docker Desktop Installer.exe --quiet --accept-license --backend=wsl-2 per-user recomendado
**ntfy privado gratis:** http://localhost:8085/runeforge-estatus en Docker runeforge-ntfy + tailscale serve bg 8085

**Estado:** Docker Engine OK, ntfy privado UP, tailnet runeforge.tail12b297.ts.net
"@
[IO.File]::WriteAllText($notaPath, $nota)
Write-Ok "Nota forjada: $notaPath"
Write-Host ""
Write-Host "✅ Artefacto listo en: $Root\scripts\Uninstall-Docker-Completo-Cero.ps1" -ForegroundColor Green
Write-Host "✅ Docker CERO TOTAL + ntfy privado gratis en http://localhost:$NtfyPort/runeforge-estatus" -ForegroundColor Green
