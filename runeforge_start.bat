@echo off
echo Iniciando Runeforge Daemon...
cd /d C:\RUNEFORGE_V2_CORE\daemon
set PYTHONUNBUFFERED=1
set OLLAMA_NUM_GPU=1
node server.js
pause
