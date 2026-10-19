
# RUNEFORGE COLLAB PROTO v1.0 — Red BLE Colaborativa tipo Find My

## Kit que tienes ya
- 1x ESP32 ScannerPRO v8.3.8 RAFAGA (192.168.100.14) como FINDER
- N x ESP32/ESP32-C3 como TAGS (este firmware Tag_RUNEFORGE_PROTO.ino)

## Flujo prototipo funcional HOY (sin GPS, con ubicación fija del finder)
1. Flashea TAG en un ESP32-C3 con SK secreta (cambia SK_SECRET en código). Emite cada 500ms Service UUID FEAA frame 0x50 con EID rotativo 5min.
2. ScannerPRO lo detecta como family=runeforge (tu filtro C3:00 ya lo coge). Publica a MQTT:
   scannerpro/collab/SCANNER-14/report {"eid":"...","rssi_kalman":-62,"lat":25.54,"lon":-103.40,"ts":...}
3. Corre haystack_decoder.py con tu SK para validar que EID es tuyo y no spoof.
4. Dashboard NEXUS muestra radar + mapa Leaflet con última posición del TAG = posición del FINDER que lo vio.

## Próxima fase (ya prevista en código)
- Cambiar epoch basado en time(nullptr) con NTP, no millis()
- Cifrar lat/lon del finder con ECIES P-224 del owner (como Apple: P_i = u_i*P + v_i*G, SK_i = KDF(SK_{i-1}, "update"))
- Implementar DULT: si TAG separado de owner >10 min, empieza a emitir FD44 para alertar tracking no deseado
- Integrar OpenHaystack: generar P-224 y subir a red Apple Find My (funciona parcialmente, Apple filtra no-Apple desde 2025)

## Flash
- TAG: Arduino IDE ESP32-C3 Dev Module, Partition Default, Upload
- SCANNER: Ya tienes v8.3.8, solo añade patch classifyFamilyCollab en tu .ino y recompila 1,759KB para OTA

## Demo en 5 min
- Pon TAG en un camión, SCANNER en oficina, mueve TAG, verás en /api/dispositivos vivo=true y rssi_kalman cambiando, y en dashboard radar el punto moviéndose de borde a centro.
