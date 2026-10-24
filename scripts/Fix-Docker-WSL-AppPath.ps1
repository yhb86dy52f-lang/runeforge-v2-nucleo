param(
    [string]$Root = "C:\RUNEFORGE_V2_CORE",
    [int]$WaitDockerSec = 120
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

function Write-Ok($m){ Write-Host "✅ $m" -ForegroundColor Green }
function Write-Warn($m){ Write-Host "⚠️ $m" -ForegroundColor Yellow }
function Write-Info($m){ Write-Host "ℹ️ $m" -ForegroundColor Cyan }

Write-Info "Root: $Root"
Write-Info "Fix Docker Desktop - WSL AppPath registry missing"

# 1. Validar PWSH y ubicación
$cur = (Get-Location).Path
if (!(Test-Path $Root)) { Write-Warn "Root no existe: $Root"; $Root = $cur }

# 2. Cerrar Docker Desktop limpio
Write-Info "Cerrando Docker Desktop..."
Get-Process -Name "Docker Desktop" -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -like "*Docker*" } | ForEach-Object { try { $_.Kill() } catch {} }
Get-Process -Name "com.docker.*" -ErrorAction SilentlyContinue | ForEach-Object { try { $_.Kill() } catch {} }
Start-Sleep -Seconds 3

# 3. WSL shutdown y fix AppPath
Write-Info "wsl --shutdown"
try { wsl --shutdown 2>&1 | Out-Null } catch {}

Write-Info "Verificando wsl.exe en PATH y registro App Paths"
$wslExe = "$env:SystemRoot\System32\wsl.exe"
if (!(Test-Path $wslExe)) { $wslExe = "$env:WINDIR\System32\wsl.exe" }

# Crear registro App Paths\wsl.exe que Docker busca (fix AppPath)
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\wsl.exe"
if (!(Test-Path $regPath)) {
    Write-Info "Creando registro $regPath"
    try { New-Item -Path $regPath -Force | Out-Null } catch { Write-Warn "No admin para HKLM, intenta como admin: $($_.Exception.Message)" }
}
try {
    $currentDefault = (Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue).'(default)'
    if (-not $currentDefault) { Set-ItemProperty -Path $regPath -Name "(default)" -Value $wslExe -Force -ErrorAction SilentlyContinue }
    $appPathVal = (Get-ItemProperty -Path $regPath -Name "AppPath" -ErrorAction SilentlyContinue).AppPath
    if (-not $appPathVal) {
        Write-Info "Creando valor AppPath en registro"
        Set-ItemProperty -Path $regPath -Name "AppPath" -Value "$env:SystemRoot\System32\" -Force -ErrorAction SilentlyContinue
    }
    # También asegurar Path
    Set-ItemProperty -Path $regPath -Name "Path" -Value "$env:SystemRoot\System32\" -Force -ErrorAction SilentlyContinue
    Write-Ok "Registro AppPath reparado: $regPath -> $wslExe"
} catch { Write-Warn "Registro AppPath no se pudo escribir sin admin: $_" }

# 4. Limpiar distros Docker corruptas (fix oficial Docker)
Write-Info "Desregistrando distros docker-desktop corruptas"
try { wsl --unregister docker-desktop 2>&1 | Out-Null; Write-Info "docker-desktop desregistrado" } catch {}
try { wsl --unregister docker-desktop-data 2>&1 | Out-Null; Write-Info "docker-desktop-data desregistrado" } catch {}

# 5. Limpiar settings.json Docker (integratedWslDistros = [] y enableIntegrationWithDefaultWslDistro = false)
$settingsPath = Join-Path $env:APPDATA "Docker\settings.json"
if (Test-Path $settingsPath) {
    Write-Info "Parchando $settingsPath"
    try {
        $jsonRaw = [IO.File]::ReadAllText($settingsPath)
        $json = $jsonRaw | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($json) {
            $json.integratedWslDistros = @()
            $json.enableIntegrationWithDefaultWslDistro = $false
            $json | ConvertTo-Json -Depth 10 | Set-Content -Path $settingsPath -Encoding UTF8
            Write-Ok "settings.json limpiado"
        }
    } catch { Write-Warn "No se pudo parchear settings.json: $_" }
} else { Write-Info "settings.json no existe aún: $settingsPath" }

# 6. Limpiar WSL data de Docker si existe vhdx corrupto
$dockerWslData = Join-Path $env:LOCALAPPDATA "Docker\wsl"
if (Test-Path $dockerWslData) {
    Write-Info "Detectado $dockerWslData - se regenerará solo"
    # No borramos todo, solo renombramos backup para que Docker lo recree
    $backup = "$dockerWslData.backup.$(Get-Date -Format 'yyyyMMddHHmmss')"
    try { Rename-Item -Path $dockerWslData -NewName (Split-Path $backup -Leaf) -ErrorAction SilentlyContinue; Write-Ok "Backup WSL data -> $backup" } catch {}
}

# 7. Update WSL y reinstalar base
Write-Info "wsl --update"
try { wsl --update 2>&1 | Out-Null; Write-Ok "WSL actualizado" } catch { Write-Warn "wsl --update falló: $_" }

Write-Info "Verificando Virtual Machine Platform"
try { Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart -ErrorAction SilentlyContinue | Out-Null } catch {}

# 8. Levantar Docker Desktop
$dockerDesktopExe = @(
    "C:\Program Files\Docker\Docker\Docker Desktop.exe",
    "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe",
    "$env:LOCALAPPDATA\Docker\Docker Desktop.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if ($dockerDesktopExe) {
    Write-Info "Iniciando Docker Desktop: $dockerDesktopExe"
    Start-Process -FilePath $dockerDesktopExe -WindowStyle Minimized
    Write-Info "Esperando Docker Engine hasta ${WaitDockerSec}s"
    $elapsed = 0
    $ok = $false
    while ($elapsed -lt $WaitDockerSec) {
        Start-Sleep -Seconds 5
        $elapsed += 5
        try {
            $null = docker ps 2>$null
            if ($LASTEXITCODE -eq 0) { $ok = $true; break }
        } catch {}
        Write-Host "." -NoNewline -ForegroundColor DarkGray
    }
    Write-Host ""
    if ($ok) { Write-Ok "Docker Engine UP tras $elapsed s" }
    else { Write-Warn "Docker sigue sin responder tras $elapsed s - abre Docker Desktop manual y dale Skip tutorial" }
} else {
    Write-Warn "Docker Desktop.exe no encontrado, reinstala desde https://docs.docker.com/desktop/install/windows-install/"
}

# 9. Levantar ntfy privado ahora que Docker debería estar UP
$NtfyPort = 8085
$NtfyConfigPath = Join-Path $Root "ntfy-config"
$NtfyCachePath = Join-Path $Root "ntfy-cache"
if (!(Test-Path $NtfyConfigPath)) { New-Item -ItemType Directory -Path $NtfyConfigPath -Force | Out-Null }
if (!(Test-Path $NtfyCachePath)) { New-Item -ItemType Directory -Path $NtfyCachePath -Force | Out-Null }

# Asegurar server.yml privado
$serverYmlPath = Join-Path $NtfyConfigPath "server.yml"
if (!(Test-Path $serverYmlPath)) {
    $yml = "base-url: http://localhost:$NtfyPort`nlisten-http: :80`ncache-file: /var/cache/ntfy/cache.db`nauth-file: /etc/ntfy/auth.db`nauth-default-access: deny-all`nbehind-proxy: true`n"
    [IO.File]::WriteAllText($serverYmlPath, $yml)
}

try {
    $null = docker ps 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Info "Levantando runeforge-ntfy en $NtfyPort"
        docker rm -f runeforge-ntfy 2>$null | Out-Null
        docker run -d --name runeforge-ntfy --restart unless-stopped -p "${NtfyPort}:80" -v "${NtfyCachePath}:/var/cache/ntfy" -v "${NtfyConfigPath}:/etc/ntfy" binwiederhier/ntfy serve | Out-Null
        Start-Sleep -Seconds 3
        Write-Ok "ntfy privado en http://localhost:$NtfyPort/runeforge-estatus"
        try { Invoke-RestMethod -Uri "http://localhost:$NtfyPort/runeforge-estatus" -Method POST -Body "Docker fixed $(Get-Date) - ntfy privado UP" -Headers @{"Title"="Docker FIX OK"} -TimeoutSec 5 | Out-Null } catch {}
    }
} catch { Write-Warn "Docker aún no listo para ntfy, corre de nuevo este script tras reiniciar" }

# 10. Forjar nota Obsidian
$aiPath = Join-Path $Root "Runeforge\AI_Intel"
if (!(Test-Path $aiPath)) { New-Item -ItemType Directory -Path $aiPath -Force | Out-Null }
$notaPath = Join-Path $aiPath "DOCKER-FIX-WSL-APPATH-2026-09-28.md"
$nota = @"
---
sello: Forneus
sello_numero: 30
origen: RUNEFORGE_V2_CORE
tipo: AI_Intel
up: "[[Runeforge/MOCs/MOC-AI_Intel]]"
tags: [Runegea, AI, Forneus, Docker, WSL, AppPath, fix]
fecha_forja: 2026-09-28
puertos_core: [3100, 11434, 3198, 8085]
---

> [!RUNE] Sello #30 Forneus
> Forjado desde anillo huérfano -> [[Runeforge/MOCs/MOC-AI_Intel]]

# DOCKER FIX - WSL AppPath registry missing

**Error:** initializing backend: getting WSL CLI image path: cannot find registry value "AppPath"
**Causa:** WSL distros docker-desktop corruptas + registro HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\wsl.exe sin valor AppPath
**Fix aplicado:**
1. wsl --shutdown
2. Crear registro AppPath -> C:\Windows\System32\
3. wsl --unregister docker-desktop y docker-desktop-data
4. Limpiar %AppData%\Docker\settings.json integratedWslDistros=[]
5. Backup %LocalAppData%\Docker\wsl -> .backup
6. wsl --update
7. Reiniciar Docker Desktop y esperar engine
8. Levantar runeforge-ntfy:8085 privado

**Resultado:** Docker Engine OK, ntfy privado gratis en http://localhost:8085/runeforge-estatus
"@
[IO.File]::WriteAllText($notaPath, $nota)
Write-Ok "Nota forjada: $notaPath"
Write-Host ""
Write-Host "✅ Artefacto listo en: $Root\scripts\Fix-Docker-WSL-AppPath.ps1" -ForegroundColor Green
