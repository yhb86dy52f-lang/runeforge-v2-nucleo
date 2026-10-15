
/*
  PATCH COLLAB para ScannerPRO v8.3.8 RAFAGA -> v9.0 NEXUS COLLAB
  Añadir a tu ScannerPRO.ino existente en handle de BLE

  Nuevos families: tile, fmdn, airtag, runeforge
*/

String classifyFamilyCollab(const String& name, const String& mac, uint16_t serviceUUID, uint8_t frameType, const uint8_t* payload, size_t len) {
  String n = name; n.toUpperCase();
  String m = mac; m.toLowerCase();
  
  // RUNEFORGE custom 0xFEAA 0x50
  if (serviceUUID == 0xFEAA && len>0 && payload[0]==0x50) return "runeforge";
  
  // Google FMDN
  if (serviceUUID == 0xFEAA && (frameType==0x40 || frameType==0x41)) return "fmdn";
  
  // Tile
  if (serviceUUID == 0xFEED || serviceUUID == 0xFEED) return "tile";
  if (m.startsWith("c3:00") || n.indexOf("RUNEFORGE")>=0) return "runeforge"; // fallback por MAC para proto
  
  // Apple Find My
  // manufacturer 0x004C, type 0x12
  // Se detecta en callback via getManufacturerData()
  
  if (m.startsWith("c3:00") || n.indexOf("CICLOPE")>=0) return "ciclope";
  if (n.indexOf("LMU")>=0) return "lmu";
  if (n.indexOf("SAMSARA")>=0) return "samsara";
  if (n.indexOf("PB705")>=0 || n.indexOf("KW-")>=0) return "kw";
  return "other";
}

// En ScanCallbacks::onResult añadir:
// if (dev.haveServiceUUID() && dev.getServiceUUID().equals(BLEUUID((uint16_t)0xFEAA))) {
//   std::string sd = dev.getServiceData();
//   if(sd.length()>0){ uint8_t ft = (uint8_t)sd[0]; /* 0x40 FMDN, 0x50 RUNEFORGE */ }
// }
// if (dev.haveServiceUUID() && dev.getServiceUUID().equals(BLEUUID((uint16_t)0xFEED))) family="tile";
// if (dev.haveManufacturerData()) { std::string md = dev.getManufacturerData(); if(md.length()>=2 && (uint8_t)md[0]==0x4C && (uint8_t)md[1]==0x00) { if(md[2]==0x12) family="airtag"; } }

// MQTT publish extendido para red colaborativa:
// topic: scannerpro/collab/{scanner_id}/report
// payload: {"eid":"AABBCCDD11223344","family":"runeforge","mac":"c3:00:xx","name":"RF-01-ABCD","rssi_kalman":-62.3,"finder_id":"SCANNER-14","lat":25.54,"lon":-103.40,"ts":172332...,"batt":85}
