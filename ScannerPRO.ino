/*
 * ============================================================
 *  SCANNER PRO — ESP32 Gateway BLE
 *  Subsistema: RUNEFORGE V2 · ble-bridge
 *  v8.3 FIELD — Multi-WiFi + AP Siempre ON + Fix WDT + /api/dispositivos
 *  Fecha: 2026-10-04
 * ============================================================
 *  FIX v8.3:
 *  - WDT 30s, registro TEMPRANO, reset en WiFi loop (fix task not found)
 *  - Orden init: WiFi.mode -> BLE init -> coex -> WiFi.begin (fix netstack cb 12308)
 *  - WiFi.disconnect solo entre intentos, no antes del primero
 *  - NUEVO: AP SIEMPRE ON (AP+STA dual) para trabajo fuera de casa
 *  - NUEVO: /api/dispositivos compatible con tu test Python (edad_seg, vivo, ts_server, etc)
 *  - CORS habilitado
 * ============================================================
 */

#include <WiFi.h>
#include <WebServer.h>
#include <ESPmDNS.h>
// #include <ElegantOTA.h> // DESACTIVADO v8.3.1 para probar partition No OTA
// #define USE_ELEGANT_OTA 0
#include <esp_task_wdt.h>
#include <ArduinoJson.h>
#include <PubSubClient.h>
#include <BLEDevice.h>
#include <BLEScan.h>
#include <BLEAdvertisedDevice.h>
#include "soc/soc.h"
#include "soc/rtc_cntl_reg.h"
#include "esp_coexist.h"

#include "config.h"
#include "index_html.h"
#include "settings_html.h"

#define AP_TIMEOUT_MS       15000UL
#define WIFI_TRY_TIMEOUT    10000UL
#define WDT_TIMEOUT_SECONDS 30
#define MAX_DEVICES         80

// ====== ESTRUCTURAS ======
struct DeviceEntry {
  String mac;
  String name;
  String family;
  int    rssiRaw;
  float  kalmanP;
  float  kalmanX;
  unsigned long firstSeen;
  unsigned long lastSeen;
  uint32_t count;
  bool   used;
};

DeviceEntry devices[MAX_DEVICES];
int devicesTotalScanned   = 0;
int devicesTotalFiltered  = 0;
int devicesTotalPublished = 0;
int devicesUniqueCount    = 0;

// ====== ESTADO GLOBAL ======
WiFiClient   espClient;
PubSubClient mqtt(espClient);
BLEScan*     pBLEScan;
WebServer    server(80);
bool         bleScanning = false; // v8.3.4 manual scan

bool modoAP             = false; // true si solo AP, false si STA o AP+STA
bool apActivo           = false;
bool mqttConnected      = false;
bool usarFallbackMQTT   = false;
unsigned long ultimoMQTTCheck = 0;
unsigned long ultimoWiFiCheck = 0;
unsigned long arranque = 0;

// ============================================================
// UTILIDADES
// ============================================================
int findDevice(const String& mac) {
  for (int i = 0; i < MAX_DEVICES; i++) {
    if (devices[i].used && devices[i].mac == mac) return i;
  }
  return -1;
}

int findFreeSlot() {
  for (int i = 0; i < MAX_DEVICES; i++) if (!devices[i].used) return i;
  int oldest = 0;
  unsigned long oldestTime = ULONG_MAX;
  for (int i = 0; i < MAX_DEVICES; i++) {
    if (devices[i].lastSeen < oldestTime) { oldestTime = devices[i].lastSeen; oldest = i; }
  }
  return oldest;
}

String classifyFamily(const String& name, const String& mac) {
  String n = name; n.toUpperCase();
  String m = mac; m.toLowerCase();
  if (m.startsWith("c3:00") || m.startsWith("bdva") || n.indexOf("CICLOPE") >= 0 || n.indexOf("BDVA") >= 0) return "ciclope";
  if (n.indexOf("LMU") >= 0 || n.indexOf("EX7") >= 0) return "lmu";
  if (n.indexOf("SAMSARA") >= 0 || n.indexOf("AT11") >= 0) return "samsara";
  if (n.indexOf("PB705") >= 0 || n.indexOf("KW-") >= 0 || n.indexOf("KENWORTH") >= 0) return "kw";
  if (n.indexOf("FIND MY") >= 0 || n.indexOf("APPLE") >= 0 || m.startsWith("4c:00")) return "apple";
  return "other";
}

bool matchesFilter(const String& mac, const String& name) {
  if (!cfg.filterEnabled) return true;
  String m = mac; m.toLowerCase();
  String n = name; n.toUpperCase();

  String macList = String(cfg.macPrefixes); macList.toLowerCase();
  int start = 0;
  while (start < (int)macList.length()) {
    int comma = macList.indexOf(',', start);
    String prefix = (comma < 0) ? macList.substring(start) : macList.substring(start, comma);
    prefix.trim();
    if (prefix.length() > 0 && m.startsWith(prefix)) return true;
    if (comma < 0) break;
    start = comma + 1;
  }

  String nameList = String(cfg.nameFilters); nameList.toUpperCase();
  start = 0;
  while (start < (int)nameList.length()) {
    int comma = nameList.indexOf(',', start);
    String filt = (comma < 0) ? nameList.substring(start) : nameList.substring(start, comma);
    filt.trim();
    if (filt.length() > 0 && n.indexOf(filt) >= 0) return true;
    if (comma < 0) break;
    start = comma + 1;
  }
  return false;
}

float kalmanUpdate(float z, float& P, float& X) {
  P = P + cfg.kQ;
  float K = P / (P + cfg.kR);
  X = X + K * (z - X);
  P = (1.0f - K) * P;
  return X;
}

// Generar timestamp similar a Python bridge
String genTsServer() {
  // Formato ISO like 2026-10-04T00:52:18.089431
  // Usamos uptime + fecha base fija
  unsigned long ms = millis();
  unsigned long secs = ms / 1000;
  unsigned long millisPart = ms % 1000;
  // Simple fake date: base 2026-10-04
  int h = (secs / 3600) % 24;
  int m = (secs / 60) % 60;
  int s = secs % 60;
  char buf[40];
  snprintf(buf, sizeof(buf), "2026-10-04T%02d:%02d:%02d.%03lu000", h, m, s, millisPart);
  return String(buf);
}

// ============================================================
// BLE CALLBACK
// ============================================================
class ScanCallbacks : public BLEAdvertisedDeviceCallbacks {
  void onResult(BLEAdvertisedDevice dev) {
    devicesTotalScanned++;
    String mac  = dev.getAddress().toString().c_str();
    String name = dev.getName().c_str();
    int    rssi = dev.getRSSI();
    mac.toLowerCase();

    bool isTarget = matchesFilter(mac, name);

    if (cfg.debugLogAll || isTarget) {
      Serial.printf("[SCAN] %-20s rssi=%4d name='%s'%s\n",
                    mac.c_str(), rssi, name.c_str(),
                    isTarget ? "  <<< OBJETIVO" : "");
    }
    if (!isTarget) return;
    if (rssi < cfg.rssiMin) return;

    devicesTotalFiltered++;

    int idx = findDevice(mac);
    unsigned long ahora = millis();

    if (idx < 0) {
      idx = findFreeSlot();
      devices[idx].mac = mac;
      devices[idx].name = name;
      devices[idx].family = classifyFamily(name, mac);
      devices[idx].rssiRaw = rssi;
      devices[idx].kalmanP = cfg.kP;
      devices[idx].kalmanX = (float)rssi;
      devices[idx].firstSeen = ahora;
      devices[idx].lastSeen = ahora;
      devices[idx].count = 1;
      devices[idx].used = true;
      devicesUniqueCount = 0;
      for (int i = 0; i < MAX_DEVICES; i++) if (devices[i].used) devicesUniqueCount++;
    } else {
      devices[idx].rssiRaw = rssi;
      devices[idx].lastSeen = ahora;
      devices[idx].count++;
      if (name.length() > 0 && devices[idx].name.length() == 0) {
        devices[idx].name = name;
        devices[idx].family = classifyFamily(name, mac);
      }
    }

    float rssiK = kalmanUpdate((float)rssi, devices[idx].kalmanP, devices[idx].kalmanX);

    if (cfg.mqttEnabled && mqttConnected) {
      StaticJsonDocument<256> doc;
      doc["mac"]         = mac;
      doc["name"]        = name;
      doc["family"]      = devices[idx].family;
      doc["rssi_raw"]    = rssi;
      doc["rssi_kalman"] = rssiK;
      doc["count"]       = devices[idx].count;
      doc["wifi"]        = cfg.ssidActivo;
      doc["broker"]      = usarFallbackMQTT ? "fallback" : "primary";

      char payload[256];
      serializeJson(doc, payload);
      if (mqtt.publish(cfg.mqttTopic, payload)) {
        devicesTotalPublished++;
        Serial.printf("[TX] %-22s raw=%d kalman=%.1f\n", mac.c_str(), rssi, rssiK);
      }
    }
  }
};

// ============================================================
// WiFi AP
// ============================================================
void iniciarAP() {
  // Siempre AP+STA si apAlwaysOn, si no solo AP cuando falla STA
  WiFiMode_t modo = cfg.apAlwaysOn ? WIFI_AP_STA : WIFI_AP;
  WiFi.mode(modo);
  bool ok = WiFi.softAP(cfg.apSSID, cfg.apPass, cfg.apChannel, 0, 8);
  apActivo = ok;
  if (ok) {
    Serial.printf("[AP] SSID: %s PASS: %s CH:%d IP: %s Mode:%s\n",
                  cfg.apSSID, cfg.apPass, cfg.apChannel,
                  WiFi.softAPIP().toString().c_str(),
                  cfg.apAlwaysOn ? "AP+STA (FIELD)" : "AP ONLY");
  } else {
    Serial.println("[AP] FALLO al crear AP");
  }
}

// ============================================================
// MULTI-WIFI: intenta SSID1 -> SSID2 -> SSID3
// FIX v8.3: no disconnect en primer intento, wdt reset con tarea ya registrada
// ============================================================
bool conectarWiFiMulti() {
  const char* ssids[]  = { cfg.ssid,   cfg.wifiSSID2,   cfg.wifiSSID3   };
  const char* passes[] = { cfg.pass,   cfg.wifiPass2,   cfg.wifiPass3   };

  // Si AP siempre ON, ya estamos en AP_STA, solo configurar STA params
  if (cfg.apAlwaysOn) {
    WiFi.mode(WIFI_AP_STA);
  } else {
    WiFi.mode(WIFI_STA);
  }
  WiFi.setTxPower(WIFI_POWER_11dBm);
  WiFi.setSleep(false);

  bool firstAttempt = true;
  for (int i = 0; i < 3; i++) {
    if (strlen(ssids[i]) == 0) continue;

    Serial.printf("[WiFi] Slot %d -> '%s' ...\n", i + 1, ssids[i]);

    if (!firstAttempt) {
      WiFi.disconnect(false, false);
      delay(200);
    }
    firstAttempt = false;

    WiFi.begin(ssids[i], passes[i]);

    unsigned long t0 = millis();
    while (WiFi.status() != WL_CONNECTED && millis() - t0 < WIFI_TRY_TIMEOUT) {
      delay(300);
      Serial.print(".");
      esp_task_wdt_reset(); // ya registrada
    }
    Serial.println();

    if (WiFi.status() == WL_CONNECTED) {
      strncpy(cfg.ssidActivo, ssids[i], sizeof(cfg.ssidActivo) - 1);
      cfg.ssidActivo[sizeof(cfg.ssidActivo) - 1] = 0;
      Serial.printf("[WiFi] OK slot %d: %s  IP: %s  RSSI: %d\n",
                    i + 1, ssids[i], WiFi.localIP().toString().c_str(), WiFi.RSSI());
      // Si AP always on, mantener AP activo
      if (cfg.apAlwaysOn && !apActivo) {
        WiFi.softAP(cfg.apSSID, cfg.apPass, cfg.apChannel, 0, 8);
        apActivo = true;
      }
      return true;
    }
    Serial.println(" FALLO");
  }
  cfg.ssidActivo[0] = 0;
  Serial.println("[WiFi] Ninguna red STA disponible");
  return false;
}

// ============================================================
// MQTT con fallback
// ============================================================
void conectarMQTT() {
  if (!cfg.mqttEnabled) return;
  if (WiFi.status() != WL_CONNECTED) return;
  if (mqtt.connected()) { mqttConnected = true; return; }

  const char* srv  = usarFallbackMQTT ? cfg.mqttFallbackServer : cfg.mqttServer;
  uint16_t    port = usarFallbackMQTT ? cfg.mqttFallbackPort   : cfg.mqttPort;

  if (strlen(srv) == 0) return;

  Serial.printf("[MQTT] Conectando a %s:%d (%s) ...\n",
                srv, port, usarFallbackMQTT ? "FALLBACK" : "PRIMARY");
  mqtt.setServer(srv, port);
  mqtt.setKeepAlive(60);
  mqtt.setBufferSize(512);

  String cid = String(cfg.mqttClient) + "-" + String((uint32_t)ESP.getEfuseMac(), HEX);

  if (mqtt.connect(cid.c_str())) {
    Serial.println("[MQTT] OK");
    mqttConnected = true;
  } else {
    Serial.printf("[MQTT] FALLO rc=%d\n", mqtt.state());
    mqttConnected = false;
    if (cfg.mqttFallbackEnabled && !usarFallbackMQTT && strlen(cfg.mqttFallbackServer) > 0) {
      usarFallbackMQTT = true;
      Serial.println("[MQTT] Cambiando a fallback para el proximo intento");
    } else if (cfg.mqttFallbackEnabled && usarFallbackMQTT) {
      usarFallbackMQTT = false;
    }
  }
}

void mqttTick() {
  if (!cfg.mqttEnabled) return;
  if (WiFi.status() != WL_CONNECTED) return;

  if (mqtt.connected()) {
    mqtt.loop();
    mqttConnected = true;
  } else {
    if (millis() - ultimoMQTTCheck > 5000) {
      ultimoMQTTCheck = millis();
      conectarMQTT();
    }
  }
}

// ============================================================
// API HANDLERS
// ============================================================
void addCors() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.sendHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  server.sendHeader("Access-Control-Allow-Headers", "Content-Type");
}

void handleStatus() {
  addCors();
  StaticJsonDocument<1024> doc;
  doc["state"]  = modoAP ? "AP_CONFIG" : (WiFi.status()==WL_CONNECTED ? "SCANNING" : "AP_ONLY");
  doc["mode"]   = cfg.apAlwaysOn ? (WiFi.status()==WL_CONNECTED ? "AP+STA" : "AP+STA_WAIT") : (modoAP ? "AP" : "STA");
  doc["ble_scanning"] = bleScanning;
  doc["ble_auto"] = false;
  doc["ip"]     = WiFi.localIP().toString();
  doc["ap_ip"]  = WiFi.softAPIP().toString();
  doc["ap_enabled"] = apActivo;
  doc["ap_ssid"] = cfg.apSSID;
  doc["rssi"]   = (WiFi.status()==WL_CONNECTED) ? WiFi.RSSI() : -100;
  doc["uptime"] = millis() / 1000;
  doc["heap"]   = ESP.getFreeHeap();
  doc["wifi_ssid"] = cfg.ssidActivo;
  doc["mqtt_connected"]  = mqttConnected;
  doc["mqtt_enabled"]    = cfg.mqttEnabled;
  doc["mqtt_server"]     = usarFallbackMQTT ? cfg.mqttFallbackServer : cfg.mqttServer;
  doc["mqtt_port"]       = usarFallbackMQTT ? cfg.mqttFallbackPort : cfg.mqttPort;
  doc["mqtt_using_fallback"]    = usarFallbackMQTT;
  doc["mqtt_fallback_enabled"]  = cfg.mqttFallbackEnabled;
  doc["scanned_total"]   = devicesTotalScanned;
  doc["filtered_total"]  = devicesTotalFiltered;
  doc["published_total"] = devicesTotalPublished;
  doc["unique_devices"]  = devicesUniqueCount;
  doc["filter_enabled"] = cfg.filterEnabled;
  doc["rssi_min"]       = cfg.rssiMin;
  doc["active_scan"]    = cfg.activeScan;
  String out; serializeJson(doc, out);
  server.send(200, "application/json", out);
}

void handleDevices() {
  addCors();
  DynamicJsonDocument doc(8192);
  JsonArray arr = doc.createNestedArray("devices");
  for (int i = 0; i < MAX_DEVICES; i++) {
    if (!devices[i].used) continue;
    JsonObject d = arr.createNestedObject();
    d["mac"]         = devices[i].mac;
    d["name"]        = devices[i].name;
    d["family"]      = devices[i].family;
    d["rssi_raw"]    = devices[i].rssiRaw;
    d["rssi_kalman"] = devices[i].kalmanX;
    d["count"]       = devices[i].count;
    d["age_s"]       = (millis() - devices[i].lastSeen) / 1000;
    d["alive"]       = (millis() - devices[i].lastSeen) < 30000;
  }
  String out; serializeJson(doc, out);
  server.send(200, "application/json", out);
}

// NUEVO: endpoint identico a tu prueba Python /api/dispositivos
void handleDispositivos() {
  addCors();
  DynamicJsonDocument doc(16384);
  JsonArray arr = doc.to<JsonArray>();
  unsigned long ahora = millis();
  for (int i = 0; i < MAX_DEVICES; i++) {
    if (!devices[i].used) continue;
    float edad = (ahora - devices[i].lastSeen) / 1000.0f;
    bool vivo = edad < 30.0f;
    JsonObject o = arr.createNestedObject();
    o["edad_seg"] = edad;
    o["mac"] = devices[i].mac;
    o["name"] = devices[i].name;
    o["family"] = devices[i].family;
    o["rssi_kalman"] = devices[i].kalmanX;
    o["rssi_raw"] = devices[i].rssiRaw;
    o["ts_server"] = genTsServer();
    o["ts_unix"] = ahora / 1000.0;
    o["vivo"] = vivo;
    o["count"] = devices[i].count;
  }
  String out; serializeJson(doc, out);
  server.send(200, "application/json", out);
}

void handleClear() {
  addCors();
  for (int i = 0; i < MAX_DEVICES; i++) {
    devices[i].used = false;
    devices[i].mac = ""; devices[i].name = ""; devices[i].family = ""; devices[i].count = 0;
  }
  devicesUniqueCount = devicesTotalScanned = devicesTotalFiltered = devicesTotalPublished = 0;
  server.send(200, "application/json", "{\"ok\":true}");
}

void handlePublishTest() {
  addCors();
  if (!mqttConnected) {
    server.send(503, "application/json", "{\"ok\":false,\"msg\":\"MQTT no conectado\"}");
    return;
  }
  StaticJsonDocument<256> doc;
  doc["mac"]         = "c3:00:00:6b:9b:c8";
  doc["name"]        = "TEST-CICLOPE";
  doc["family"]      = "ciclope";
  doc["rssi_raw"]    = -68;
  doc["rssi_kalman"] = -70.2;
  doc["test"]        = true;
  doc["wifi"]        = cfg.ssidActivo;
  char payload[256]; serializeJson(doc, payload);
  bool ok = mqtt.publish(cfg.mqttTopic, payload);
  String resp = String("{\"ok\":") + (ok ? "true" : "false") + "}";
  server.send(200, "application/json", resp);
}

void handleWiFiScan() {
  addCors();
  Serial.println("[WiFi] Escaneando redes...");
  int n = WiFi.scanNetworks(false, false);
  DynamicJsonDocument doc(6144);
  JsonArray arr = doc.createNestedArray("networks");
  for (int i = 0; i < n && i < 25; i++) {
    JsonObject o = arr.createNestedObject();
    o["ssid"]      = WiFi.SSID(i);
    o["rssi"]      = WiFi.RSSI(i);
    o["channel"]   = WiFi.channel(i);
    o["encrypted"] = (WiFi.encryptionType(i) != WIFI_AUTH_OPEN);
  }
  doc["count"] = n;
  String out; serializeJson(doc, out);
  WiFi.scanDelete();
  server.send(200, "application/json", out);
}

void handleWiFiReconnect() {
  addCors();
  Serial.println("[WiFi] Reconexion forzada STA...");
  bool ok = conectarWiFiMulti();
  String resp = String("{\"ok\":") + (ok ? "true" : "false")
              + ",\"ssid\":\"" + cfg.ssidActivo + "\"}";
  server.send(200, "application/json", resp);
}

void handleMQTTSwitch() {
  addCors();
  usarFallbackMQTT = !usarFallbackMQTT;
  mqtt.disconnect();
  mqttConnected = false;
  Serial.printf("[MQTT] Switch manual a %s\n", usarFallbackMQTT ? "FALLBACK" : "PRIMARY");
  String resp = String("{\"ok\":true,\"using_fallback\":")
              + (usarFallbackMQTT ? "true" : "false") + "}";
  server.send(200, "application/json", resp);
}

void handleSettingsGet() {
  addCors();
  StaticJsonDocument<2048> doc;
  doc["ssid"]  = cfg.ssid;
  doc["pass"]  = "********";
  doc["ssid2"] = cfg.wifiSSID2;
  doc["pass2"] = strlen(cfg.wifiPass2) > 0 ? "********" : "";
  doc["ssid3"] = cfg.wifiSSID3;
  doc["pass3"] = strlen(cfg.wifiPass3) > 0 ? "********" : "";
  doc["mdns"]  = cfg.mdns;
  doc["apSSID"] = cfg.apSSID;
  doc["apPass"] = cfg.apPass;
  doc["apChannel"] = cfg.apChannel;
  doc["apAlwaysOn"] = cfg.apAlwaysOn;
  doc["mqttServer"]         = cfg.mqttServer;
  doc["mqttPort"]           = cfg.mqttPort;
  doc["mqttFallbackServer"] = cfg.mqttFallbackServer;
  doc["mqttFallbackPort"]   = cfg.mqttFallbackPort;
  doc["mqttFallbackEnabled"]= cfg.mqttFallbackEnabled;
  doc["mqttTopic"]          = cfg.mqttTopic;
  doc["mqttClient"]         = cfg.mqttClient;
  doc["mqttEnabled"]        = cfg.mqttEnabled;
  doc["activeScan"]   = cfg.activeScan;
  doc["scanInterval"] = cfg.scanInterval;
  doc["scanWindow"]   = cfg.scanWindow;
  doc["scanTime"]     = cfg.scanTime;
  doc["filterEnabled"] = cfg.filterEnabled;
  doc["rssiMin"]       = cfg.rssiMin;
  doc["macPrefixes"]   = cfg.macPrefixes;
  doc["nameFilters"]   = cfg.nameFilters;
  doc["kQ"]  = cfg.kQ;
  doc["kR"]  = cfg.kR;
  doc["kP"]  = cfg.kP;
  doc["kX0"] = cfg.kX0;
  doc["debugLogAll"] = cfg.debugLogAll;
  doc["ip"]      = WiFi.localIP().toString();
  doc["ap_ip"]   = WiFi.softAPIP().toString();
  doc["ap_mode"] = modoAP;
  String out; serializeJson(doc, out);
  server.send(200, "application/json", out);
}

void handleSettingsPost() {
  addCors();
  if (!server.hasArg("plain")) {
    server.send(400, "application/json", "{\"ok\":false,\"msg\":\"sin body\"}");
    return;
  }
  StaticJsonDocument<3072> doc;
  DeserializationError err = deserializeJson(doc, server.arg("plain"));
  if (err) {
    String r = String("{\"ok\":false,\"msg\":\"JSON invalido: ") + err.c_str() + "\"}";
    server.send(400, "application/json", r);
    return;
  }

  bool wifiChanged = false;
  String s;

  if (doc.containsKey("ssid"))  { s = doc["ssid"].as<String>();  if (s.length() > 0 && s != String(cfg.ssid))   { strncpy(cfg.ssid,  s.c_str(), sizeof(cfg.ssid)-1);  cfg.ssid[sizeof(cfg.ssid)-1]=0;   wifiChanged = true; } }
  if (doc.containsKey("pass"))  { s = doc["pass"].as<String>();  if (s.length() > 0 && s != "********")          { strncpy(cfg.pass,  s.c_str(), sizeof(cfg.pass)-1);  cfg.pass[sizeof(cfg.pass)-1]=0;   wifiChanged = true; } }
  if (doc.containsKey("ssid2")) { s = doc["ssid2"].as<String>(); if (s != String(cfg.wifiSSID2))                  { strncpy(cfg.wifiSSID2, s.c_str(), sizeof(cfg.wifiSSID2)-1); cfg.wifiSSID2[sizeof(cfg.wifiSSID2)-1]=0; wifiChanged = true; } }
  if (doc.containsKey("pass2")) { s = doc["pass2"].as<String>(); if (s.length() > 0 && s != "********")          { strncpy(cfg.wifiPass2, s.c_str(), sizeof(cfg.wifiPass2)-1); cfg.wifiPass2[sizeof(cfg.wifiPass2)-1]=0; wifiChanged = true; } }
  if (doc.containsKey("ssid3")) { s = doc["ssid3"].as<String>(); if (s != String(cfg.wifiSSID3))                  { strncpy(cfg.wifiSSID3, s.c_str(), sizeof(cfg.wifiSSID3)-1); cfg.wifiSSID3[sizeof(cfg.wifiSSID3)-1]=0; wifiChanged = true; } }
  if (doc.containsKey("pass3")) { s = doc["pass3"].as<String>(); if (s.length() > 0 && s != "********")          { strncpy(cfg.wifiPass3, s.c_str(), sizeof(cfg.wifiPass3)-1); cfg.wifiPass3[sizeof(cfg.wifiPass3)-1]=0; wifiChanged = true; } }
  if (doc.containsKey("mdns"))  { s = doc["mdns"].as<String>();  if (s.length() > 0) { strncpy(cfg.mdns, s.c_str(), sizeof(cfg.mdns)-1); cfg.mdns[sizeof(cfg.mdns)-1]=0; } }

  // AP config
  if (doc.containsKey("apSSID")) { s = doc["apSSID"].as<String>(); if (s.length()>0) { strncpy(cfg.apSSID, s.c_str(), sizeof(cfg.apSSID)-1); cfg.apSSID[sizeof(cfg.apSSID)-1]=0; wifiChanged=true; } }
  if (doc.containsKey("apPass")) { s = doc["apPass"].as<String>(); if (s.length()>0) { strncpy(cfg.apPass, s.c_str(), sizeof(cfg.apPass)-1); cfg.apPass[sizeof(cfg.apPass)-1]=0; wifiChanged=true; } }
  if (doc.containsKey("apChannel")) cfg.apChannel = constrain((int)doc["apChannel"],1,13);
  if (doc.containsKey("apAlwaysOn")) { bool b = doc["apAlwaysOn"].as<bool>(); if (b!=cfg.apAlwaysOn){ cfg.apAlwaysOn=b; wifiChanged=true; } }

  if (doc.containsKey("mqttServer"))         { s = doc["mqttServer"].as<String>();         strncpy(cfg.mqttServer, s.c_str(), sizeof(cfg.mqttServer)-1);         cfg.mqttServer[sizeof(cfg.mqttServer)-1]=0; }
  if (doc.containsKey("mqttPort"))           cfg.mqttPort = constrain((int)doc["mqttPort"], 1, 65535);
  if (doc.containsKey("mqttFallbackServer")) { s = doc["mqttFallbackServer"].as<String>(); strncpy(cfg.mqttFallbackServer, s.c_str(), sizeof(cfg.mqttFallbackServer)-1); cfg.mqttFallbackServer[sizeof(cfg.mqttFallbackServer)-1]=0; }
  if (doc.containsKey("mqttFallbackPort"))   cfg.mqttFallbackPort = constrain((int)doc["mqttFallbackPort"], 1, 65535);
  if (doc.containsKey("mqttFallbackEnabled")) cfg.mqttFallbackEnabled = doc["mqttFallbackEnabled"].as<bool>();
  if (doc.containsKey("mqttTopic"))          { s = doc["mqttTopic"].as<String>();          strncpy(cfg.mqttTopic, s.c_str(), sizeof(cfg.mqttTopic)-1);           cfg.mqttTopic[sizeof(cfg.mqttTopic)-1]=0; }
  if (doc.containsKey("mqttClient"))         { s = doc["mqttClient"].as<String>();         strncpy(cfg.mqttClient, s.c_str(), sizeof(cfg.mqttClient)-1);         cfg.mqttClient[sizeof(cfg.mqttClient)-1]=0; }
  if (doc.containsKey("mqttEnabled"))        cfg.mqttEnabled = doc["mqttEnabled"].as<bool>();

  if (doc.containsKey("activeScan"))   cfg.activeScan = doc["activeScan"].as<bool>();
  if (doc.containsKey("scanInterval")) cfg.scanInterval = constrain((int)doc["scanInterval"], 50, 1000);
  if (doc.containsKey("scanWindow"))   cfg.scanWindow = constrain((int)doc["scanWindow"], 50, cfg.scanInterval);
  if (doc.containsKey("scanTime"))     cfg.scanTime = constrain((int)doc["scanTime"], 0, 60);

  if (doc.containsKey("filterEnabled")) cfg.filterEnabled = doc["filterEnabled"].as<bool>();
  if (doc.containsKey("rssiMin"))       cfg.rssiMin = constrain((int)doc["rssiMin"], -120, -40);
  if (doc.containsKey("macPrefixes")) { s = doc["macPrefixes"].as<String>(); strncpy(cfg.macPrefixes, s.c_str(), sizeof(cfg.macPrefixes)-1); cfg.macPrefixes[sizeof(cfg.macPrefixes)-1]=0; }
  if (doc.containsKey("nameFilters")) { s = doc["nameFilters"].as<String>(); strncpy(cfg.nameFilters, s.c_str(), sizeof(cfg.nameFilters)-1); cfg.nameFilters[sizeof(cfg.nameFilters)-1]=0; }

  if (doc.containsKey("kQ"))  cfg.kQ  = constrain(doc["kQ"].as<float>(),  0.0001f, 100.0f);
  if (doc.containsKey("kR"))  cfg.kR  = constrain(doc["kR"].as<float>(),  0.001f,  100.0f);
  if (doc.containsKey("kP"))  cfg.kP  = constrain(doc["kP"].as<float>(),  0.01f,  1000.0f);
  if (doc.containsKey("kX0")) cfg.kX0 = constrain(doc["kX0"].as<float>(), -120.0f, -40.0f);

  if (doc.containsKey("debugLogAll")) cfg.debugLogAll = doc["debugLogAll"].as<bool>();

  configSave();

  String resp = String("{\"ok\":true,\"reboot\":") + (wifiChanged ? "true" : "false") + "}";
  server.send(200, "application/json", resp);

  if (wifiChanged) {
    Serial.println(F("[CONFIG] WiFi/AP cambiado, reiniciando..."));
    delay(2000);
    ESP.restart();
  }
}

void handleSettingsReset() {
  addCors();
  configFactoryReset();
  configSave();
  server.send(200, "application/json", "{\"ok\":true}");
  delay(500);
  ESP.restart();
}


void handleScanStart() {
  addCors();
  if (!bleScanning) {
    try {
      pBLEScan->start(0, false);
      bleScanning = true;
      Serial.println("[BLE] Scan INICIADO manualmente desde API");
      server.send(200, "application/json", "{\"ok\":true,\"scanning\":true,\"msg\":\"Scan iniciado\"}");
    } catch (...) {
      server.send(500, "application/json", "{\"ok\":false,\"msg\":\"Error iniciando scan\"}");
    }
  } else {
    server.send(200, "application/json", "{\"ok\":true,\"scanning\":true,\"msg\":\"Ya estaba escaneando\"}");
  }
}

void handleScanStop() {
  addCors();
  if (bleScanning) {
    try {
      pBLEScan->stop();
      bleScanning = false;
      Serial.println("[BLE] Scan DETENIDO manualmente desde API");
      server.send(200, "application/json", "{\"ok\":true,\"scanning\":false,\"msg\":\"Scan detenido\"}");
    } catch (...) {
      server.send(500, "application/json", "{\"ok\":false,\"msg\":\"Error deteniendo scan\"}");
    }
  } else {
    server.send(200, "application/json", "{\"ok\":true,\"scanning\":false,\"msg\":\"Ya estaba detenido\"}");
  }
}

void handleScanStatus() {
  addCors();
  String j = String("{\"scanning\":") + (bleScanning?"true":"false") + ",\"scan_active\":" + (cfg.activeScan?"true":"false") + "}";
  server.send(200, "application/json", j);
}

// ============================================================
// SETUP  v8.3 FIELD - ORDEN CORREGIDO

// ============================================================
void setup() {
  Serial.begin(115200);
  delay(800);
  WRITE_PERI_REG(RTC_CNTL_BROWN_OUT_REG, 0);
  arranque = millis();

  Serial.println("\n============================================================");
  Serial.println("  SCANNER PRO ESP32 · RUNEFORGE V2 · v8.3.4 MANUAL SCAN - No auto inicia");
  Serial.println("============================================================");

  configLoad();
  // FIX v8.3.3: forzar scan ligero para que HTTP no haga timeout (25% duty)
  if (cfg.scanInterval < 300) cfg.scanInterval = 400;
  if (cfg.scanWindow > 120) cfg.scanWindow = 100;
  if (cfg.scanWindow > cfg.scanInterval) cfg.scanWindow = 100;

  Serial.printf("WiFi slots: [1]%s [2]%s [3]%s\n",
                cfg.ssid,
                strlen(cfg.wifiSSID2) > 0 ? cfg.wifiSSID2 : "-",
                strlen(cfg.wifiSSID3) > 0 ? cfg.wifiSSID3 : "-");
  Serial.printf("AP config: %s / %s ch%d alwaysOn=%d\n", cfg.apSSID, cfg.apPass, cfg.apChannel, cfg.apAlwaysOn);
  Serial.printf("MQTT: %s:%d%s\n", cfg.mqttServer, cfg.mqttPort,
                cfg.mqttFallbackEnabled ? " (+fallback)" : "");

  // 1. Watchdog 30s y registrar ANTES de todo lo bloqueante
  esp_task_wdt_config_t twdt = {
    .timeout_ms = WDT_TIMEOUT_SECONDS * 1000,
    .idle_core_mask = (1 << portNUM_PROCESSORS) - 1,
    .trigger_panic = true
  };
  esp_task_wdt_reconfigure(&twdt);
  esp_task_wdt_add(NULL);
  esp_task_wdt_reset();

  // 2. WiFi modo segun config (AP+STA para campo)
  if (cfg.apAlwaysOn) {
    WiFi.mode(WIFI_AP_STA);
    Serial.println("[WiFi] Modo AP+STA (campo) iniciado");
    iniciarAP();
  } else {
    WiFi.mode(WIFI_STA);
  }

  // 3. BLE init ANTES de coex preference (fix netstack cb reg failed)
  BLEDevice::init("ScannerPRO");

  // 4. Coexistencia BT preferente (despues de BLE init y WiFi.mode)
  esp_coex_preference_set(ESP_COEX_PREFER_BALANCE); // FIX v8.3.3 balance para HTTP

  // 5. Conectar WiFi STA multi-slot
  bool online = conectarWiFiMulti();

  if (online) {
    if (MDNS.begin(cfg.mdns)) {
      MDNS.addService("http", "tcp", 80);
      Serial.printf("mDNS: http://%s.local\n", cfg.mdns);
    }
    modoAP = false;
  } else {
    // Si no hay STA y AP no estaba activo, crear AP de emergencia
    if (!apActivo) {
      Serial.println(F("\n[FALLBACK] Creando AP de emergencia..."));
      iniciarAP();
    }
    modoAP = !cfg.apAlwaysOn; // si apAlwaysOn, no es fallback, es modo normal campo
    Serial.printf("AP SSID: %s\nAP PASS: %s\nAP IP  : %s\n",
                  cfg.apSSID, cfg.apPass, WiFi.softAPIP().toString().c_str());
    Serial.println(F("Conectate a esa red y abre http://192.168.4.1"));
  }

  // 5.5 Delay para estabilizar WiFi dual
  delay(300);
  esp_task_wdt_reset();

  // 6. Rutas Web + CORS - ANTES de BLE para que siempre levante aunque BLE falle (v8.3.2)
  server.on("/", HTTP_GET, []() {
    server.sendHeader("Access-Control-Allow-Origin","*");
    server.send_P(200, "text/html", index_html);
  });
  server.on("/settings", HTTP_GET, []() {
    server.sendHeader("Access-Control-Allow-Origin","*");
    server.send_P(200, "text/html", settings_html);
  });

  server.on("/api/status", HTTP_GET, handleStatus);
  server.on("/api/devices", HTTP_GET, handleDevices);
  server.on("/api/dispositivos", HTTP_GET, handleDispositivos); // NUEVO - compatible con tu test
  server.on("/api/devices/clear", HTTP_POST, handleClear);
  server.on("/api/publish_test", HTTP_POST, handlePublishTest);
  server.on("/api/wifi_scan", HTTP_GET, handleWiFiScan);
  server.on("/api/wifi_reconnect", HTTP_POST, handleWiFiReconnect);
  server.on("/api/mqtt_switch", HTTP_POST, handleMQTTSwitch);
  server.on("/api/settings", HTTP_GET, handleSettingsGet);
  server.on("/api/settings", HTTP_POST, handleSettingsPost);
  server.on("/api/settings/reset", HTTP_POST, handleSettingsReset);
  server.on("/api/ping", HTTP_GET, [](){
    addCors();
    server.send(200, "text/plain", "pong v8.3.4 MANUAL " + WiFi.localIP().toString() + " AP:" + WiFi.softAPIP().toString());
  });
  server.on("/api/scan/start", HTTP_POST, handleScanStart);
  server.on("/api/scan/start", HTTP_GET, handleScanStart); // permite GET tambien para boton simple
  server.on("/api/scan/stop", HTTP_POST, handleScanStop);
  server.on("/api/scan/stop", HTTP_GET, handleScanStop);
  server.on("/api/scan/status", HTTP_GET, handleScanStatus);
  server.on("/api/scan", HTTP_GET, handleScanStatus);

  // CORS preflight
  server.onNotFound([](){
    if (server.method() == HTTP_OPTIONS) {
      addCors();
      server.send(200);
    } else {
      server.send(404, "text/plain", "Not Found");
    }
  });

  // ElegantOTA.begin(&server); // DESACTIVADO v8.3.1
  Serial.println("[OTA] Desactivado v8.3.4 MANUAL - Coex BALANCE");
  server.begin();
  Serial.println(F("WebServer listo puerto 80 - v8.3.4 MANUAL SCAN"));
  Serial.println(F("Endpoints: / , /settings , /api/status , /api/devices , /api/dispositivos , /api/wifi_scan , /api/ping"));
  Serial.printf("STA IP: %s  AP IP: %s\n", WiFi.localIP().toString().c_str(), WiFi.softAPIP().toString().c_str());
  Serial.println("============================================================\n");
  esp_task_wdt_reset();

  // 7. BLE Scan MANUAL v8.3.4 - NO inicia automatico, se activa desde /api/scan/start
  Serial.println("[BLE] Configurando en modo MANUAL...");
  try {
    pBLEScan = BLEDevice::getScan();
    pBLEScan->setAdvertisedDeviceCallbacks(new ScanCallbacks(), true);
    pBLEScan->setActiveScan(cfg.activeScan);
    pBLEScan->setInterval(cfg.scanInterval);
    pBLEScan->setWindow(cfg.scanWindow);
    // pBLEScan->start(0, false); // DESACTIVADO v8.3.4 - manual
    bleScanning = false;
    Serial.printf("[BLE] En espera MANUAL (activo=%d int=%d win=%d) - usa /api/scan/start\n",
                  cfg.activeScan, cfg.scanInterval, cfg.scanWindow);
  } catch (...) {
    Serial.println("[BLE] ERROR configurando scan, pero WebServer ya esta arriba");
  }

  esp_task_wdt_reset();
}

// ============================================================
// LOOP
// ============================================================
void loop() {
  esp_task_wdt_reset();
  server.handleClient();
  yield();
  server.handleClient();
  // ElegantOTA.loop();
  mqttTick();
  yield();

  // Reconexion WiFi STA automatica cada 15s si se cae
  if (WiFi.status() != WL_CONNECTED && millis() - ultimoWiFiCheck > 15000) {
    ultimoWiFiCheck = millis();
    Serial.println("[WiFi] Reintentando STA...");
    conectarWiFiMulti();
  }
  // delay(5) eliminado en v8.3.3 para respuesta HTTP rapida
}
