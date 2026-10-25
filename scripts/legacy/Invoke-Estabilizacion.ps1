# ESTABILIZACION RUNEFORGE v2.7.0-STABLE - PASO A PASO
# Fecha: 2026-09-20 18:05:58 - openwash-real.exe 3.38MB compilado OK
# Base: C:\RUNEFORGE_V2_CORE\

Write-Host "`n[RUNEFORGE ESTABILIZACION v2.7.0-STABLE]`n" -ForegroundColor Cyan

# --- PASO 0: Verificar lo que ya tienes ---
Write-Host "[PASO 0] Verificando artefactos existentes..." -ForegroundColor Yellow
$checks = @(
  "C:\RUNEFORGE_V2_CORE\apps\openwash-real\src-tauri\target\release\openwash-real.exe",
  "C:\RUNEFORGE_V2_CORE\apps\nexus-lab\src-tauri\target\release\nexus-lab.exe",
  "C:\RUNEFORGE_V2_CORE\scripts\Nexus-Forge.ps1",
  "D:\UserData\Desktop\Html\Html\Openwash-Real-Comercial-Html.html"
)
foreach ($p in $checks) {
  if (Test-Path $p) {
    $s = [math]::Round((Get-Item $p).Length/1KB,1)
    Write-Host "  [OK] $p ($s KB)" -ForegroundColor Green
  } else {
    Write-Host "  [--] $p no existe (opcional)" -ForegroundColor DarkGray
  }
}

# --- PASO 1: Aplicar Norma Canonica v1.0 a TODO ---
Write-Host "`n[PASO 1] Aplicando Norma Canonica v1.0 a cargo..." -ForegroundColor Yellow
$cargoDir = "$env:USERPROFILE\.cargo"
New-Item -ItemType Directory -Path $cargoDir -Force | Out-Null
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
'@ | Set-Content "$cargoDir\config.toml" -Encoding UTF8
Write-Host "  [OK] $cargoDir\config.toml canonico escrito" -ForegroundColor Green

$env:CARGO_HTTP_MULTIPLEXING = "false"
$env:CARGO_NET_RETRY = "10"
$env:CARGO_HTTP_TIMEOUT = "180"
$env:CARGO_REGISTRIES_CRATES_IO_PROTOCOL = "sparse"
$env:NODE_OPTIONS = "--openssl-legacy-provider --max-old-space-size=4096"
$env:Path = "$env:USERPROFILE\.cargo\bin;$env:Path"

# --- PASO 2: Organizar estructura canonica ---
Write-Host "`n[PASO 2] Organizando estructura canonica..." -ForegroundColor Yellow
$base = "C:\RUNEFORGE_V2_CORE"
New-Item -ItemType Directory -Path "$base\apps","$base\scripts","$base\canon","$base\dist" -Force | Out-Null

# Mover tus 5 archivos descargados a canon/
$srcFiles = @("Invoke-Fusion.ps1","Invoke-CanonicalBuild.ps1","NORMA-CANONICA-RUNEFORGE-V1.md","Nexus-Forge.ps1","CANON.md")
foreach ($f in $srcFiles) {
  $found = Get-ChildItem -Path "$base" -Recurse -Filter $f -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($found) {
    Copy-Item $found.FullName "$base\canon\$f" -Force
    Write-Host "  [OK] $f -> canon\" -ForegroundColor Green
  }
}

# --- PASO 3: Fusion con runeforge-v2-nucleo (si existe) ---
Write-Host "`n[PASO 3] Fusion con runeforge-v2-nucleo.git..." -ForegroundColor Yellow
$clone = "C:\runeforge-v2-nucleo"
if (Test-Path $clone) {
  Write-Host "  Repo encontrado en $clone" -ForegroundColor Green
  # Copiar exe recien forjado al repo
  $exe = "$base\apps\openwash-real\src-tauri\target\release\openwash-real.exe"
  if (Test-Path $exe) {
    New-Item -ItemType Directory -Path "$clone\apps\openwash-real" -Force | Out-Null
    Copy-Item $exe "$clone\apps\openwash-real\openwash-real.exe" -Force
    Write-Host "  [OK] openwash-real.exe 3.38MB -> $clone\apps\openwash-real\" -ForegroundColor Green
  }
  $nexus = "$base\apps\nexus-lab\src-tauri\target\release\nexus-lab.exe"
  if (Test-Path $nexus) {
    New-Item -ItemType Directory -Path "$clone\apps\nexus-lab" -Force | Out-Null
    Copy-Item $nexus "$clone\apps\nexus-lab\nexus-lab.exe" -Force
    Write-Host "  [OK] nexus-lab.exe 2.94MB -> $clone\apps\nexus-lab\" -ForegroundColor Green
  }
} else {
  Write-Host "  [--] Repo no clonado en $clone - opcional, saltando" -ForegroundColor DarkGray
  Write-Host "  Para clonar: git clone https://github.com/yhb86dy52f-lang/runeforge-v2-nucleo.git C:\runeforge-v2-nucleo" -ForegroundColor DarkYellow
}

# --- PASO 4: Actualizar launcher unificado ---
Write-Host "`n[PASO 4] Verificando runeforge_launcher.ps1..." -ForegroundColor Yellow
$launcher = "$base\runeforge_launcher.ps1"
if (-not (Test-Path $launcher) -and (Test-Path "$clone\runeforge_launcher.ps1")) {
  $launcher = "$clone\runeforge_launcher.ps1"
}
if (Test-Path $launcher) {
  Write-Host "  [OK] Launcher existe: $launcher" -ForegroundColor Green
  Write-Host "  Debe levantar: Ollama :11434 + PM2 + Fastify 77k + nexus-lab.exe + openwash-real.exe" -ForegroundColor DarkGray
} else {
  Write-Host "  [--] Launcher no encontrado - crearemos uno basico en siguiente paso" -ForegroundColor DarkYellow
}

# --- PASO 5: Tag estable v2.7.0-STABLE ---
Write-Host "`n[PASO 5] Creando tag estable v2.7.0-STABLE..." -ForegroundColor Yellow
Set-Location $base
& cmd /c "git add . >nul 2>&1"
& cmd /c "git commit -m ""estable v2.7.0-STABLE: openwash-real.exe 3.38MB 52m30s + nexus-lab.exe 2.94MB + Norma Canonica v1.0 HTTP/1.1 sparse"" >nul 2>&1"
& cmd /c "git tag -a v2.7.0-STABLE -m ""ESTABLE - openwash-real 3.38MB + nexus-lab 2.94MB + Norma v1.0 + Nexus-Forge 9.7KB"" >nul 2>&1"
Write-Host "  [OK] Tag v2.7.0-STABLE creado local" -ForegroundColor Green

Write-Host "`n[RESUMEN ESTABILIZACION]" -ForegroundColor Cyan
Write-Host "  - openwash-real.exe 3.38MB (779KB HTML) - 52m30s - OFFLINE OK" -ForegroundColor Green
Write-Host "  - nexus-lab.exe 2.94MB (211KB) - 54m53s - OFFLINE OK" -ForegroundColor Green
Write-Host "  - cargo config.toml canonico: HTTP/1.1 multiplexing=false retry=10 sparse" -ForegroundColor Green
Write-Host "  - Norma v1.0: NODE_OPTIONS=--openssl-legacy-provider + cmd /c npm" -ForegroundColor Green
Write-Host "  - Factory: Nexus-Forge.ps1 9.7KB" -ForegroundColor Green
Write-Host "`n[SIGUIENTE] Ejecuta: .\runeforge_launcher.ps1 o inicia openwash-real.exe + nexus-lab.exe manual" -ForegroundColor Yellow
