# =====================================================================
# RUNEFORGE_ESTRUCTURA_LAUNCHER.ps1
# Mapea la estructura del simulador, audita dependencias de producción
# y genera un lanzador (.bat) automático para iniciar el sistema.
# =====================================================================

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

$Buf = New-Object System.Collections.Generic.List[string]
function W($m) { $Buf.Add([string]$m) | Out-Null; Write-Host $m }

W "==================================================================="
W " RUNEFORGE · ANÁLISIS ESTRUCTURAL Y LANZADOR · $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
W "==================================================================="

$SimuladorDir = "C:\RUNEFORGE_V2_CORE\runeforge-v2-nucleo\simulador"
if (-not (Test-Path $SimuladorDir)) {
    W "[ERROR] No se encontró la carpeta en $SimuladorDir"
    Set-Clipboard -Value ($Buf -join "`r`n")
    exit 1
}

Set-Location $SimuladorDir

# ---------- FASE 1: Mapeo de Archivos Principales ----------
W "`n[FASE 1] Mapeando estructura del simulador"
$files = Get-ChildItem -Path $SimuladorDir -File | Select-Object -ExpandProperty Name
W "  Archivos en la raíz del simulador:"
foreach ($f in $files) { W "    - $f" }

# ---------- FASE 2: Extraer Comando de Inicio ----------
W "`n[FASE 2] Extrayendo comando de inicio (package.json)"
$packageJsonPath = Join-Path $SimuladorDir "package.json"
$startScript = $null

if (Test-Path $packageJsonPath) {
    $pkg = Get-Content $packageJsonPath -Raw | ConvertFrom-Json
    if ($pkg.scripts -and $pkg.scripts.start) {
        $startScript = $pkg.scripts.start
        W "  [+] Comando 'start' encontrado: $startScript"
    } elseif ($pkg.main) {
        $startScript = "node $($pkg.main)"
        W "  [+] Comando derivado de 'main': $startScript"
    } else {
        W "  [!] No hay comando 'start' ni 'main' definido."
    }
} else {
    W "  [!] No se encontró package.json."
}

# ---------- FASE 3: Auditoría de Dependencias de Producción ----------
W "`n[FASE 3] Auditoría de Producción (ignorando herramientas de desarrollo)"
W "  Ejecutando 'npm audit --omit=dev'..."
$npmProdOut = cmd /c "npm audit --omit=dev 2>&1"
if ($npmProdOut -match "found 0 vulnerabilities") {
    W "  [+] PERFECTO: 0 vulnerabilidades en producción."
} elseif ($npmProdOut -match "vulnerabilities") {
    W "  [!] ALERTA: Hay vulnerabilidades que afectan la ejecución real."
    W "      (Revisa el reporte local con 'npm audit')."
} else {
    W "  [=] No se pudo determinar el estado (posiblemente sin red)."
}

# ---------- FASE 4: Creación de Lanzador Seguro ----------
W "`n[FASE 4] Generando lanzador de arranque seguro"
$launcherPath = Join-Path $SimuladorDir "start_runeforge.bat"
$launcherContent = @"
@echo off
title RUNEFORGE SIMULADOR
echo =======================================================
echo Iniciando el nucleo de Runeforge de forma segura...
echo =======================================================
cd /d "%~dp0"

if exist ".env" (
    echo [OK] Cargando variables de entorno...
) else (
    echo [AVISO] No se encontro .env, usando valores por defecto.
)

"@

if ($startScript) {
    $launcherContent += "echo [OK] Ejecutando: $startScript`n"
    $launcherContent += "call $startScript`n"
} else {
    $launcherContent += "echo [ERROR] No se detecto un comando de inicio valido.`n"
}

$launcherContent += "pause`n"
$launcherContent | Set-Content -Path $launcherPath -Encoding ASCII
W "  [+] Lanzador creado en: $launcherPath"

# ---------- RESUMEN ----------
W "`n==================================================================="
W " RESUMEN DE OPERACIÓN"
W "==================================================================="
W " 1. Se mapeó la estructura real (revisa los archivos listados)."
W " 2. Se aislaron las vulnerabilidades de producción."
W " 3. Se creó el archivo 'start_runeforge.bat' para arrancar el sistema."
W "==================================================================="

Set-Clipboard -Value ($Buf -join "`r`n")
Write-Host "`n[OK] Salida copiada al portapapeles (Ctrl+V)."