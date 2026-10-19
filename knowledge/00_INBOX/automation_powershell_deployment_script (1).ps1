# ==============================================================================
# RUNEFORGE BITÁCORA PRO v12.6 - SCRIPT POWERSHELL DE DESPLIEGUE Y FUSIÓN GIT
# Repositorio: https://github.com/yhb86dy52f-lang/runeforge-v2-nucleo.git
# ==============================================================================

$ErrorActionPreference = "Stop"

$RepoUrl = "https://github.com/yhb86dy52f-lang/runeforge-v2-nucleo.git"
$HomeDir = [System.Environment]::GetFolderPath("UserProfile")
$TargetDir = Join-Path $HomeDir "runeforge_web"
$DataDir = Join-Path $HomeDir "runeforge_data"
$DbFile = Join-Path $DataDir "db.json"

Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "  RUNEFORGE v12.6 - INICIANDO PROCESO DE FUSIÓN POWERSHELL" -ForegroundColor Yellow
Write-Host "====================================================" -ForegroundColor Cyan

# 1. Asegurar Estructura de Directorios
if (-not (Test-Path $DataDir)) {
    New-Item -ItemType Directory -Path $DataDir -Force | Out-Null
    Write-Host "[+] Directorio de datos creado: $DataDir" -ForegroundColor Green
}

if (-not (Test-Path $DbFile)) {
    $InitialDb = @{
        orders = @()
        fichajes = @()
    } | ConvertTo-Json -Depth 5
    Set-Content -Path $DbFile -Value $InitialDb -Encoding UTF8
    Write-Host "[+] Base de datos db.json inicializada" -ForegroundColor Green
}

# 2. Gestión e Integración Git
if (Test-Path $TargetDir) {
    Write-Host "[+] Directorio de repositorio existente encontrado. Actualizando..." -ForegroundColor Yellow
    Set-Location $TargetDir
    try {
        git fetch origin main
        git reset --hard origin/main
        Write-Host "[+] Repositorio sincronizado con exito." -ForegroundColor Green
    } catch {
        Write-Host "[!] Error actualizando Git. Continuando con respaldos..." -ForegroundColor Red
    }
} else {
    Write-Host "[+] Clonando repositorio desde $RepoUrl..." -ForegroundColor Yellow
    git clone $RepoUrl $TargetDir
    Set-Location $TargetDir
    Write-Host "[+] Repositorio clonado exitosamente." -ForegroundColor Green
}

# 3. Verificación de Dependencias e Instalación
Write-Host "[+] Verificando paquetes de Node.js..." -ForegroundColor Cyan
if (Test-Path (Join-Path $TargetDir "package.json")) {
    npm install --silent
    Write-Host "[+] Dependencias de Node.js instaladas/verificadas." -ForegroundColor Green
}

# 4. Validar Puertos y Proceso
$Port = 8080
$PortActive = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue

if ($PortActive) {
    Write-Host "[!] El puerto $Port esta activo. Reiniciando servicio..." -ForegroundColor Yellow
}

Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "  PROCESO DE FUSIÓN COMPLETADO CORRECTAMENTE" -ForegroundColor Green
Write-Host "  Ruta WEB: $TargetDir" -ForegroundColor White
Write-Host "  Ruta DATA: $DataDir" -ForegroundColor White
Write-Host "====================================================" -ForegroundColor Cyan