<#
    RUNEFORGE - WATCHDOG AUTÓNOMO
    Se ejecuta en segundo plano cada 5 minutos. Verifica y reactiva Ollama y Fastify.
#>
$logFile = "C:\RUNEFORGE_V2_CORE\logs\watchdog.log"
$projectRoot = "C:\RUNEFORGE_V2_CORE"

# Función para escribir logs
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $logFile -Append -Encoding utf8
}

Write-Log "=== INICIANDO WATCHDOG ==="

# 1. Verificar Ollama (puerto 11434)
try {
    $null = Invoke-WebRequest -Uri "http://localhost:11434/api/tags" -Method GET -TimeoutSec 2 -ErrorAction Stop
    Write-Log "[OK] Ollama está ONLINE."
} catch {
    Write-Log "[FAIL] Ollama está OFFLINE. Reactivando..."
    Stop-Process -Name ollama -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Start-Process -FilePath "ollama.exe" -ArgumentList "serve" -WindowStyle Hidden
    Start-Sleep -Seconds 5
    Write-Log "[INFO] Comando 'ollama serve' ejecutado."
}

# 2. Verificar Fastify (puerto 3100)
try {
    $null = Invoke-WebRequest -Uri "http://127.0.0.1:3100" -Method GET -TimeoutSec 3 -ErrorAction Stop
    Write-Log "[OK] Fastify está ONLINE."
} catch {
    Write-Log "[FAIL] Fastify está OFFLINE. Reactivando..."
    # Matar procesos zombis de Node en puerto 3100
    Get-Process -Name node -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -match "3100" } | Stop-Process -Force
    Start-Sleep -Seconds 2
    # Lanzar npm start
    $scriptBlock = "Set-Location '$projectRoot'; npm start"
    Start-Process pwsh.exe -ArgumentList "-NoExit -Command `"$scriptBlock`"" -WindowStyle Hidden
    Start-Sleep -Seconds 10
    Write-Log "[INFO] Backend reiniciado."
}

Write-Log "=== WATCHDOG FINALIZADO ==="
