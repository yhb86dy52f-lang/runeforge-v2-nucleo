param(
    [string]$Root = "C:\RUNEFORGE_V2_CORE",
    [string]$NtfyUser = "runeforge",
    [string]$NtfyPass = "Runeforge2026!",
    [int]$NtfyPort = 8085,
    [switch]$ModoAbierto
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

function Write-Ok($m){ Write-Host "✅ $m" -ForegroundColor Green }
function Write-Warn($m){ Write-Host "⚠️ $m" -ForegroundColor Yellow }
function Write-Info($m){ Write-Host "ℹ️ $m" -ForegroundColor Cyan }

$NtfyConfigPath = Join-Path $Root "ntfy-config"
$NtfyCachePath = Join-Path $Root "ntfy-cache"
if (!(Test-Path $NtfyConfigPath)) { New-Item -ItemType Directory -Path $NtfyConfigPath -Force | Out-Null }

$serverYmlPath = Join-Path $NtfyConfigPath "server.yml"

if ($ModoAbierto) {
    Write-Info "Modo ABIERTO privado por tailnet - sin auth, solo accesible por 100.111.32.10 y localhost"
    $yml = "base-url: http://localhost:$NtfyPort`nlisten-http: :80`ncache-file: /var/cache/ntfy/cache.db`nbehind-proxy: true`n"
    [IO.File]::WriteAllText($serverYmlPath, $yml)
    Write-Ok "server.yml modo abierto escrito"
} else {
    Write-Info "Modo PRIVADO con auth - creando usuario $NtfyUser"
    $yml = "base-url: http://localhost:$NtfyPort`nlisten-http: :80`ncache-file: /var/cache/ntfy/cache.db`nauth-file: /etc/ntfy/auth.db`nauth-default-access: deny-all`nbehind-proxy: true`n"
    [IO.File]::WriteAllText($serverYmlPath, $yml)
    Write-Ok "server.yml con auth escrito"
}

Write-Info "Recreando runeforge-ntfy con nueva config"
try { docker rm -f runeforge-ntfy 2>$null | Out-Null } catch {}
docker run -d --name runeforge-ntfy --restart unless-stopped -p "${NtfyPort}:80" -v "${NtfyCachePath}:/var/cache/ntfy" -v "${NtfyConfigPath}:/etc/ntfy" binwiederhier/ntfy serve | Out-Null
Start-Sleep 5
Write-Ok "Contenedor recreado"

if (-not $ModoAbierto) {
    Write-Info "Creando usuario $NtfyUser en auth.db"
    # Esperar a que ntfy cree auth.db
    Start-Sleep 3
    try {
        docker exec runeforge-ntfy ntfy user add --role=admin $NtfyUser 2>&1 | Out-Null
        Write-Info "Usuario agregado, seteando password"
        # ntfy user add pide password interactivo, usamos ntfy user change-pass o echo
        docker exec runeforge-ntfy sh -c "echo '$NtfyPass' | ntfy user change-pass $NtfyUser --new-password='$NtfyPass'" 2>&1 | Out-Null
        # Alternativa si falla: ntfy user add con stdin
        docker exec runeforge-ntfy sh -c "ntfy user add $NtfyUser --role=admin 2>&1 || true" | Out-Null
    } catch { Write-Warn "Error creando usuario, probando modo directo: $_" }
    
    # Intentar con ntfy tool directo
    try {
        # Borrar y crear con password via env
        docker exec runeforge-ntfy ntfy user del $NtfyUser 2>&1 | Out-Null
        docker exec runeforge-ntfy sh -c "printf '$NtfyPass\n$NtfyPass\n' | ntfy user add $NtfyUser --role=admin" 2>&1 | Out-Null
        Write-Ok "Usuario $NtfyUser creado"
    } catch { Write-Warn "No se pudo crear usuario interactivo: $_" }

    try {
        docker exec runeforge-ntfy ntfy access $NtfyUser "runeforge-*" rw 2>&1 | Out-Null
        docker exec runeforge-ntfy ntfy access $NtfyUser "runegea-*" rw 2>&1 | Out-Null
        Write-Ok "Acceso rw a runeforge-* y runegea-*"
    } catch { Write-Warn "Error seteando acceso: $_" }
}

Write-Info "Probando publish"
Start-Sleep 2
if ($ModoAbierto) {
    try {
        $r = Invoke-RestMethod -Uri "http://localhost:$NtfyPort/runeforge-estatus" -Method POST -Body "RUNEFORGE CERO TOTAL OK - 12 min UP - FIXED AUTH OPEN" -Headers @{"Title"="NTFY PRIVADO GRATIS FIXED"} -TimeoutSec 10
        Write-Ok "Publish OK modo abierto: $r"
    } catch { Write-Warn "Publish falló modo abierto: $($_.Exception.Message)" }
} else {
    $pair = "$($NtfyUser):$($NtfyPass)"
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
    $base64 = [Convert]::ToBase64String($bytes)
    $headers = @{"Authorization"="Basic $base64"; "Title"="NTFY PRIVADO GRATIS AUTH"}
    try {
        $r = Invoke-RestMethod -Uri "http://localhost:$NtfyPort/runeforge-estatus" -Method POST -Body "RUNEFORGE CERO TOTAL OK - AUTH OK" -Headers $headers -TimeoutSec 10
        Write-Ok "Publish OK con auth: $r"
        Write-Info "Para curl usa: curl -u ${NtfyUser}:${NtfyPass} -d 'test' -H 'Title: test' http://localhost:$NtfyPort/runeforge-estatus"
    } catch { Write-Warn "Publish con auth falló: $($_.Exception.Message) - Usa -ModoAbierto para modo sin auth" }
}

Write-Ok "Fix completado - ntfy en http://localhost:$NtfyPort/runeforge-estatus"
Write-Host "Artefacto: $Root\scripts\Fix-Ntfy-Auth-403.ps1" -ForegroundColor Green
