
/*
  TAG RUNEFORGE v1.0 FINAL - Sin deep sleep (batería resuelta)
  ESP32-WROOM-32D | Emite EID rotativo 5min AES-128 | 100% TX continuo
  Flashear en ESP32 con batería
*/
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <mbedtls/aes.h>

#define SK_SECRET {0x12,0x34,0x56,0x78,0x9A,0xBC,0xDE,0xF0,0x11,0x22,0x33,0x44,0x55,0x66,0x77,0x88}
#define DEVICE_ID "RF-01"
#define EPOCH_SECONDS 300

uint8_t sk[16] = SK_SECRET;

void aesEncrypt(uint8_t *key, uint8_t *in, uint8_t *out){
  mbedtls_aes_context aes;
  mbedtls_aes_init(&aes);
  mbedtls_aes_setkey_enc(&aes, key, 128);
  mbedtls_aes_crypt_ecb(&aes, MBEDTLS_AES_ENCRYPT, in, out);
  mbedtls_aes_free(&aes);
}

void genEID(uint32_t epoch, uint8_t *eid){
  uint8_t in[16]={0};
  in[0]=(epoch>>24)&0xFF; in[1]=(epoch>>16)&0xFF; in[2]=(epoch>>8)&0xFF; in[3]=epoch&0xFF;
  in[4]=DEVICE_ID[0]; in[5]=DEVICE_ID[1]; in[6]=DEVICE_ID[2]; in[7]=DEVICE_ID[3];
  uint8_t full[16];
  aesEncrypt(sk,in,full);
  memcpy(eid,full,8);
}

BLEAdvertising *pAdv;
unsigned long lastEpochCheck=0;
uint32_t currentEpoch=0;

void updateAdv(){
  uint8_t eid[8];
  genEID(currentEpoch, eid);
  char hex[17]; for(int i=0;i<8;i++) sprintf(hex+i*2,"%02X",eid[i]);
  Serial.printf("[TAG] EPOCH %u EID %s NAME RF-%s-%s\n", currentEpoch, hex, DEVICE_ID, String(hex).substring(0,4).c_str());

  BLEAdvertisementData adv;
  adv.setFlags(0x06);
  uint8_t payload[13];
  payload[0]=0x50; // RUNEFORGE frame
  memcpy(payload+1,eid,8);
  payload[9]=95; // batt
  payload[10]=0xC3; payload[11]=0x00; payload[12]=0x01;
  std::string sd; sd+=(char)0xAA; sd+=(char)0xFE; for(int i=0;i<13;i++) sd+=(char)payload[i];
  adv.setServiceData(BLEUUID((uint16_t)0xFEAA), sd);
  adv.setName(String("RF-") + DEVICE_ID + "-" + String(hex).substring(0,4));
  pAdv->setAdvertisementData(adv);
}

void setup(){
  Serial.begin(115200); delay(800);
  Serial.println("\n=== TAG RUNEFORGE v1.0 FINAL BATERIA ===");
  Serial.printf("DEVICE %s SK 123456789ABCDEF0...\n", DEVICE_ID);
  BLEDevice::init(String("RF-")+DEVICE_ID);
  BLEServer *pServer = BLEDevice::createServer();
  pAdv = BLEDevice::getAdvertising();
  pAdv->setScanResponse(false);
  pAdv->setMinPreferred(0x06);
  currentEpoch = millis()/(EPOCH_SECONDS*1000);
  updateAdv();
  BLEDevice::startAdvertising();
  Serial.println("Advertising 100% continuo FEAA 0x50 RUNEFORGE");
}

void loop(){
  if(millis()-lastEpochCheck>1000){
    lastEpochCheck=millis();
    uint32_t newEpoch = millis()/(EPOCH_SECONDS*1000);
    if(newEpoch!=currentEpoch){
      currentEpoch=newEpoch;
      updateAdv();
      BLEDevice::startAdvertising();
    }
  }
  delay(100);
}
