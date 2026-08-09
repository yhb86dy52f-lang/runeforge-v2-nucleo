# ============================================================
# CORRECCIÓN DEFINITIVA – INSTALACIÓN Y PUESTA EN MARCHA
# ============================================================
# Este script no asume nada: verifica cada recurso antes de actuar.
# ============================================================

$ErrorActionPreference = "Stop"

# Rutas base (ajusta si es necesario)
$backendRoot = "C:\RUNEFORGE_V2_CORE\src\backend"
$relayRoot   = "C:\RUNEFORGE_V2_CORE\src\relay"

# ---- 1. Verificación de existencia ----
if (-not (Test-Path $backendRoot)) {
    Write-Host "❌ No existe $backendRoot. Creándola..." -ForegroundColor Red
    New-Item -ItemType Directory -Path $backendRoot -Force | Out-Null
}
if (-not (Test-Path $relayRoot)) {
    Write-Host "❌ No existe $relayRoot. Creándola..." -ForegroundColor Red
    New-Item -ItemType Directory -Path $relayRoot -Force | Out-Null
}

# ---- 2. Detectar punto de entrada del backend ----
$backendEntry = $null
$backendAppDir = Join-Path $backendRoot "app"
if (Test-Path (Join-Path $backendAppDir "src\server.js")) {
    $backendEntry = "app\src\server.js"
    Write-Host "✅ Backend: punto de entrada detectado en app\src\server.js" -ForegroundColor Green
} elseif (Test-Path (Join-Path $backendRoot "src\server.js")) {
    $backendEntry = "src\server.js"
    Write-Host "✅ Backend: punto de entrada detectado en src\server.js" -ForegroundColor Green
} else {
    Write-Host "❌ No se encontró un punto de entrada para el backend." -ForegroundColor Red
    exit 1
}

# ---- 3. Detectar punto de entrada del relay ----
$relayEntry = $null
if (Test-Path (Join-Path $relayRoot "server.js")) {
    $relayEntry = "server.js"
    Write-Host "✅ Relay: punto de entrada detectado en server.js" -ForegroundColor Green
} elseif (Test-Path (Join-Path $relayRoot "src\server.mjs")) {
    $relayEntry = "src\server.mjs"
    Write-Host "✅ Relay: punto de entrada detectado en src\server.mjs" -ForegroundColor Green
} else {
    Write-Host "❌ No se encontró un punto de entrada para el relay." -ForegroundColor Red
    exit 1
}

# ---- 4. Instalar dependencias ----
function Install-Dependencies {
    param($path)
    Write-Host "📦 Instalando dependencias en $path ..." -ForegroundColor Cyan
    Push-Location $path
    try {
        npm install --production
        if ($LASTEXITCODE -ne 0) {
            Write-Host "⚠️ Falló la instalación en $path. Revisa el package.json." -ForegroundColor Yellow
        } else {
            Write-Host "✅ Dependencias instaladas en $path." -ForegroundColor Green
        }
    } catch {
        Write-Host "❌ Error ejecutando npm en $path : $_" -ForegroundColor Red
    } finally {
        Pop-Location
    }
}

# Instalar en el directorio del backend (si existe package.json)
$backendPackage = Join-Path $backendRoot "package.json"
if (-not (Test-Path $backendPackage)) {
    # Buscar dentro de app
    $backendPackage = Join-Path $backendRoot "app\package.json"
    if (Test-Path $backendPackage) {
        Install-Dependencies -path (Join-Path $backendRoot "app")
    } else {
        Write-Host "❌ No se encontró package.json en el backend." -ForegroundColor Red
    }
} else {
    Install-Dependencies -path $backendRoot
}

# Instalar en el relay
$relayPackage = Join-Path $relayRoot "package.json"
if (Test-Path $relayPackage) {
    Install-Dependencies -path $relayRoot
} else {
    Write-Host "❌ No se encontró package.json en el relay." -ForegroundColor Red
}

# ---- 5. Crear archivos .env (si no existen) ----
function Ensure-EnvFile {
    param($targetDir, $exampleFile = ".env.example", $defaultContent = "")
    $envPath = Join-Path $targetDir ".env"
    if (Test-Path $envPath) {
        Write-Host "✅ .env ya existe en $targetDir" -ForegroundColor Green
        return
    }
    $examplePath = Join-Path $targetDir $exampleFile
    if (Test-Path $examplePath) {
        Copy-Item -Path $examplePath -Destination $envPath -Force
        Write-Host "✅ Copiado $exampleFile a .env en $targetDir" -ForegroundColor Green
    } else {
        # Crear un .env mínimo
        $defaultContent | Out-File -FilePath $envPath -Encoding UTF8
        Write-Host "✅ Creado .env básico en $targetDir" -ForegroundColor Yellow
    }
}

# Backend: .env en app (si existe) o en raíz
$backendEnvDir = if (Test-Path (Join-Path $backendRoot "app\.env.example")) {
    Join-Path $backendRoot "app"
} elseif (Test-Path (Join-Path $backendRoot ".env.example")) {
    $backendRoot
} else {
    $backendRoot  # no hay ejemplo, se creará vacío
}
Ensure-EnvFile -targetDir $backendEnvDir -defaultContent "# Backend environment`nPORT=3000`nNODE_ENV=production"

# Relay: .env en raíz
Ensure-EnvFile -targetDir $relayRoot -defaultContent "# Relay environment`nPORT=3198`nNODE_ENV=production"

# ---- 6. Iniciar servicios ----
function Start-Service {
    param($name, $path, $entry, $port)
    Write-Host "🚀 Iniciando $name en $path\$entry (puerto $port)..." -ForegroundColor Cyan
    $fullPath = Join-Path $path $entry
    if (-not (Test-Path $fullPath)) {
        Write-Host "❌ No se encuentra $fullPath" -ForegroundColor Red
        return $false
    }
    # Verificar si pm2 está disponible
    $pm2Available = Get-Command pm2 -ErrorAction SilentlyContinue
    if ($pm2Available) {
        # Usar PM2
        $proc = pm2 start $fullPath --name $name -- --port $port 2>&1
        Write-Host "✅ $name iniciado con PM2" -ForegroundColor Green
        return $true
    } else {
        # Usar Start-Process en segundo plano
        $proc = Start-Process -FilePath "node" -ArgumentList $fullPath --port $port -PassThru -WindowStyle Hidden
        Write-Host "✅ $name iniciado con Start-Process (PID $($proc.Id))" -ForegroundColor Green
        return $true
    }
}

# Iniciar backend (usar el puerto 3000 por defecto)
$backendPort = 3000
Start-Service -name "runeforge-backend" -path $backendRoot -entry $backendEntry -port $backendPort

# Iniciar relay (puerto 3198)
$relayPort = 3198
Start-Service -name "runeforge-relay" -path $relayRoot -entry $relayEntry -port $relayPort

# ---- 7. Verificación de puertos ----
Write-Host "`n📋 Verificando puertos..." -ForegroundColor Magenta
$ports = @($backendPort, $relayPort, 11434)  # 11434 es Ollama
foreach ($p in $ports) {
    $conn = Test-NetConnection -ComputerName localhost -Port $p -ErrorAction SilentlyContinue
    if ($conn.TcpTestSucceeded) {
        Write-Host "✅ Puerto $p : ACCESIBLE" -ForegroundColor Green
    } else {
        Write-Host "❌ Puerto $p : NO ACCESIBLE" -ForegroundColor Red
    }
}

# ---- 8. Resumen final ----
Write-Host "`n✅ CORRECCIÓN COMPLETADA" -ForegroundColor Green
Write-Host "📂 Backend: $backendRoot\$backendEntry" -ForegroundColor Cyan
Write-Host "📂 Relay:   $relayRoot\$relayEntry" -ForegroundColor Cyan
Write-Host "🔍 Los servicios deberían estar corriendo. Revisa los logs si algo falla." -ForegroundColor Yellow
Write-Host "💡 Puedes ver los procesos con: Get-Process -Name node" -ForegroundColor Gray