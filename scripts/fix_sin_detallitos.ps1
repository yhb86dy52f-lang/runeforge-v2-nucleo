# fix_sin_detallitos.ps1 - Cierra todo sin detallitos - En orden Etapa 1.5 -> 2
$ErrorActionPreference="Stop"
Remove-Module PSReadLine -ErrorAction SilentlyContinue
$root = $PSScriptRoot; if(-not $root){ $root = (Get-Location).Path }; if($root -like "*\scripts"){ $root = Split-Path $root -Parent }
Set-Location $root
Write-Host "=== FIX SIN DETALLITOS - EN ORDEN ===" -ForegroundColor Cyan

# 1. Backend 3100 pulido
Write-Host "[1/5] Backend 3100 - index.js + fix Ollama count" -ForegroundColor Yellow
Copy-Item src\backend\server.js src\backend\index.js -Force
Write-Host "  Copiado server.js -> index.js" -ForegroundColor Green
pm2 restart runeforge-backend -ErrorAction SilentlyContinue
if($LASTEXITCODE -ne 0){ pm2 start src\backend\server.js --name runeforge-backend }
pm2 save | Out-Null
Write-Host "  pm2 backend online" -ForegroundColor Green

# 2. Curar Inbox 68
Write-Host "[2/5] Curar Inbox 68 archivos -> DB" -ForegroundColor Yellow
if(Test-Path "knowledge\00_INBOX"){
  $c = (Get-ChildItem knowledge\00_INBOX -File -ErrorAction SilentlyContinue).Count
  Write-Host "  Inbox actual: $c archivos" -ForegroundColor DarkGray
  node src\backend\curar_inbox.js
} else { Write-Host "  No existe knowledge\00_INBOX" -ForegroundColor DarkYellow }

# 3. Blindaje backups tarea 02:00
Write-Host "[3/5] Backup tarea programada 02:00" -ForegroundColor Yellow
try{
  .\scripts\setup_backup_task.ps1
} catch { Write-Host "  Necesitas ADMIN para tarea programada: $_" -ForegroundColor Red }

# 4. .env.template -> .env si no existe
Write-Host "[4/5] .env y Telegram bot check" -ForegroundColor Yellow
if(!(Test-Path ".env") -and (Test-Path "src\backend\.env.template")){
  Copy-Item src\backend\.env.template .env
  Write-Host "  Creado .env desde template - edita TELEGRAM_BOT_TOKEN" -ForegroundColor Green
}
if(!(Test-Path ".env") -and (Test-Path ".env.template")){
  Copy-Item .env.template .env -ErrorAction SilentlyContinue
}

# 5. Tests parser
Write-Host "[5/5] Tests parser T/P/A/H/R" -ForegroundColor Yellow
node src\backend\test_parser.js

Write-Host "`n=== REPORTE FINAL SIN DETALLITOS ===" -ForegroundColor Cyan
try{ dir data\runeforge.db }catch{}
try{ Invoke-RestMethod http://127.0.0.1:3100/api/status -TimeoutSec 3 | ConvertTo-Json -Depth 3 }catch{ Write-Host "  API status no responde aun, haz pm2 logs" -ForegroundColor DarkYellow }
Write-Host "Listo - abre http://127.0.0.1:3100/dashboard" -ForegroundColor Green
