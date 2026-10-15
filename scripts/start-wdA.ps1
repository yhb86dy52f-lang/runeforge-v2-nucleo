# RUNEFORGE V2 - One Click WDA for iOS 27.0
# Cierra todas las terminales antes de ejecutar esto

$bundleId = "com.facebook.WebDriverAgentRunner.xctrunner.T58A9CHGBT"
$ErrorActionPreference = "SilentlyContinue"

Write-Host "=== RUNEFORGE WDA STARTER ===" -ForegroundColor Cyan
Write-Host "Matando procesos ios viejos..." -ForegroundColor DarkGray
Get-Process -Name "ios" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep 2

Write-Host "[1/3] Iniciando tunnel (userspace)..." -ForegroundColor Yellow
$tunnel = Start-Process -FilePath "ios" -ArgumentList "tunnel start --userspace" -PassThru -NoNewWindow
Start-Sleep 3

# Esperar a que aparezca el endpoint
$retries = 0
while ($retries -lt 20) {
    $conn = Get-NetTCPConnection -LocalPort 60106 -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($conn) { break }
    Write-Host "." -NoNewline
    Start-Sleep 1
    $retries++
}
Write-Host ""
Write-Host "Tunnel PID $($tunnel.Id) iniciado" -ForegroundColor Green

Write-Host "[2/3] Forwardeando 8100 -> 8100..." -ForegroundColor Yellow
$forward = Start-Process -FilePath "ios" -ArgumentList "forward 8100 8100" -PassThru -NoNewWindow
Start-Sleep 2
Write-Host "Forward PID $($forward.Id) iniciado" -ForegroundColor Green

Write-Host "[3/3] Iniciando WDA - NO CIERRES ESTA VENTANA" -ForegroundColor Yellow
Write-Host "Esperando ready: true en http://localhost:8100/status" -ForegroundColor Cyan
Write-Host ""

# Esto se queda bloqueando, es el proceso principal
ios runwda --bundleid $bundleId --testrunnerbundleid $bundleId --xctestconfig WebDriverAgentRunner.xctest

# Si se cae el runwda, matamos todo
Write-Host "WDA se detuvo, matando tunnel y forward..." -ForegroundColor Red
Stop-Process -Id $tunnel.Id -Force -ErrorAction SilentlyContinue
Stop-Process -Id $forward.Id -Force -ErrorAction SilentlyContinue
