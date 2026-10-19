
# RUNEFORGE V14 CORRECTIVO TOTAL - Si cambias uno, cambias todos
# Uso: .\Correctivo-Total.ps1 -WifiPass "bebecillogordillo" -MqttServer "192.168.100.5"

param(
  [string]$WifiSsid = "517388haieksja_2.4G",
  [string]$WifiPass = "bebecillogordillo",
  [string]$MqttServer = "192.168.100.5",
  [string]$Port = "COM5",
  [string]$DeviceId = "SCANNER-14-TORREON"
)

$ErrorActionPreference = "Stop"
Write-Host "=== RUNEFORGE V14 CORRECTIVO TOTAL ===" -ForegroundColor Cyan
Write-Host "FUENTE DE VERDAD: SSID=$WifiSsid | PASS=$($WifiPass.Substring(0,3))*** | MQTT=$MqttServer | DEVICE=$DeviceId" -ForegroundColor White

$root = "C:\RUNEFORGE_V2_CORE"
$downloads = "$env:USERPROFILE\Downloads"
$src = "$root\apps\esp32-scanner-pro\src"
$firmware = "$root\firmware"
$mosq = "$root\mosquitto"

# 0. Buscar pack correctivo en Downloads
$pack = Get-ChildItem "$downloads\*correctivo*" -Directory -EA SilentlyContinue | Sort LastWriteTime -Descending | Select -First 1
if(-not $pack){ $pack = Get-Item "C:\Users\nesth\Downloads" }

# 1. Generar config.h CORRECTIVO desde parametros (FUENTE UNICA)
$configPath = "$firmware\config.h"
@"
#ifndef CONFIG_H
#define CONFIG_H
#define DEF_WIFI_SSID     "$WifiSsid"
#define DEF_WIFI_PASS     "$WifiPass"
#define DEF_MQTT_SERVER   "$MqttServer"
#define DEF_MQTT_PORT     1883
#define DEF_MQTT_WS_PORT  9001
#define DEF_MQTT_TOPIC_PUB  "scannerpro/collab/$DeviceId/report"
#define DEF_MQTT_TOPIC_SUB  "scannerpro/collab/+/cmd"
#define DEF_MQTT_CLIENT_BASE "$DeviceId"
#define DEF_DEVICE_ID       "$DeviceId"
#define BLE_SCAN_INTERVAL 100
#define BLE_SCAN_WINDOW   99
#define BLE_ACTIVE_SCAN   true
#define DEF_MQTT_KEEPALIVE 60
#endif
"@ | Out-File $configPath -Encoding utf8
Write-Host "[1/5] config.h CORRECTIVO -> $configPath" -ForegroundColor Green

# 2. mosquitto.conf CORRECTIVO
$mosqConf = @"
listener 1883 0.0.0.0
allow_anonymous true
listener 9001 0.0.0.0
protocol websockets
allow_anonymous true
persistence false
log_dest stdout
log_type all
connection_messages true
"@
$mosqConf | Out-File "$mosq\mosquitto.conf" -Encoding utf8
Write-Host "[2/5] mosquitto.conf CORRECTIVO -> $mosq\mosquitto.conf" -ForegroundColor Green

# 3. .ino CORRECTIVO - Copiar si existe en Downloads
$inoCorrectivo = Get-ChildItem "$downloads\*\ScannerPRO*CORRECTIVO*.ino" -Recurse -EA SilentlyContinue | Select -First 1
if(-not $inoCorrectivo){ $inoCorrectivo = Get-ChildItem "$downloads\ScannerPRO*CORRECTIVO*.ino" -EA SilentlyContinue | Select -First 1 }
if($inoCorrectivo){ Copy-Item $inoCorrectivo.FullName "$firmware\ScannerPRO_v9_COLLAB.ino" -Force; Write-Host "[3/5] .ino CORRECTIVO copiado" -ForegroundColor Green }
else { Write-Host "[3/5] .ino CORRECTIVO no encontrado, edita manualmente clientId random" -ForegroundColor Yellow }

# 4. Dashboard v14 CORRECTIVO
$dash = Get-ChildItem "$downloads\*v14*CORRECTIVO*.html" -EA SilentlyContinue | Sort LastWriteTime -Descending | Select -First 1
if(-not $dash){ $dash = Get-ChildItem "$downloads\*v13.2*FIX*.html" -EA SilentlyContinue | Sort LastWriteTime -Descending | Select -First 1 }
if(-not $dash){ $dash = Get-ChildItem "$downloads\*V13*FIX*MQTT*.html" -EA SilentlyContinue | Sort LastWriteTime -Descending | Select -First 1 }
if($dash){ Copy-Item $dash.FullName "$src\index.html" -Force; Write-Host "[4/5] index.html CORRECTIVO -> $src\index.html" -ForegroundColor Green }

# 5. Verificar IP actual
$ip = (Get-NetIPAddress -AddressFamily IPv4 | Where {$_.IPAddress -like "192.168.100.*"} | Select -First 1).IPAddress
Write-Host "`n[CHECK] IP PC detectada: $ip (configurada $MqttServer)" -ForegroundColor Cyan
if($ip -ne $MqttServer){ Write-Host "⚠️  MISMATCH! Tu PC ahora es $ip pero config dice $MqttServer - Corrige con -MqttServer $ip" -ForegroundColor Red }

Write-Host "`n=== CORRECTIVO TOTAL LISTO ===" -ForegroundColor Green
Write-Host "1. Reinicia broker: & 'C:\Program Files\mosquitto\mosquitto.exe' -c $mosq\mosquitto.conf -v" -ForegroundColor White
Write-Host "2. Flashea: .\firmware\flash-FINAL-DIRECT-WIFI.ps1 -WifiSsid $WifiSsid -WifiPass $WifiPass -MqttServer $MqttServer -Port $Port" -ForegroundColor White
Write-Host "3. Build: .\scripts\Build-Release-Estable.ps1 -Apps @('esp32-scanner-pro')" -ForegroundColor White
