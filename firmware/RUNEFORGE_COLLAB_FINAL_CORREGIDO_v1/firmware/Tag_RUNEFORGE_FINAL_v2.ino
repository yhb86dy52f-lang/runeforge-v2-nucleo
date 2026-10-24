/*
  ============================================================
  TAG RUNEFORGE v2.0 FINAL
  ESP32-WROOM-32D / ESP32-C3 | 100% TX continuo (batería resuelta)
  EID rotativo 300s | AES-128 ECB | Payload FEAA/0x50 v2
  ============================================================
  Contrato EID:
    EID = AES-128-ECB(SK, epoch_BE(4) || "RF-01" || 0x00*8)[:8]
  Payload Service Data 0xFEAA:
    [0xAA][0xFE][0x50][EID 8B][batt 1B][epoch BE 4B]  = 16 bytes
  ============================================================
*/

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <mbedtls/aes.h>

// ====== CONFIG ======
// CAMBIA esta SK por la tuya (misma que pondrás en haystack_decoder_v2.py)
#define SK_SECRET {0x12,0x34,0x56,0x78,0x9A,0xBC,0xDE,0xF0, \
                   0x11,0x22,0x33,0x44,0x55,0x66,0x77,0x88}

#define DEVICE_ID       "RF-01"
#define EPOCH_SECONDS   300
#define BATT_PERCENT    95   // placeholder, conecta ADC si quieres real

static uint8_t sk[16] = SK_SECRET;
static BLEAdvertising *pAdv = nullptr;
static uint32_t currentEpoch = 0;
static unsigned long lastTick = 0;

// ====== CRYPTO ======
static void aesEncrypt(const uint8_t *key, const uint8_t *in, uint8_t *out) {
  mbedtls_aes_context aes;
  mbedtls_aes_init(&aes);
  mbedtls_aes_setkey_enc(&aes, key, 128);
  mbedtls_aes_crypt_ecb(&aes, MBEDTLS_AES_ENCRYPT, in, out);
  mbedtls_aes_free(&aes);
}

static void genEID(uint32_t epoch, uint8_t *eid) {
  uint8_t in[16] = {0};
  in[0] = (epoch >> 24) & 0xFF;
  in[1] = (epoch >> 16) & 0xFF;
  in[2] = (epoch >>  8) & 0xFF;
  in[3] =  epoch        & 0xFF;
  in[4] = DEVICE_ID[0];
  in[5] = DEVICE_ID[1];
  in[6] = DEVICE_ID[2];
  in[7] = DEVICE_ID[3];
  uint8_t full[16];
  aesEncrypt(sk, in, full);
  memcpy(eid, full, 8);
}

// ====== ADV ======
static void publishAdv() {
  uint8_t eid[8];
  genEID(currentEpoch, eid);

  char hex[17];
  for (int i = 0; i < 8; i++) sprintf(hex + i * 2, "%02X", eid[i]);

  Serial.printf("[TAG] epoch=%u eid=%s batt=%u\n",
                currentEpoch, hex, BATT_PERCENT);

  uint8_t payload[14];
  payload[0] = 0x50;
  memcpy(payload + 1, eid, 8);
  payload[9]  = BATT_PERCENT;
  payload[10] = (currentEpoch >> 24) & 0xFF;
  payload[11] = (currentEpoch >> 16) & 0xFF;
  payload[12] = (currentEpoch >>  8) & 0xFF;
  payload[13] =  currentEpoch        & 0xFF;

  // Service Data: [0xAA 0xFE] + 14 bytes payload
  String sd;
  sd.reserve(16);
  sd += (char)0xAA;
  sd += (char)0xFE;
  for (int i = 0; i < 14; i++) sd += (char)payload[i];

  BLEAdvertisementData adv;
  adv.setFlags(0x06);
  adv.setServiceData(BLEUUID((uint16_t)0xFEAA), sd);

  // Nombre que engancha con NAME_FILTERS del ScannerPRO
  char nameBuf[24];
  snprintf(nameBuf, sizeof(nameBuf), "RF-%s-%c%c%c%c",
           DEVICE_ID, hex[0], hex[1], hex[2], hex[3]);
  adv.setName(nameBuf);

  pAdv->setAdvertisementData(adv);
}

// ====== SETUP / LOOP ======
void setup() {
  Serial.begin(115200);
  delay(800);
  Serial.println("\n============================================================");
  Serial.println("  TAG RUNEFORGE v2.0 FINAL — 100% TX CONTINUO");
  Serial.println("============================================================");
  Serial.printf("DEVICE_ID=%s  EPOCH=%ds  SK=1234...7788\n",
                DEVICE_ID, EPOCH_SECONDS);

  BLEDevice::init(DEVICE_ID);
  BLEDevice::createServer();
  pAdv = BLEDevice::getAdvertising();
  pAdv->setScanResponse(false);
  pAdv->setMinPreferred(0x06);
  pAdv->setMinPreferred(0x12);

  currentEpoch = millis() / (EPOCH_SECONDS * 1000UL);
  publishAdv();
  BLEDevice::startAdvertising();

  Serial.println("[TAG] advertising FEAA/0x50 corriendo\n");
}

void loop() {
  if (millis() - lastTick > 1000) {
    lastTick = millis();
    uint32_t e = millis() / (EPOCH_SECONDS * 1000UL);
    if (e != currentEpoch) {
      currentEpoch = e;
      publishAdv();
      BLEDevice::startAdvertising();
    }
  }
  delay(50);
}