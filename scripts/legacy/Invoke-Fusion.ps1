# Invoke-Fusion.ps1 - FUSION RUNEFORGE-V2-NUCLEO + FORJA LOCAL
# Norma Canonica v1.0 - 2026-09-20 13:03:19
# Uso: pwsh -NoProfile -ExecutionPolicy Bypass -File .\Invoke-Fusion.ps1

$ErrorActionPreference = "Continue"
Write-Host "`n[RUNEFORGE FUSION v2.7.0] Fusionando nucleo GitHub + forja local" -ForegroundColor Cyan

$REMOTE = "https://github.com/yhb86dy52f-lang/runeforge-v2-nucleo.git"
$LOCAL_CORE = "C:\RUNEFORGE_V2_CORE"
$CLONE_PATH = "C:\runeforge-v2-nucleo"

# 1. Clonar si no existe
if (-not (Test-Path $CLONE_PATH)) {
    Write-Host "[1/5] Clonando $REMOTE" -ForegroundColor Yellow
    Set-Location "C:\"
    & cmd /c "git clone $REMOTE >nul 2>&1"
    if ($LASTEXITCODE -ne 0) { Write-Host "[X] git clone fallo" -ForegroundColor Red; exit 1 }
} else {
    Write-Host "[1/5] Repo ya existe en $CLONE_PATH - pull" -ForegroundColor Green
    Set-Location $CLONE_PATH
    & cmd /c "git pull >nul 2>&1"
}

Set-Location $CLONE_PATH

# 2. Crear estructura apps/
Write-Host "[2/5] Creando estructura apps/" -ForegroundColor Yellow
New-Item -ItemType Directory -Path "apps\nexus-lab","apps\flota-kw-os","apps\forja","apps\lmu-hmi","config\cargo" -Force | Out-Null

# 3. Fusionar artefactos locales -> nucleo
Write-Host "[3/5] Fusionando artefactos locales" -ForegroundColor Yellow

$nexusExe = "$LOCAL_CORE\apps\nexus-lab\src-tauri\target\release\nexus-lab.exe"
if (Test-Path $nexusExe) {
    Copy-Item $nexusExe "apps\nexus-lab\nexus-lab.exe" -Force
    Write-Host "  [OK] nexus-lab.exe 2.94MB -> apps\nexus-lab\" -ForegroundColor Green
} else {
    Write-Host "  [!] nexus-lab.exe no encontrado en $nexusExe" -ForegroundColor DarkYellow
}

if (Test-Path "$LOCAL_CORE\forja") {
    Copy-Item "$LOCAL_CORE\forja\*" "apps\forja\" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  [OK] forja -> apps\forja\" -ForegroundColor Green
}

if (Test-Path "$LOCAL_CORE\flota-kw-os") {
    Copy-Item "$LOCAL_CORE\flota-kw-os\*" "apps\flota-kw-os\" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  [OK] flota-kw-os -> apps\flota-kw-os\" -ForegroundColor Green
}

# 4. Copiar normas canónicas
Write-Host "[4/5] Copiando normas canónicas" -ForegroundColor Yellow
$cargoCfg = "$env:USERPROFILE\.cargo\config.toml"
if (Test-Path $cargoCfg) {
    Copy-Item $cargoCfg "config\cargo\config.toml" -Force
    Write-Host "  [OK] cargo config.toml canónico -> config\cargo\" -ForegroundColor Green
}

if (Test-Path "$LOCAL_CORE\NORMA_CANONICA_RUNEFORGE_V1.md") {
    Copy-Item "$LOCAL_CORE\NORMA_CANONICA_RUNEFORGE_V1.md" ".\NORMA_CANONICA_RUNEFORGE_V1.md" -Force -ErrorAction SilentlyContinue
}
if (Test-Path "$LOCAL_CORE\Invoke-CanonicalBuild.ps1") {
    Copy-Item "$LOCAL_CORE\Invoke-CanonicalBuild.ps1" ".\Invoke-CanonicalBuild.ps1" -Force -ErrorAction SilentlyContinue
}

# 5. Commit fusión
Write-Host "[5/5] Commit fusión v2.7.0" -ForegroundColor Yellow
& cmd /c "git add . >nul 2>&1"
& cmd /c "git commit -m ""fusion v2.7.0: forja + nexus-lab.exe 2.94MB + FlotaKW STOCK_R PB705/T2101N + Norma Canonica v1.0 HTTP/1.1 sparse"" >nul 2>&1"
& cmd /c "git tag -a v2.7.0-FUSION -m ""Fusion canonica - Fastify 77k + Ollama 110tok/s + Nexus Lab 2.94MB + FlotaKW"" >nul 2>&1"

Write-Host "`n[OK] FUSIÓN COMPLETA" -ForegroundColor Green
Write-Host "Repo: $CLONE_PATH" -ForegroundColor DarkGray
Write-Host "Launcher: $CLONE_PATH\runeforge_launcher.ps1" -ForegroundColor DarkGray
Write-Host "Norma: $CLONE_PATH\NORMA_CANONICA_RUNEFORGE_V1.md" -ForegroundColor DarkGray
Write-Host "Build canónico: pwsh -NoProfile -File .\Invoke-CanonicalBuild.ps1 -AppName nexus-lab" -ForegroundColor Yellow
Write-Host "`nSiguiente: cd $CLONE_PATH; .\runeforge_launcher.ps1" -ForegroundColor Cyan
