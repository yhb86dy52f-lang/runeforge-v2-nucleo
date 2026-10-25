@echo off
title RUNEFORGE TACTICAL - LANZADOR
echo [*] Iniciando Nexus Tactical (Tauri + Vite)...
cd /d "C:\RUNEFORGE_V2_CORE\nexus-tactical"
start /min cmd /c "npm run tauri dev"
exit