
/*
 * RUNEFORGE V14 CORRECTIVO TOTAL - ScannerPRO_v9_COLLAB.ino
 * ESP32-D0WD-V3 COM5 MAC 3c:8a:1f:a1:aa:84
 * WIFI: 517388haieksja_2.4G / bebecillogordillo -> MQTT 192.168.100.5:1883
 * FIX: ClientID random para evitar session takeover
 */
#include <WiFi.h>
#include <PubSubClient.h>
#include <BLEDevice.h>
#include <BLEScan.h>
#include <ArduinoJson.h>
#include "config.h"

WiFiClient espClient;
PubSubClient client(espClient);
BLEScan* pBLEScan;
unsigned long lastPublish = 0;
String clientIdFull;

String genClientId(){
  uint64_t chipId = ESP.getEfuseMac();
  String macPart = String((uint32_t)chipId, HEX);
  macPart.toUpperCase();
  String rnd = String(random(0xFFFF), HEX);
  return String(DEF_MQTT_CLIENT_BASE) + "-" + macPart + "-" + rnd;
}

void setupWifi(){
  WiFi.mode(WIFI_STA);
  WiFi.begin(DEF_WIFI_SSID, DEF_WIFI_PASS);
  Serial.print("Conectando WiFi "); Serial.println(DEF_WIFI_SSID);
  unsigned long start = millis();
  while(WiFi.status()!=WL_CONNECTED && millis()-start < DEF_WIFI_TIMEOUT){
    delay(500); Serial.print(".");
  }
  if(WiFi.status()==WL_CONNECTED){
    Serial.println("\nWiFi OK"); Serial.print("IP: "); Serial.println(WiFi.localIP());
    Serial.print("GW: "); Serial.println(WiFi.gatewayIP());
  } else {
    Serial.println("\nWiFi FAIL - Reiniciando"); ESP.restart();
  }
}

bool mqttConnect(){
  if(client.connected()) return true;
  clientIdFull = genClientId();
  Serial.print("MQTT conectando a "); Serial.print(DEF_MQTT_SERVER); Serial.print(":"); Serial.print(DEF_MQTT_PORT);
  Serial.print(" como "); Serial.println(clientIdFull);
  client.setServer(DEF_MQTT_SERVER, DEF_MQTT_PORT);
  client.setKeepAlive(DEF_MQTT_KEEPALIVE);
  client.setSocketTimeout(10);
  // Buffer grande para JSON
  client.setBufferSize(2048);
  if(client.connect(clientIdFull.c_str())){
    Serial.println("MQTT conectado");
    client.subscribe(DEF_MQTT_TOPIC_SUB);
    return true;
  } else {
    Serial.print("MQTT fail rc="); Serial.print(client.state()); Serial.println(" reintento 3s");
    delay(3000);
    return false;
  }
}

void callback(char* topic, byte* payload, unsigned int length){
  // comandos futuros
}

void setup(){
  Serial.begin(115200);
  delay(1000);
  Serial.println("=== RUNEFORGE V14 CORRECTIVO TOTAL ===");
  setupWifi();
  client.setServer(DEF_MQTT_SERVER, DEF_MQTT_PORT);
  client.setCallback(callback);
  // BLE init
  BLEDevice::init("");
  pBLEScan = BLEDevice::getScan();
  pBLEScan->setActiveScan(BLE_ACTIVE_SCAN);
  pBLEScan->setInterval(BLE_SCAN_INTERVAL);
  pBLEScan->setWindow(BLE_SCAN_WINDOW);
  pBLEScan->setInterval(BLE_SCAN_INTERVAL);
  randomSeed(esp_random());
}

void loop(){
  if(WiFi.status()!=WL_CONNECTED){ setupWifi(); }
  if(!client.connected()){ mqttConnect(); }
  client.loop();

  if(millis()-lastPublish > TELEMETRY_INTERVAL){
    lastPublish = millis();
    // BLE Scan rapido
    BLEScanResults results = pBLEScan->start(BLE_SCAN_DURATION, false);
    int n = results.getCount();
    Serial.printf("BLE scan %d dispositivos\n", n);
    for(int i=0;i<n;i++){
      BLEAdvertisedDevice dev = results.getDevice(i);
      String mac = dev.getAddress().toString().c_str();
      int rssi = dev.getRSSI();
      String name = dev.getName().c_str();
      if(name.length()==0) name = mac;

      // Filtro Tile / Escort / Generic
      String family = "generic";
      if(name.indexOf("Tile")>=0 || mac.indexOf("b4:0e")>=0) family="tile";
      if(name.indexOf("Escort")>=0 || name.indexOf("TD-BLE")>=0) family="fuel";

      DynamicJsonDocument doc(512);
      doc["id"] = mac;
      doc["mac"] = mac;
      doc["name"] = name;
      doc["rssi"] = rssi;
      doc["rssiRaw"] = rssi;
      doc["family"] = family;
      doc["channel"] = 37 + (i%3);
      doc["node"] = DEF_DEVICE_ID;
      doc["ip"] = WiFi.localIP().toString();
      doc["ts"] = millis();
      if(family=="fuel"){
        doc["fuel"]["pct"] = 65;
        doc["fuel"]["liters"] = 260;
        doc["fuel"]["capacity"] = FUEL_CAPACITY_L;
      }
      String json; serializeJson(doc, json);
      if(client.connected()){
        client.publish(DEF_MQTT_TOPIC_PUB, json.c_str(), false);
        // Tambien publica en topico legacy para compatibilidad
        client.publish("scannerpro/dispositivos", json.c_str(), false);
      }
      Serial.println(json);
    }
    pBLEScan->clearResults();
  }
}
