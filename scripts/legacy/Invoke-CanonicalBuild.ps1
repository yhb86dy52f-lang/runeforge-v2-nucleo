# =====================================================================
# Invoke-CanonicalBuild.ps1 - NORMA CANONICA RUNEFORGE v1.0
# Uso: pwsh -NoProfile -ExecutionPolicy Bypass -File .\Invoke-CanonicalBuild.ps1 -AppName nexus-lab
#      pwsh -NoProfile -ExecutionPolicy Bypass -File .\Invoke-CanonicalBuild.ps1 -AppName lmu-hmi -ProductName "LMU-2630 HMI"
# =====================================================================
param(
    [string]$AppName = "nexus-lab",
    [string]$ProductName = "",
    [string]$BasePath = "C:\RUNEFORGE_V2_CORE\apps"
)

$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# --- NORMA 1: Entorno ---
$env:NODE_OPTIONS = "--openssl-legacy-provider --max-old-space-size=4096"
$env:NODE_TLS_REJECT_UNAUTHORIZED = "0"
$env:CARGO_HTTP_MULTIPLEXING = "false"
$env:CARGO_NET_RETRY = "10"
$env:CARGO_HTTP_TIMEOUT = "180"
$env:CARGO_REGISTRIES_CRATES_IO_PROTOCOL = "sparse"
$env:Path = "$env:USERPROFILE\.cargo\bin;$env:Path"

if (-not $ProductName) { $ProductName = $AppName }

$APP = Join-Path $BasePath $AppName
Write-Host "`n[RUNEFORGE CANON v1.0] Build $AppName -> $ProductName" -ForegroundColor Cyan
Write-Host "[PATH] $APP" -ForegroundColor DarkGray

# --- NORMA 2: Config cargo canónica ---
$cargoCfgDir = "$env:USERPROFILE\.cargo"
New-Item -ItemType Directory -Path $cargoCfgDir -Force | Out-Null
@'
[http]
multiplexing = false
timeout = 180
low-speed-limit = 5
[net]
retry = 10
git-fetch-with-cli = true
[registries.crates-io]
protocol = "sparse"
'@ | Set-Content "$cargoCfgDir\config.toml" -Encoding UTF8
Write-Host "[OK] $cargoCfgDir\config.toml canónico" -ForegroundColor Green

# --- NORMA 3: Limpieza ---
Set-Location $APP
Remove-Item "$APP\src-tauri\Cargo.lock" -Force -ErrorAction SilentlyContinue
Write-Host "[OK] Cargo.lock limpiado" -ForegroundColor Green

# --- NORMA 4: Build con fallback ---
Set-Location "$APP\src-tauri"
$ok = $false
for ($i=1; $i -le 2; $i++) {
    if ($i -eq 1) {
        Write-Host "[Intento 1] CDN oficial crates.io HTTP/1.1" -ForegroundColor Yellow
    } else {
        Write-Host "[Intento 2] Espejo USTC" -ForegroundColor Yellow
        @'
[http]
multiplexing = false
timeout = 180
[net]
retry = 10
git-fetch-with-cli = true
[source.crates-io]
replace-with = "ustc"
[source.ustc]
registry = "sparse+https://mirrors.ustc.edu.cn/crates.io-index/"
'@ | Set-Content "$cargoCfgDir\config.toml" -Encoding UTF8
    }
    & cmd /c "cargo build --release > build.log 2>&1"
    Get-Content "build.log" -Tail 20 | Where-Object { $_ -match "Compiling|Finished|error|warning: spurious" } | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
    $exe = "$APP\src-tauri\target\release\$AppName.exe"
    if ($LASTEXITCODE -eq 0 -and (Test-Path $exe)) {
        $ok = $true
        $size = [math]::Round((Get-Item $exe).Length/1MB,2)
        Write-Host "[OK] $exe ($size MB)" -ForegroundColor Green
        break
    }
    Write-Host "[!] Fallo intento $i" -ForegroundColor DarkYellow
    Start-Sleep -Seconds 3
}

if (-not $ok) { Write-Host "[X] Ambos intentos fallaron. Revisa build.log" -ForegroundColor Red; exit 1 }

# --- NORMA 5: Restaurar config sin espejo ---
@'
[http]
multiplexing = false
timeout = 180
[net]
retry = 10
git-fetch-with-cli = true
[registries.crates-io]
protocol = "sparse"
'@ | Set-Content "$cargoCfgDir\config.toml" -Encoding UTF8

Write-Host "[RUNEFORGE] Build canónico completado: $AppName" -ForegroundColor Green
Write-Host "[NORMA] v1.0 2026-09-20 13:03:19 - 2.94MB - 429 crates" -ForegroundColor DarkGray
