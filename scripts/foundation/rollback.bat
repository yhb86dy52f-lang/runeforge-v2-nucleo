@echo off
set BASE=C:\RUNEFORGE_V2_CORE
set BACKUPS=%BASE%\backups
for /f "delims=" %%i in ('dir /b /o-d "%BACKUPS%\pre-cimiento-*.zip" 2^>nul') do (powershell -Command "Expand-Archive -Path '%BACKUPS%\%%i' -DestinationPath '%BASE%' -Force" & echo [OK] Rollback %%i & pause & exit /b)
