
# RUNEFORGE V13 FINAL - DIRECT WIFI 517388haieksja_2.4G - FLASH CORREGIDO
param(
  [string]$WifiSsid = "517388haieksja_2.4G",
  [string]$WifiPass = "bebecillogordillo",
  [string]$MqttServer = "192.168.100.5",
  [string]$Port = "COM5",
  [int]$Baud = 460800,
  [string]$Mode = "auto"
)

$ErrorActionPreference = "Stop"
Write-Host "=== RUNEFORGE V13 FINAL - DIRECT WIFI ===" -ForegroundColor Cyan
Write-Host "SSID: $WifiSsid | PASS: $($WifiPass.Substring(0,3))*** | MQTT: $MqttServer | Port: $Port" -ForegroundColor Gray

$root = "C:\RUNEFORGE_V2_CORE"
$firmware = "$root\firmware"
$sketchName = "ScannerPRO_v9_COLLAB.ino"

# 1. Generar config.h FINAL
$configPath = Join-Path $firmware "config.h"
$configContent = @"
#ifndef CONFIG_H
#define CONFIG_H
#define DEF_WIFI_SSID     "$WifiSsid"
#define DEF_WIFI_PASS     "$WifiPass"
#define DEF_MQTT_SERVER   "$MqttServer"
#define DEF_MQTT_PORT     1883
#define DEF_MQTT_WS_PORT  9001
#define DEF_MQTT_TOPIC    "scannerpro/collab/SCANNER-14-TORREON/report"
#define DEF_MQTT_CLIENT   "SCANNER-14-TORREON"
#define BLE_SCAN_INTERVAL 100
#define BLE_SCAN_WINDOW   99
#define BLE_ACTIVE_SCAN   true
#endif
"@
$configContent | Out-File -Encoding utf8 $configPath
Write-Host "[OK] config.h generado DIRECT WIFI -> $configPath" -ForegroundColor Green

# 2. Buscar build previo
$sketchRoot = "$env:LOCALAPPDATA\arduino\sketches"
$build = Get-ChildItem $sketchRoot -Directory -EA SilentlyContinue |
  Where-Object { Test-Path "$($_.FullName)\$sketchName.bin" } |
  Sort-Object LastWriteTime -Descending | Select-Object -First 1

if(-not $build){
  Write-Host "[!] No hay build previo, compilando con arduino-cli si existe..." -ForegroundColor Yellow
  $cli = Get-Command arduino-cli -EA SilentlyContinue
  if($cli){
    $buildPath = "$env:TEMP\runeforge_build"
    & arduino-cli compile --fqbn esp32:esp32:esp32 "$firmware" --build-path $buildPath
    $build = Get-Item $buildPath
  } else {
    throw "Compila primero en Arduino IDE: $sketchName y deja el .bin en $sketchRoot"
  }
}

Write-Host "[OK] Build: $($build.FullName)" -ForegroundColor Green
$boot = Get-ChildItem $build.FullName -Filter "*.bootloader.bin" | Select -First 1 -Expand FullName
$part = Get-ChildItem $build.FullName -Filter "*.partitions.bin" | Select -First 1 -Expand FullName
$app  = Get-ChildItem $build.FullName -Filter "$sketchName.bin" | Select -First 1 -Expand FullName
$bootApp0 = Get-ChildItem "$env:LOCALAPPDATA\Arduino15\packages\esp32\hardware\esp32" -Recurse -Filter "boot_app0.bin" -EA SilentlyContinue | Select -First 1 -Expand FullName
$esptool = Get-ChildItem "$env:LOCALAPPDATA\Arduino15\packages\esp32\tools" -Recurse -Filter "esptool.exe" -EA SilentlyContinue | Sort LastWriteTime -Descending | Select -First 1 -Expand FullName

if(-not $esptool){ throw "esptool.exe no encontrado en Arduino15" }

$before = if($Mode -eq "manual"){"no_reset"}else{"default_reset"}
if($Mode -eq "manual"){
  Write-Host "`n=== MODO MANUAL 115200 - BOOT+EN 15s ===" -ForegroundColor Yellow
  for($i=15;$i -ge 1;$i--){ Write-Host -NoNewline ("`r Mantén BOOT {0}s... " -f $i) -ForegroundColor Yellow; Start-Sleep 1 }
  $Baud=115200
}

$args = @("--chip","esp32","--port",$Port,"--baud",$Baud,"--before",$before,"--after","hard_reset","write_flash","-z","--flash_mode","dio","--flash_freq","80m","--flash_size","detect","0x1000",$boot,"0x8000",$part)
if($bootApp0){ $args+=@("0xe000",$bootApp0) }
$args+=@("0x10000",$app)

Write-Host "`nFlasheando $Port $Baud $Mode..." -ForegroundColor Cyan
& $esptool @args

if($LASTEXITCODE -eq 0){
  Write-Host "`n[OK] FLASH OK - SCANNER-14-TORREON en $WifiSsid -> MQTT $MqttServer" -ForegroundColor Green
} else {
  Write-Host "`n[FAIL] exit=$LASTEXITCODE - Prueba -Mode manual" -ForegroundColor Red
}
