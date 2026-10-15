
# RUNEFORGE COLLAB - De Cero a Prod v1.0 FINAL
# Con correcciones de RED REAL Torreón

## Datos reales integrados (de tus archivos RED.txt, TAILSCALE.csv, imágenes)
- WiFi Router: 517388haieksja_2.4G / bebecillogordillo / Canal 11 / 2.4GHz / IP PC 192.168.100.5
- Hotspot PC: RUNE FORGE-PC 8808 / 12345678 / Ahorro Desactivado / 0 de 8 / Activado (imagen)
- Tailscale: runeforge-pc 100.83.105.117, iphone-14-pro 100.95.173.89
- Docker Desktop: Engine running
- ESP32: ESP32-WROOM-32D FCC ID 2A54N-ESP32 (foto esp_mio.jpg) con batería resuelta
- MQTT: 192.168.100.5:1883 via Docker (corrección de 192.168.100.8)

## Estructura ZIP
firmware/TAG/Tag_RUNEFORGE_FINAL.ino -> Flashear en ESP con batería, TX continuo FEAA 0x50 RUNEFORGE
firmware/FINDER/ScannerPRO_v9_COLLAB.ino + config.h -> Finder 192.168.100.14, ráfagas 2s/0.4s fix WDT
backend/docker-compose.yml + mosquitto.conf -> docker compose up -d
backend/haystack_decoder.py -> valida EIDs con SK secreta
dashboard/RUNEFORGE_COLLAB_DASHBOARD.html -> Entorno trabajo NEXUS COLLAB
docs/ -> Guias

## Correcciones aplicadas
1. config.h: WiFi dual real + MQTT 192.168.100.5 (no 192.168.100.8)
2. Tag: eliminado deep sleep por batería resuelta, TX 100% continuo
3. Finder: burst scan fix task_wdt loopTask, coex BALANCE, AP+STA siempre ON para campo
4. Filtros: añadido 50:2b:73 (tu USB WiFi MAC), 55:17, 50:55, c5:fa (tus objetivos SCAN log), RUNEFORGE, RF-
5. Docker: mosquitto.conf allow_anonymous true para pruebas campo
6. Tailscale: docs para acceso remoto iPhone -> PC

## Flash rápido
TAG (WROOM con batería):
  Arduino -> ESP32 Dev Module -> Minimal SPIFFS -> Upload Tag_RUNEFORGE_FINAL.ino

FINDER (WROOM):
  Mismo board -> Upload ScannerPRO_v9_COLLAB.ino (usa config.h corregido)
  OTA: http://scanner-pro.local/update -> arrastra bin 1,759KB

Test:
  curl http://192.168.100.14/api/dispositivos -> debe salir runeforge
  docker exec -it runeforge-mqtt mosquitto_sub -t "scannerpro/#" -v

Dashboard: abre dashboard/RUNEFORGE_COLLAB_DASHBOARD.html o http://192.168.100.14
