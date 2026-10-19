@echo off
cd /d C:\RUNEFORGE_V2_CORE
echo [RUNEFORGE] Orquestador de arranque
echo [RUNEFORGE] PM2 se encarga del backend :3100
echo [RUNEFORGE] Verificando PM2...
call pm2 resurrect
echo [RUNEFORGE] Estado:
call pm2 list
pause
