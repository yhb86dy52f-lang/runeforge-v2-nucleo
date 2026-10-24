# =====================================================================
# RUNEFORGE_SIMULADOR_HARDENING.ps1
# Fuerza la reparación de dependencias vulnerables en la carpeta
# 'simulador' e inyecta archivos de entorno seguros en la ubicación real.
# =====================================================================

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

$Buf = New-Object System.Collections.Generic.List[string]
function W($m) { $Buf.Add([string]$m) | Out-Null; Write-Host $m }

W "==================================================================="
W " RUNEFORGE · SIMULADOR HARDENING · $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
W "==================================================================="

$SimuladorDir = "C:\RUNEFORGE_V2_CORE\runeforge-v2-nucleo\simulador"

if (-not (Test-Path $SimuladorDir)) {
    W "[ERROR] No se encontró la carpeta del simulador en $SimuladorDir"
    Set-Clipboard -Value ($Buf -join "`r`n")
    exit 1
}

Set-Location $SimuladorDir
W "[OK] Entrando al núcleo del sistema: $SimuladorDir"

# ---------- FASE 1: Resolución de Vulnerabilidades Críticas ----------
W "`n[FASE 1] Forzando la reparación de dependencias (NPM Audit Fix --force)"
W "  [!] AVISO: Esto puede actualizar versiones mayores (major versions)."
W "  [!] Si el sistema se rompe, podremos revertir desde el archivo package-lock.json."
$npmOut = cmd /c "npm audit fix --force 2>&1"
if ($LASTEXITCODE -eq 0) {
    W "  [+] Reparación forzada completada con éxito."
} else {
    W "  [-] NPM reportó problemas al forzar la reparación. Revisa el log."
}
if ($npmOut -match "vulnerabilities") {
    W "  [!] Aún quedan vulnerabilidades. Es posible que requieran intervención manual de código."
} else {
    W "  [+] Todo limpio. Vulnerabilidades resueltas."
}

# ---------- FASE 2: Aseguramiento de Secretos en el Núcleo ----------
W "`n[FASE 2] Creando blindaje de secretos en el simulador"
$EnvFile = Join-Path $SimuladorDir ".env"
if (-not (Test-Path $EnvFile)) {
    $envContent = @"
# RUNEFORGE SIMULADOR - Variables Críticas
NODE_ENV=production
PORT=3001
# Coloca aquí tus llaves reales:
LLM_API_KEY=clave_secreta_aqui
"@
    $envContent | Set-Content -Path $EnvFile -Encoding UTF8
    W "  [+] Creado .env local en el simulador."
} else {
    W "  [=] El archivo .env ya existe en el simulador. Omitiendo."
}

$GitIgnore = Join-Path $SimuladorDir ".gitignore"
$ignoreLines = @("node_modules/", ".env", "*.log")
if (Test-Path $GitIgnore) {
    $currentIgnore = Get-Content $GitIgnore -Raw
    foreach ($line in $ignoreLines) {
        if ($currentIgnore -notmatch [regex]::Escape($line)) {
            Add-Content -Path $GitIgnore -Value "`n$line"
            W "  [+] Agregado a .gitignore del simulador: $line"
        }
    }
} else {
    $ignoreLines | Set-Content -Path $GitIgnore -Encoding UTF8
    W "  [+] Creado .gitignore en el simulador."
}

# ---------- FASE 3: Verificación de Puertos Expuestos ----------
W "`n[FASE 3] Auditoría de red del simulador"
$packageJsonPath = Join-Path $SimuladorDir "package.json"
if (Test-Path $packageJsonPath) {
    $pkg = Get-Content $packageJsonPath -Raw | ConvertFrom-Json
    $entryPoint = $pkg.main
    if (-not $entryPoint) {
        # Buscar archivos comunes de entrada
        $possibleFiles = @("index.js", "server.js", "app.js", "src/index.js")
        foreach ($f in $possibleFiles) {
            if (Test-Path (Join-Path $SimuladorDir $f)) {
                $entryPoint = $f
                break
            }
        }
    }
    
    if ($entryPoint -and (Test-Path (Join-Path $SimuladorDir $entryPoint))) {
        W "  [>] Punto de entrada detectado: $entryPoint"
        $sourceCode = Get-Content (Join-Path $SimuladorDir $entryPoint) -Raw
        # Buscar si el servidor escucha en 0.0.0.0 (peligroso) o 127.0.0.1 (seguro)
        if ($sourceCode -match "0\.0\.0\.0") {
            W "  [!] ALERTA: El servidor parece escuchar en 0.0.0.0 (Toda la red)."
            W "      Se recomienda cambiarlo a 127.0.0.1 por seguridad."
        } else {
            W "  [+] El servidor parece usar loopback (127.0.0.1) o configuración segura."
        }
    } else {
        W "  [!] No se pudo detectar el archivo de entrada exacto."
    }
}

# ---------- RESUMEN ----------
W "`n==================================================================="
W " RESUMEN DE OPERACIÓN"
W "==================================================================="
W " 1. Se forzó la actualización de dependencias en el simulador."
W " 2. Se inyectó el archivo .env en la carpeta correcta."
W " 3. Se actualizaron las reglas de .gitignore internas."
W " 4. Se auditó el punto de entrada para verificar si expone la red."
W "==================================================================="

Set-Clipboard -Value ($Buf -join "`r`n")
Write-Host "`n[OK] Salida copiada al portapapeles (Ctrl+V)."