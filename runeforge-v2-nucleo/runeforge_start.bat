@echo off
echo ? LEVANTANDO EL N?CLEO RUNEFORGE (CON ENJAMBRE SWARM)...
cd /d C:\RUNEFORGE_V2_CORE
start /min ollama serve
start /min pm2 start ecosystem.config.js
echo ? SISTEMA AMARRADO Y EN L?NEA.
echo    ?? Forge UI: http://localhost:3100/forge
echo    ?? Enjambre Swarm: http://localhost:3100/forge/swarm
echo    ?? PWA Offline: http://localhost:3100/pwa
