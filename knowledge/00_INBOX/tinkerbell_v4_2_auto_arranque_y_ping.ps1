# ==============================================================================
# RUNEFORGE RELAY - AUTO-ARRANQUE Y PING COGNITIVO
# ==============================================================================
$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$CanonicalDir = "C:\RUNEFOGE_PRO\runeforge-relay"
Set-Location $CanonicalDir

Write-Host "[*] 1. Levantando servidor en una ventana paralela aislada..." -ForegroundColor Cyan

# Abre una nueva ventana de PowerShell que ejecuta el servidor y no se cierra si hay error (-NoExit)
Start-Process powershell -ArgumentList "-NoExit -Command `"cd $CanonicalDir; Write-Host '[*] INICIANDO NÚCLEO...' -ForegroundColor Yellow; node server.js`""

Write-Host "[*] 2. Esperando 5 segundos a que el motor Fastify y Ollama sincronicen..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

Write-Host "[*] 3. Disparando Ping Cognitivo (Pregunta Trampa)..." -ForegroundColor Cyan

# El Ping
$body = @{ 
    message = "Ingeniero, ¿qué algoritmo debemos usar para las tablas de Wialon y cuál es el error máximo tolerable en los extremos?" 
} | ConvertTo-Json

try {
    $respuesta = Invoke-RestMethod -Uri "http://127.0.0.1:8080/api/ai/chat" -Method Post -Body $body -ContentType "application/json"
    
    Write-Host "`n[✅] RESPUESTA DE LA IA:" -ForegroundColor Green
    Write-Host "---------------------------------------------------"
    Write-Host $respuesta.response -ForegroundColor White
    Write-Host "---------------------------------------------------`n"
} catch {
    Write-Host "`n[❌] ERROR: El servidor se apagó inmediatamente." -ForegroundColor Red
    Write-Host "👉 Revisa la NUEVA ventana azul que se abrió. Debe haber un error rojo de Node.js ahí (tal vez falte 'npm install'). Dime qué dice esa ventana." -ForegroundColor Yellow
}