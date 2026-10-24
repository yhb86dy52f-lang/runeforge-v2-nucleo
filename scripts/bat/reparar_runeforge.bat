@echo off
title RUNEFORGE AUTO-REPAIR SYSTEM
color 0A
echo [1/4] REPARANDO TAILSCALE...
net stop Tailscale /y >nul 2>&1
taskkill /F /IM tailscale* /T >nul 2>&1
if exist "C:\RUNEFORGE_V2_CORE\tailscale-setup-1.102.4.exe" (
    start /wait "" "C:\RUNEFORGE_V2_CORE\tailscale-setup-1.102.4.exe" /silent
)
net start Tailscale >nul 2>&1
timeout /t 3 /nobreak >nul
if exist "C:\Program Files\Tailscale\tailscale.exe" (
    "C:\Program Files\Tailscale\tailscale.exe" up --reset >nul 2>&1
)

echo [2/4] ACTUALIZANDO ECOSYSTEM.CONFIG.JS (PUERTO 3001)...
(
echo module.exports = {
echo   apps: [
echo     { 
echo       name: "runeforge-backend", 
echo       script: "./server.js", 
echo       cwd: "C:/RUNEFORGE_V2_CORE", 
echo       instances: 1, 
echo       exec_mode: "fork", 
echo       env: { PORT: 3001, NODE_ENV: "production" } 
echo     }
echo   ]
echo }
) > "C:\RUNEFORGE_V2_CORE\ecosystem.config.js"

call pm2 restart runeforge-backend --update-env >nul 2>&1

echo [3/4] CONSOLIDANDO GIT LOCAL...
cd /d "C:\RUNEFORGE_V2_CORE"
git add . >nul 2>&1
git commit -m "feat(core): consolidacion V2.6.2" >nul 2>&1

echo [4/4] EJECUTANDO WATCHDOG...
pwsh.exe -NoLogo -NoExit -ExecutionPolicy Bypass -File "C:\RUNEFORGE_V2_CORE\scripts\rf_init.ps1"
