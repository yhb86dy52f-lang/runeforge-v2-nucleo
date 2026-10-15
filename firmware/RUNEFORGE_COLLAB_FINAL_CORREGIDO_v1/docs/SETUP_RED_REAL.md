
# RUNEFORGE - Setup con tu RED real

Tu PC IP: 192.168.100.5 (del RED.txt)
Hotspot: RUNE FORGE-PC 8808 (0/8 conectados) -> AP para ESPs en campo
Tailscale: runeforge-pc 100.83.105.117 (acceso remoto desde iPhone)

## Paso 1 - Levantar MQTT en Docker Desktop (imagen que mandaste)

1. Pon docker-compose.yml y mosquitto.conf en C:\RUNEFORGE\DOCKER
2. En PowerShell:
   cd C:\RUNEFORGE\DOCKER
   docker compose up -d
3. Verifica:
   docker logs runeforge-mqtt

MQTT queda en 192.168.100.5:1883 (tu IP real del RED.txt)

## Paso 2 - Flashear ESP32 con config.h real

Ya actualicé config.h con:
- WIFI_SSID_1 = 517388haieksja_2.4G / bebecillogordillo (tu router canal 11)
- WIFI_SSID_2 = RUNE FORGE-PC 8808 / 12345678 (tu hotspot PC)
- MQTT_SERVER = 192.168.100.5 (tu PC)

Compila ScannerPRO.ino con Minimal SPIFFS y flashea OTA a 192.168.100.14 o directo USB.

Si estás en campo sin router, activa hotspot RUNE FORGE-PC 8808 en Windows (ya lo tienes Activado, Ahorro Desactivado) y el ESP se conecta al slot 2 automáticamente.

## Paso 3 - Test

En PowerShell:
  mosquitto_sub -h 192.168.100.5 -t "scannerpro/#" -v

Debes ver:
  scannerpro/collab/SCANNER-14-TORREON/report {"eid":"...","rssi_kalman":-62,...}

## Paso 4 - Tailscale remoto

Desde tu iPhone (100.95.173.89) abre:
  http://100.83.105.117:1880   -> Node-RED
  http://100.83.105.117:1883 no, pero MQTT via Tailscale funciona
  http://scanner-pro.local si estás en misma red

Con Tailscale puedes ver dashboard NEXUS desde el iPhone en campo.
