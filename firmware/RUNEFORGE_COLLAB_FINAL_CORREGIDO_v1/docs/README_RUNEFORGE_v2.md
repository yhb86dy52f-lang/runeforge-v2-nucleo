# RUNEFORGE COLLAB v2.0 — Contrato E2E

## Derivación EID (contrato único, no negociable)
    EID = AES-128-ECB(SK, epoch_BE(4) || device_id[:4] || 0x00*8)[:8]
    - SK: 16 bytes (hex 32 chars), secreta del owner
    - epoch: uint32 big-endian, rotación cada 300s
    - device_id: string, primeros 4 bytes ASCII ("RF-01")
    - output: primeros 8 bytes del ciphertext → 16 hex chars

## Payload BLE (Tag → aire)
    Service UUID: 0xFEAA
    Service Data: [0xAA 0xFE] + payload[14]
    payload = [
      0x50           frame RUNEFORGE
      EID[8]         big-endian
      batt           0-100
      epoch_BE[4]    permite validar sin reloj compartido
    ]
    Nombre adv: "RF-RF-01-XXXX"  (XXXX = primeros 4 hex del EID)
    Nota: el prefijo RF- coincide con filtro MAC_PREFIXES/NAME_FILTERS
          del ScannerPRO config.h para captura garantizada.

## MQTT (Scanner → broker)
    Topic: scannerpro/collab/{FINDER_ID}/report
    Payload JSON:
    {
      "eid":         "AABBCCDD11223344",
      "mac":         "aa:bb:cc:dd:ee:ff",
      "name":        "RF-RF-01-AABB",
      "family":      "runeforge",
      "rssi_raw":    -68,
      "rssi_kalman": -66.4,
      "count":       42,
      "batt":        95,
      "epoch":       1234567,
      "finder_id":   "SCANNER-14-TORREON",
      "lat":         25.5428,
      "lon":         -103.4068,
      "ts":          1730000000
    }

## REST (Scanner → dashboard)
    GET /api/dispositivos  →  JSON array, cada item con los campos MQTT
                              + edad_seg, vivo, ts_server

## Puertos
    1883   MQTT TCP       (Scanner, mosquitto_sub, node-red)
    9001   MQTT WebSocket (dashboards browser)
    80     HTTP Scanner   (API + dashboard embebido)
    1880   Node-RED       (opcional)

## Seguridad (estado actual)
    allow_anonymous true  → SOLO pruebas en LAN de campo.
    Fase 2: TLS + auth usuario/pass en mosquitto.conf.
    Fase 3: ECIES P-224 para cifrar lat/lon del finder.