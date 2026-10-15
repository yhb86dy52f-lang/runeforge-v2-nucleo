# ScannerPRO v9.0 COLLAB — Patch delta vs v8.3.8 RAFAGA

Si prefieres NO reemplazar tu `.ino` completo, aplica estos 4 cambios
quirúrgicos sobre tu `ScannerPRO_v838_RAFAGA.ino`.

## 1) struct DeviceEntry — añadir 4 campos

    String   eid;
    uint8_t  batt;
    uint32_t tagEpoch;
    bool     isRuneforge;

## 2) classifyFamily() — añadir parámetro rf + 2 reglas

    String classifyFamily(const String& name, const String& mac, bool rf = false) {
      if (rf) return "runeforge";
      String n = name; n.toUpperCase();
      String m = mac;  m.toLowerCase();
      if (n.indexOf("RUNEFORGE") >= 0 || n.startsWith("RF-")) return "runeforge";
      // ... resto igual
    }

## 3) ScanCallbacks::onResult() — añadir parseo FEAA/0x50

Antes de matchesFilter, añadir el bloque que extrae eidHex, batt, tagEpoch,
isRF. Detalle completo en `ScannerPRO_v9_COLLAB.ino` (busca "RUNEFORGE
extraction"). Regla:

    off = 0  si len>=14 && p[0]==0x50
    off = 2  si len>=16 && p[0]==0xAA && p[1]==0xFE && p[2]==0x50

    eidHex = hex(p[off+1..off+8])
    batt   = p[off+9]
    epoch  = BE32(p[off+10..off+13])

## 4) handleDispositivos() — añadir campos colaborativos

Después de `o["ts_server"] = genTsServer();` añadir:

    o["eid"]       = devices[i].eid;
    o["batt"]      = devices[i].batt;
    o["epoch"]     = devices[i].tagEpoch;
    o["finder_id"] = FINDER_ID;
    o["lat"]       = FINDER_LAT;
    o["lon"]       = FINDER_LON;

## 5) MQTT publish — topic colaborativo

Reemplazar `mqtt.publish(cfg.mqttTopic, payload)` por:

    String topic = String(cfg.mqttTopic) + "/" + FINDER_ID + "/report";
    mqtt.publish(topic.c_str(), payload);

Y añadir al JSON: eid, batt, epoch, finder_id, lat, lon, ts.