# ================================================================
# RUNEFORGE — SCRIPT DE INICIO DE TERMINAL
# ================================================================

Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║  ⚡ NÚCLEO RUNEFORGE ACTIVO                            ║" -ForegroundColor Green
Write-Host "║  📁 Entorno: C:\RUNEFORGE_V2_CORE                     ║" -ForegroundColor Cyan
Write-Host "║  👤 Usuario: $env:USERNAME                           ║" -ForegroundColor Yellow
Write-Host "║  🌐 MagicDNS: $env:COMPUTERNAME.tailad757b.ts.net    ║" -ForegroundColor White
Write-Host "║  📡 Tailscale IP: $((Get-NetIPAddress -InterfaceAlias 'Tailscale' -AddressFamily IPv4 -ErrorAction SilentlyContinue).IPAddress) ║" -ForegroundColor Gray
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host ""

# Establecer alias y variables de entorno
$env:RUNEFORGE_HOME = "C:\RUNEFORGE_V2_CORE"
Set-Location $env:RUNEFORGE_HOME

# Comprobar estado de servicios
Write-Host "[🔍] Verificando servicios..." -ForegroundColor Cyan

$services = @(
    @{ Name = "Backend (Fastify)"; Port = 3100 },
    @{ Name = "Relay WhatsApp"; Port = 3198 },
    @{ Name = "Ollama"; Port = 11434 }
)

foreach ($svc in $services) {
    $test = Test-NetConnection -ComputerName localhost -Port $svc.Port -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
    if ($test.TcpTestSucceeded) {
        Write-Host "  ✅ $($svc.Name) - Puerto $($svc.Port) ACCESIBLE" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️ $($svc.Name) - Puerto $($svc.Port) NO ACCESIBLE" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "[RUNEFORGE] Terminal lista. Escribe 'help' para comandos." -ForegroundColor Magenta
Write-Host ""