Clear-Host
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "       RUNEFORGE V2 - INICIANDO ECOSISTEMA               " -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[*] Limpiando procesos zombis..." -ForegroundColor Yellow
Get-Process python, node, cargo, app -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

Write-Host "[*] Iniciando Whisper IA (GPU)..." -ForegroundColor Yellow
Start-Process -FilePath "C:\RUNEFORGE_V2_CORE\whisper-backend\venv\Scripts\python.exe" -ArgumentList "server.py" -WorkingDirectory "C:\RUNEFORGE_V2_CORE\whisper-backend" -WindowStyle Minimized

Write-Host "[*] Iniciando Nexus Brain (Monitor)..." -ForegroundColor Yellow
Start-Process -FilePath "python" -ArgumentList "C:\RUNEFORGE_V2_CORE\scripts\brain_hub.py" -WorkingDirectory "C:\RUNEFORGE_V2_CORE\scripts" -WindowStyle Minimized

Write-Host "[*] Iniciando Nexus Tactical (Tauri)..." -ForegroundColor Yellow
Start-Process -FilePath "cmd.exe" -ArgumentList "/c npm run tauri dev" -WorkingDirectory "C:\RUNEFORGE_V2_CORE\nexus-tactical" -WindowStyle Minimized

Write-Host "`n[*] Esperando 8 segundos a que los servicios arranquen..." -ForegroundColor Yellow
Start-Sleep -Seconds 8

Write-Host "`n[*] Verificando estado de arranque (Auditoria automatica)..." -ForegroundColor Yellow
& "C:\RUNEFORGE_V2_CORE\scripts\AUDIT.ps1"

Write-Host "`n=========================================================" -ForegroundColor Cyan
Write-Host "  [OK] ECOSISTEMA EN LINEA Y OPERATIVO." -ForegroundColor Green
Write-Host "=========================================================" -ForegroundColor Cyan
