# ================================================================
# RUNEFORGE — AUTÓNOMO v2 (fix terminal crash)
# ================================================================
 $ErrorActionPreference = "Stop"
 $rootDir        = "C:\RUNEFORGE_V2_CORE"
 $backendAppDir  = Join-Path $rootDir "src\backend\app"
 $serverFile     = Join-Path $backendAppDir "src\server.js"
 $frontendFile   = Join-Path $rootDir "src\frontend\index.html"
 $logDir         = Join-Path $rootDir "data\logs"
 $logFile        = Join-Path $logDir "autonomo-runeforge-$(Get-Date -Format yyyyMMdd_HHmmss).log"
 $iphoneIP       = "100.97.117.115"
 $iphoneDNS      = "rf-iphone-nesth.tailad757b.ts.net"

 $script:logLines = New-Object System.Collections.Generic.List[string]

function Write-Log {
    param([string]$Msg, [ConsoleColor]$Color = [ConsoleColor]::Gray)
    $line = "[$(Get-Date -Format 'HH:mm:ss')] $Msg"
    $script:logLines.Add($line)
    Write-Host $line -ForegroundColor $Color
}
function Assert-Path {
    param([string]$Path, [string]$Label)
    if (-not (Test-Path $Path)) { Write-Log "[FALTA] $Label no encontrado: $Path" Red; return $false }
    Write-Log "[OK] $Label existe" Green; return $true
}
function Assert-Command {
    param([string]$Cmd)
    $c = Get-Command $Cmd -ErrorAction SilentlyContinue
    if (-not $c) { Write-Log "[FALTA] '$Cmd' no está en PATH" Red; return $false }
    Write-Log "[OK] '$Cmd' disponible ($($c.Source))" Green; return $true
}

# ===== FASE 0 — ENTORNO VERIFICADO =====
Write-Log "=== FASE 0: Verificacion de entorno ===" Cyan
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }

 $envOk = $true
 $envOk = $envOk -and (Assert-Path $rootDir       "Directorio raiz Runeforge")
 $envOk = $envOk -and (Assert-Path $backendAppDir "src\backend\app")
 $envOk = $envOk -and (Assert-Path $serverFile    "src\backend\app\src\server.js")
 $envOk = $envOk -and (Assert-Command "node")
 $envOk = $envOk -and (Assert-Command "npm")
 $envOk = $envOk -and (Assert-Command "pm2")

 $tailscaleIP = $null
try {
    $tailscaleIP = (Get-NetIPAddress -InterfaceAlias "Tailscale" -AddressFamily IPv4 -ErrorAction Stop).IPAddress
    Write-Log "[OK] IP Tailscale PC: $tailscaleIP" Green
} catch {
    Write-Log "[WARN] Tailscale no detectado. Verificacion iPhone se limita a impresion de comando." Yellow
}

if (-not $envOk) {
    Write-Log "[ABORT] Entorno incompleto. NO se toca npm ni PM2." Red
    $script:logLines | Set-Content -Path $logFile -Encoding UTF8
    exit 1
}

# ===== FASE 1 — INSTALAR env-schema + dependencias =====
Write-Log "=== FASE 1: Instalacion env-schema, @sinclair/typebox, pino-pretty ===" Cyan
Push-Location $backendAppDir
try {
    $pkgJson = Join-Path $backendAppDir "package.json"
    if (-not (Test-Path $pkgJson)) {
        Write-Log "[INIT] package.json ausente -> 'npm init -y'" Yellow
        npm init -y *>$null
        if ($LASTEXITCODE -ne 0) { throw "npm init fallo" }
    }
    Write-Log "[NPM] Instalando dependencias (~30s)..." Cyan

    # FIX 1: Redirigir output a archivo, NO capturar en variable
    $npmLogFile = Join-Path $logDir "npm-install-$(Get-Date -Format yyyyMMdd_HHmmss).log"
    npm install env-schema @sinclair/typebox pino-pretty --save --no-fund --no-audit *> "$npmLogFile"
    if ($LASTEXITCODE -ne 0) {
        $lastLines = Get-Content $npmLogFile -Tail 20
        throw "npm install fallo (exit=$LASTEXITCODE). Ultimas lineas: $($lastLines -join '`n')"
    }

    $envSchemaPath = Join-Path $backendAppDir "node_modules\env-schema\package.json"
    if (-not (Test-Path $envSchemaPath)) { throw "env-schema no aparece en node_modules tras install" }
    $envSchemaVer = (Get-Content $envSchemaPath -Raw | ConvertFrom-Json).version
    Write-Log "[OK] env-schema v$envSchemaVer instalado" Green
    Write-Log "[LOG] npm output: $npmLogFile" DarkGray
} catch {
    Write-Log "[ERROR] FASE 1: $_" Red
    Pop-Location
    $script:logLines | Set-Content -Path $logFile -Encoding UTF8
    exit 2
} finally {
    Pop-Location
}

# ===== FASE 2 — PRUEBA MANUAL node src\server.js =====
Write-Log "=== FASE 2: Prueba manual del servidor en :3100 ===" Cyan

 $portInUse = $false
try {
    $existing = Get-NetTCPConnection -LocalPort 3100 -State Listen -ErrorAction Stop
    if ($existing) {
        $portInUse = $true
        Write-Log "[WARN] Puerto 3100 ya en escucha por PID(s): $($existing.OwningProcess -join ','). Prueba manual omitida." Yellow
    }
} catch { Write-Log "[OK] Puerto 3100 libre" Green }

 $manualOk = $false
if (-not $portInUse) {
    $stdoutFile = Join-Path $logDir "server-manual-stdout.log"
    $stderrFile = Join-Path $logDir "server-manual-stderr.log"
    Push-Location $backendAppDir
    try {
        Write-Log "[MANUAL] Arrancando 'node src\server.js' en background..." Cyan
        $proc = Start-Process -FilePath "node" -ArgumentList "src\server.js" `
            -WorkingDirectory $backendAppDir `
            -RedirectStandardOutput $stdoutFile -RedirectStandardError $stderrFile `
            -PassThru -WindowStyle Hidden

        $listened = $false
        for ($i = 0; $i -lt 15; $i++) {
            Start-Sleep -Seconds 1
            if ($proc.HasExited) {
                $err = if (Test-Path $stderrFile) { (Get-Content $stderrFile -Raw).Trim() } else { "" }
                Write-Log "[ERROR] node termino prematuro (exit=$($proc.ExitCode)). STDERR: $err" Red
                break
            }
            try {
                $conn = Get-NetTCPConnection -LocalPort 3100 -State Listen -ErrorAction Stop
                if ($conn) { $listened = $true; break }
            } catch { }
        }

        if ($listened) {
            Write-Log "[OK] node escuchando :3100 (PID $($proc.Id))" Green
            try {
                $health = Invoke-RestMethod -Uri "http://localhost:3100/health" -Method GET -TimeoutSec 5
                Write-Log "[OK] /health respondio: $($health | ConvertTo-Json -Compress)" Green
                $manualOk = $true
            } catch {
                Write-Log "[WARN] /health no OK: $_" Yellow
            }
        }

        if (-not $proc.HasExited) {
            Write-Log "[MANUAL] Deteniendo PID $($proc.Id)..." Cyan
            Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
            for ($i = 0; $i -lt 5; $i++) {
                Start-Sleep -Seconds 1
                try { $still = Get-NetTCPConnection -LocalPort 3100 -State Listen -ErrorAction Stop; if (-not $still) { break } } catch { break }
            }
        }
    } catch {
        Write-Log "[ERROR] Excepcion prueba manual: $_" Red
    } finally {
        Pop-Location
    }
} else {
    $manualOk = $true
}

if (-not $manualOk) {
    Write-Log "[ABORT] Prueba manual no confirmo :3100. NO se reinicia PM2." Red
    $script:logLines | Set-Content -Path $logFile -Encoding UTF8
    exit 3
}

# ===== FASE 3 — REINICIAR PM2 =====
Write-Log "=== FASE 3: PM2 restart runeforge-backend ===" Cyan

try {
    $stillListening = Get-NetTCPConnection -LocalPort 3100 -State Listen -ErrorAction Stop
    if ($stillListening -and -not $portInUse) {
        Write-Log "[WARN] Puerto 3100 aun ocupado por PID $($stillListening.OwningProcess)." Yellow
    }
} catch { }

try {
    # FIX 2: Usar pm2 list (liviano) para verificar existencia
    $pm2List = pm2 list --no-color 2>$null | Out-String
    if ($pm2List -notmatch "runeforge-backend") {
        Write-Log "[ERROR] 'runeforge-backend' NO existe en PM2. Procesos actuales:" Red
        pm2 list --no-color 2>$null | ForEach-Object { Write-Log "[PM2] $_" DarkGray }
        Write-Log "[HINT] pm2 start src\server.js --name runeforge-backend --cwd `"$backendAppDir`"" Yellow
        $script:logLines | Set-Content -Path $logFile -Encoding UTF8
        exit 5
    }
} catch {
    Write-Log "[ERROR] 'pm2 list' fallo. ¿Daemon caido? Ejecuta 'pm2 update'." Red
    $script:logLines | Set-Content -Path $logFile -Encoding UTF8
    exit 4
}

Write-Log "[PM2] 'runeforge-backend' encontrado. Reiniciando..." Cyan
 $restartOut = (pm2 restart runeforge-backend --update-env --no-color 2>&1 | Out-String).Trim()
if ($LASTEXITCODE -ne 0) {
    Write-Log "[ERROR] pm2 restart fallo (exit=$LASTEXITCODE): $restartOut" Red
    $script:logLines | Set-Content -Path $logFile -Encoding UTF8
    exit 6
}
Start-Sleep -Seconds 3

# FIX 2b: jlist solo para extraer status, no para imprimir
 $pm2Procs2 = (pm2 jlist 2>$null | Out-String) | ConvertFrom-Json
 $target2 = $pm2Procs2 | Where-Object { $_.name -eq "runeforge-backend" }
 $status2 = if ($target2) { $target2.pm2_env.status } else { "UNKNOWN" }
Write-Log "[PM2] Estado post-restart: $status2" $(if ($status2 -eq 'online') {'Green'} else {'Red'})

 $pm2Listening = $false
for ($i = 0; $i -lt 10; $i++) {
    Start-Sleep -Seconds 1
    try { $conn = Get-NetTCPConnection -LocalPort 3100 -State Listen -ErrorAction Stop; if ($conn) { $pm2Listening = $true; break } } catch { }
}
if (-not $pm2Listening) {
    Write-Log "[ERROR] PM2 NO escucha :3100. Revisa: pm2 logs runeforge-backend --lines 50" Red
    $script:logLines | Set-Content -Path $logFile -Encoding UTF8
    exit 7
}
Write-Log "[OK] PM2 escuchando :3100" Green
try {
    $h2 = Invoke-RestMethod -Uri "http://localhost:3100/health" -Method GET -TimeoutSec 5
    Write-Log "[OK] /health via PM2: $($h2 | ConvertTo-Json -Compress)" Green
} catch { Write-Log "[WARN] /health post-PM2: $_" Yellow }

pm2 save --no-color *>$null
Write-Log "[OK] pm2 save ejecutado" Green

# ===== FASE 4 — VERIFICACION IPHONE =====
Write-Log "=== FASE 4: Conectividad iPhone (aShell) ===" Cyan
 $iphoneCmd = $null
if ($tailscaleIP) {
    $iphoneCmd = "curl -X POST http://${tailscaleIP}:3100/api/chat -H `"Content-Type: application/json`" -d '{`"message`":`"Hola desde aShell`"}'"
    Write-Log "[IPHONE] iPhone 14 Pro (RUNE):" Cyan
    Write-Log "  MagicDNS : $iphoneDNS"      White
    Write-Log "  IP       : $iphoneIP"       White
    Write-Log "  PC Tails : $tailscaleIP"    White
    Write-Log "  Comando aShell:" White
    Write-Host "  $iphoneCmd" -ForegroundColor Green
    try {
        $hT = Invoke-RestMethod -Uri "http://${tailscaleIP}:3100/health" -Method GET -TimeoutSec 5
        Write-Log "[OK] /health alcanzable via Tailscale ($tailscaleIP)." Green
    } catch {
        Write-Log "[WARN] No se alcanzo :3100 via $tailscaleIP. Revisa Windows Firewall." Yellow
        Write-Log "[HINT] New-NetFirewallRule -DisplayName 'Runeforge-3100' -Direction Inbound -LocalPort 3100 -Protocol TCP -Action Allow" Yellow
    }
} else {
    Write-Log "[SKIP] Sin IP Tailscale. Verificacion iPhone pendiente." Yellow
}

# ===== FASE 5 — RESUMEN + PORTAPAPELES =====
Write-Log "=== RESUMEN FINAL ===" Cyan
 $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
 $resumen = @"
============================================
 RUNEFORGE -- AUTONOMO v2 COMPLETADO
 $ts
============================================
[1] env-schema + @sinclair/typebox + pino-pretty: INSTALADOS
[2] Prueba manual node: OK
[3] PM2 runeforge-backend: $status2
[4] iPhone comando: $iphoneCmd
Log completo: $logFile
============================================
"@
Write-Host $resumen -ForegroundColor Cyan

# FIX 3: Portapapeles con proteccion
try {
    $resumen | Set-Clipboard
    Write-Log "[CLIPBOARD] Resumen copiado al portapapeles." Green
} catch {
    Write-Log "[WARN] Portapapeles no disponible: $_" Yellow
}

 $script:logLines | Set-Content -Path $logFile -Encoding UTF8
Write-Log "[LOG] Detalle: $logFile" Cyan
exit 0