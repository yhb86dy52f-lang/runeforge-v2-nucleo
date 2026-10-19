# Script unificado de inicio - Runeforge v2.0
$ErrorActionPreference = "Continue"

Write-Host "Iniciando Backend Fastify (Puerto 3002)..." -ForegroundColor Green
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd C:\RUNEFORGE_V2_CORE\src\backend; npm start"

Start-Sleep -Seconds 3

Write-Host "Iniciando Relay de WhatsApp (Puerto 3198)..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd C:\RUNEFORGE_V2_CORE\src\relay; node server.mjs"

Write-Host "Servicios desplegados con éxito." -ForegroundColor Yellow
