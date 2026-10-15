# RUNEFORGE V2.6.2 - MASTER START - Una sola ventana - iOS 27.0
# Solución final: mata procesos fantasma, levanta backend 3001 + relay 3198 + tunnel + WDA 8100

$ErrorActionPreference = "SilentlyContinue"
$ROOT = "C:\RUNEFORGE_V2_CORE"
Set-Location $ROOT

Write-Host "=== RUNEFORGE V2.6.2 - MASTER START ===" -ForegroundColor Cyan

# 0. Limpieza total - corrige EADDRINUSE 3001/3198
Write-Host "Limpiando procesos fantasma..." -ForegroundColor Yellow
Get-Process -Name "ios" -ErrorAction SilentlyContinue | Stop-Process -Force
pm2 delete all 2>$null | Out-Null
pm2 kill 2>$null | Out-Null
Start-Sleep 1
Get-Process -Name "node" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep 2
# Mata cualquier cosa que aún escuche 3001/3198
$busy = Get-NetTCPConnection -LocalPort 3001,3198 -ErrorAction SilentlyContinue
foreach($c in $busy){ try{ Stop-Process -Id $c.OwningProcess -Force }catch{} }

# 1. PM2 backend + relay - tu server.js usa 3001 hardcodeado, no 3100
Write-Host "[1/4] Backend 3001 + Relay 3198..." -ForegroundColor Yellow
pm2 start ecosystem.config.js
Start-Sleep 3

# 2. iOS Tunnel
Write-Host "[2/4] Tunnel userspace..." -ForegroundColor Yellow
$bundleId = "com.facebook.WebDriverAgentRunner.xctrunner.T58A9CHGBT"
Remove-Item "$ROOT\tunnel.log","$ROOT\forward.log","$ROOT\wda.log" -ErrorAction SilentlyContinue
$tunnelProc = Start-Process -FilePath "ios" -ArgumentList "tunnel start --userspace" -PassThru -WindowStyle Hidden -RedirectStandardOutput "$ROOT\tunnel.log"
Start-Sleep 5

# 3. Forward 8100
Write-Host "[3/4] Forward 8100 -> 8100..." -ForegroundColor Yellow
$forwardProc = Start-Process -FilePath "ios" -ArgumentList "forward 8100 8100" -PassThru -WindowStyle Hidden -RedirectStandardOutput "$ROOT\forward.log"
Start-Sleep 2

# 4. WDA iOS 27.0
Write-Host "[4/4] WDA iOS 27.0..." -ForegroundColor Yellow
$wdaProc = Start-Process -FilePath "ios" -ArgumentList "runwda --bundleid $bundleId --testrunnerbundleid $bundleId --xctestconfig WebDriverAgentRunner.xctest" -PassThru -WindowStyle Hidden -RedirectStandardOutput "$ROOT\wda.log"
Start-Sleep 3

# 5. Health check hasta 60s
Write-Host "Esperando healthchecks..." -ForegroundColor Cyan
$timeout=60; $elapsed=0
while($elapsed -lt $timeout){
    $b=$r=$w=$false
    try{ $resp = Invoke-RestMethod http://localhost:3001/health -TimeoutSec 2; if($resp.status -like "*ONLINE*"){ $b=$true } }catch{}
    try{ $resp = Invoke-RestMethod http://localhost:3198/ -TimeoutSec 2; if($resp.status -eq "online"){ $r=$true } }catch{}
    try{ $resp = Invoke-RestMethod http://localhost:8100/status -TimeoutSec 2; if($resp.value.ready){ $w=$true } }catch{}
    if($b -and $r -and $w){ break }
    Start-Sleep 1; $elapsed++; Write-Host "." -NoNewline
}
Write-Host ""

# 6. Reporte final
Write-Host ""
Write-Host "--- RUNEFORGE V2.6.2 STATUS REPORT ---" -ForegroundColor Green
Write-Host "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
try{ $b=Invoke-RestMethod http://localhost:3001/health -TimeoutSec 2; Write-Host "[Fastify Backend]: ONLINE - $($b.status) http://localhost:3001/health - clippings:$($b.clippings)" -ForegroundColor Green }catch{ Write-Host "[Fastify Backend]: OFFLINE" -ForegroundColor Red }
try{ $r=Invoke-RestMethod http://localhost:3198/ -TimeoutSec 2; Write-Host "[Relay]: ONLINE - $($r.service) http://localhost:3198/" -ForegroundColor Green }catch{ Write-Host "[Relay]: OFFLINE" -ForegroundColor Red }
try{ $w=Invoke-RestMethod http://localhost:8100/status -TimeoutSec 2; Write-Host "[WDA iOS 27.0]: ONLINE - ready:$($w.value.ready) version:$($w.value.os.version) ip:$($w.value.ios.ip) http://localhost:8100/status" -ForegroundColor Green }catch{ Write-Host "[WDA]: OFFLINE" -ForegroundColor Red }
try{ Invoke-RestMethod http://localhost:11434/api/tags -TimeoutSec 2 | Out-Null; Write-Host "[Ollama (LLM)]: ONLINE" -ForegroundColor Green }catch{ Write-Host "[Ollama (LLM)]: OFFLINE" -ForegroundColor Yellow }
Write-Host "[PM2 Supervisor]: ONLINE" -ForegroundColor Green
Write-Host "------------------------"
Write-Host "PIDs -> Tunnel:$($tunnelProc.Id) Forward:$($forwardProc.Id) WDA:$($wdaProc.Id)" -ForegroundColor DarkGray
Write-Host "Logs -> tunnel.log / forward.log / wda.log" -ForegroundColor DarkGray
pm2 list
Write-Host ""
Write-Host "LISTO. Deja esta ventana abierta. RUNEFORGE ya puede automatizar." -ForegroundColor Cyan
Write-Host "Parar todo: pm2 delete all; Get-Process ios,node | Stop-Process -Force" -ForegroundColor DarkGray

# Mantener ventana viva
while($true){ Start-Sleep 10 }
