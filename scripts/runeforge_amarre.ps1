# ============================================================
# RUNEFORGE AMARRE - Protocolo de Inicio Blindado (CORREGIDO)
# ============================================================
Write-Host "
╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  ⚡ NÚCLEO RUNEFORGE - PROTOCOLO DE AMARRE ACTIVO      ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

$corePath = "C:\RUNEFORGE_V2_CORE"

# 1. Crear carpeta de logs si no existe
if (-not (Test-Path "$corePath\logs")) { New-Item -ItemType Directory -Path "$corePath\logs" -Force | Out-Null }

# 2. Resetear todos los procesos de PM2
Write-Host "[*] Aplicando reinicio en seco de PM2..." -ForegroundColor Yellow
pm2 delete all

# 3. Iniciar desde el candado de configuración (USANDO LA RUTA CORRECTA)
Write-Host "[*] Montando arquitectura inmutable desde ecosystem.config.js..." -ForegroundColor Yellow
pm2 start "$corePath\ecosystem.config.js"

# 4. Esperar 3 segundos para que los procesos se estabilicen
Start-Sleep -Seconds 3

# 5. Auto-diagnóstico de puertos
Write-Host "[🔍] Verificando servicios..." -ForegroundColor Yellow
$puertos = @(3100, 3198, 11434)
foreach ($puerto in $puertos) {
    $test = Test-NetConnection -ComputerName localhost -Port $puerto -WarningAction SilentlyContinue
    if ($test.TcpTestSucceeded) {
        Write-Host "  ✅ Servicio en puerto $puerto ACCESIBLE" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Servicio en puerto $puerto FALLIDO" -ForegroundColor Red
    }
}

Write-Host "
[✅] ENTORNO AMARRADO Y ESTABLE." -ForegroundColor Green
Write-Host "    👉 Forge UI: http://localhost:3100/" -ForegroundColor White
Write-Host "    👉 PWA Offline: http://localhost:3100/pwa" -ForegroundColor White
Write-Host "
[*] Para ver el estado de los procesos en vivo, usa: pm2 monit" -ForegroundColor Cyan
