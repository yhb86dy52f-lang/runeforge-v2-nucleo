@echo off
echo ⚡ LEVANTANDO EL NÚCLEO RUNEFORGE...
cd /d C:\RUNEFORGE_V2_CORE
start /min ollama serve
start /min pm2 start ecosystem.config.js
echo ✅ SISTEMA AMARRADO Y EN LÍNEA.
echo    👉 Forge UI: http://localhost:3100/
echo    👉 PWA Offline: http://localhost:3100/pwa