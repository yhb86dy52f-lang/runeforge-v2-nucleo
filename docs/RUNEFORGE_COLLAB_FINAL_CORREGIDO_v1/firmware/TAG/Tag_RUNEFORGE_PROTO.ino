
/*
  TAG RUNEFORGE PROTO v1.0 - Red Colaborativa BLE tipo Find My
  Hardware: ESP32 / ESP32-C3 / nRF52
  Emite EID rotativo cada 5 min (300s) derivado de SK secreto via AES-128
  Formato: Service UUID 0xFEAA (para ser captado por ScannerPRO) + custom frame 0x50
  + 8-byte EID + battery + name RUNEFORGE-TAG-XX

  Para prototipo rápido: usa prefijo MAC C3:00 y nombre para que tu filtro actual lo capture
*/
#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>
#include <mbedtls/aes.h>
#include <esp_sleep.h>

#define SK_SECRET {0x12,0x34,0x56,0x78,0x9A,0xBC,0xDE,0xF0,0x11,0x22,0x33,0x44,0x55,0x66,0x77,0x88} // CAMBIA ESTO - tu clave maestra 16 bytes
#define EPOCH_SECONDS 300 // 5 min rotación como tpt-bluetooth-mesh
#define DEVICE_ID "RF-01"

uint8_t sk[16] = SK_SECRET;

void aesEcbEncrypt(uint8_t *key, uint8_t *input, uint8_t *output) {
  mbedtls_aes_context aes;
  mbedtls_aes_init(&aes);
  mbedtls_aes_setkey_enc(&aes, key, 128);
  mbedtls_aes_crypt_ecb(&aes, MBEDTLS_AES_ENCRYPT, input, output);
  mbedtls_aes_free(&aes);
}

void generateEID(uint32_t epoch, uint8_t *eid_out) {
  uint8_t input[16] = {0};
  input[0] = (epoch >> 24) & 0xFF;
  input[1] = (epoch >> 16) & 0xFF;
  input[2] = (epoch >> 8) & 0xFF;
  input[3] = epoch & 0xFF;
  // padding con DEVICE_ID hash
  input[4] = DEVICE_ID[0];
  input[5] = DEVICE_ID[1];
  input[6] = DEVICE_ID[2];
  input[7] = DEVICE_ID[3];
  uint8_t full[16];
  aesEcbEncrypt(sk, input, full);
  memcpy(eid_out, full, 8); // truncado 64 bits para caber en BLE (estándar EID)
}

void setup() {
  Serial.begin(115200);
  delay(500);
  Serial.println("=== TAG RUNEFORGE PROTO v1.0 ===");
  
  BLEDevice::init(String("RUNEFORGE-TAG-") + DEVICE_ID);
  BLEServer *pServer = BLEDevice::createServer();
  BLEAdvertising *pAdv = BLEDevice::getAdvertising();
  
  // Usamos 0xFEAA para ser detectado por ScannerPRO como FMDN-like pero frame custom 0x50 = RUNEFORGE
  BLEAdvertisementData advData;
  advData.setFlags(0x06);
  
  uint32_t epoch = millis() / (EPOCH_SECONDS * 1000); // para demo sin RTC, usa uptime; en prod usa unix time
  // En prod: epoch = time(nullptr) / EPOCH_SECONDS
  
  uint8_t eid[8];
  generateEID(epoch, eid);
  
  char eidHex[17];
  for(int i=0;i<8;i++) sprintf(eidHex + i*2, "%02X", eid[i]);
  Serial.printf("EPOCH %u EID %s\n", epoch, eidHex);
  
  // Payload: [0xFEAA][frame 0x50 RUNEFORGE][8-byte EID][batt][rssi_ref]
  uint8_t payload[13];
  payload[0] = 0x50; // RUNEFORGE custom frame
  memcpy(payload+1, eid, 8);
  payload[9] = 85; // battery %
  payload[10] = 0xC3; // ref RSSI
  payload[11] = 0x00; // flags
  payload[12] = 0x01; // version
  
  // Service Data 0xFEAA
  std::string serviceData = "";
  serviceData += (char)0xAA;
  serviceData += (char)0xFE;
  for(int i=0;i<13;i++) serviceData += (char)payload[i];
  
  advData.setServiceData(BLEUUID((uint16_t)0xFEAA), serviceData);
  advData.setName(String("RF-") + DEVICE_ID + "-" + String(eidHex).substring(0,4));
  
  pAdv->setAdvertisementData(advData);
  pAdv->setScanResponse(false);
  pAdv->setMinPreferred(0x06);
  pAdv->setMinPreferred(0x12);
  
  BLEDevice::startAdvertising();
  Serial.println("Advertising RUNEFORGE TAG...");
  
  // Deep sleep 0.5s advertising, 4.5s sleep para bajo consumo (prototipo)
  // Descomenta para modo ultra bajo consumo:
  // esp_sleep_enable_timer_wakeup(4500*1000);
  // delay(500);
  // esp_deep_sleep_start();
}

void loop() {
  delay(5000);
  // Re-generar EID cada epoch
  uint32_t epoch = millis() / (EPOCH_SECONDS * 1000);
  uint8_t eid[8];
  generateEID(epoch, eid);
  Serial.printf("Still alive EPOCH %u\n", epoch);
}
