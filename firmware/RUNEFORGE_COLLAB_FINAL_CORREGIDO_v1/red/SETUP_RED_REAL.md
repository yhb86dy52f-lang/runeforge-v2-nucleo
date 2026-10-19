# RUNEFORGE — Setup red real (Torreón)

## Host PC
- IP LAN    : 192.168.100.5
- Tailscale : 100.83.105.117 (runeforge-pc)
- iPhone    : 100.95.173.89 (iphone-14-pro)
- Router    : 517388haieksja_2.4G / canal 11 / WPA2
- Hotspot   : RUNE FORGE-PC 8808 / 12345678

## Docker (broker MQTT)
    cd $env:SystemDrive\RUNEFORGE\DOCKER
    docker compose down
    docker compose up -d
    docker logs runeforge-mqtt

Puertos:
- 1883 TCP  → Scanner ESP32, mosquitto_sub, Node-RED
- 9001 WS   → dashboards browser
- 1880 HTTP → Node-RED

## Scanner ESP32
- IP objetivo: 192.168.100.14
- mDNS       : scanner-pro.local
- MQTT      : 192.168.100.5:1883
- Topic     : scannerpro/collab/SCANNER-14-TORREON/report

## Tag ESP32
- Service UUID 0xFEAA
- Frame 0x50 (RUNEFORGE)
- EID rotativo 300s
- Nombre adv "RF-RF-01-XXXX"

## Test end-to-end

    # Terminal A
    mosquitto_sub -h 192.168.100.5 -t "scannerpro/#" -v | Tee-Object mqtt.json

    # Terminal B (validador)
    python haystack_decoder_v2.py --sk 123456789ABCDEF01122334455667788 `
        --device-id RF-01 --scan-log mqtt.json

Criterio de éxito: 4 verdes
1. Serial Tag     : "epoch=N eid=XXXXXXXXXXXXXXXX"
2. curl scanner   : /api/dispositivos trae "family":"runeforge","eid":"..."
3. mosquitto_sub  : línea scannerpro/collab/SCANNER-14-TORREON/report {...}
4. decoder        : "✅ OWN" para ese reporte

## Tailscale (acceso remoto desde iPhone)
- http://100.83.105.117:1880 → Node-RED
- http://100.83.105.117:80   → ScannerPRO (si STA activa)
- MQTT TCP 1883 vía Tailscale funciona