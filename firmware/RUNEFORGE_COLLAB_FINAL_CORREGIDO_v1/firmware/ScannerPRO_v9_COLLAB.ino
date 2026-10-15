/*
 * ============================================================
 *  SCANNER PRO — ESP32 Gateway BLE
 *  RUNEFORGE V2 · v9.0 COLLAB
 *  FEAA/0x50 RUNEFORGE parser + MQTT colaborativo + /api/dispositivos extendido
 *  Base: v8.3.8 RAFAGA + PATCH COLLAB v1.0
 * ============================================================
 */

#include <WiFi.h>
#include <WebServer.h>
#include <ESPmDNS.h>
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

#define WIFI_TRY_TIMEOUT    10000UL
#define WDT_TIMEOUT_SECONDS 30
#define MAX_DEVICES         80
#define SCAN_BURST_SEC      2
#define SCAN_PAUSE_MS       400

// ================== ESTRUCTURA ==================
struct DeviceEntry {
  String   mac;
  String   name;
  String   family;
  String   eid;
  uint8_t  batt;
  uint32_t tagEpoch;
  bool     isRuneforge;
  int      rssiRaw;
  float    kalmanP;
  float    kalmanX;
  unsigned long firstSeen;
  unsigned long lastSeen;
  uint32_t count;
  bool     used;
};

DeviceEntry devices[MAX_DEVICES];
int devicesTotalScanned   = 0;
int devicesTotalFiltered  = 0;
int devicesTotalPublished = 0;
int devicesUniqueCount    = 0;

// ================== ESTADO ==================
WiFiClient   espClient;
PubSubClient mqtt(espClient);
BLEScan*     pBLEScan = nullptr;
WebServer    server(80);
bool         bleScanning = false;
unsigned long lastScanBurst = 0;
bool         scanBurstActive = false;
bool         modoAP = false;
bool         apActivo = false;
bool         mqttConnected = false;
bool         usarFallbackMQTT = false;
unsigned long ultimoMQTTCheck = 0;
unsigned long ultimoWiFiCheck = 0;
unsigned long arranque = 0;

// ================== UTILIDADES ==================
int findDevice(const String& mac) {
  for (int i = 0; i < MAX_DEVICES; i++)
    if (devices[i].used && devices[i].mac == mac) return i;
  return -1;
}

int findFreeSlot() {
  for (int i = 0; i < MAX_DEVICES; i++) if (!devices[i].used) return i;
  int oldest = 0; unsigned long t = ULONG_MAX;
  for (int i = 0; i < MAX_DEVICES; i++)
    if (devices[i].lastSeen < t) { t = devices[i].lastSeen; oldest = i; }
  return oldest;
}

String classifyFamily(const String& name, const String& mac, bool rf = false) {
  if (rf) return "runeforge";
  String n = name; n.toUpperCase();
  String m = mac;  m.toLowerCase();
  if (n.indexOf("RUNEFORGE") >= 0 || n.startsWith("RF-")) return "runeforge";
  if (m.startsWith("c3:00") || n.indexOf("CICLOPE") >= 0 || n.indexOf("BDVA") >= 0) return "ciclope";
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
    int c = macList.indexOf(',', start);
    String p = (c < 0) ? macList.substring(start) : macList.substring(start, c);
    p.trim();
    if (p.length() > 0 && m.startsWith(p)) return true;
    if (c < 0) break;
    start = c + 1;
  }

  String nameList = String(cfg.nameFilters); nameList.toUpperCase();
  start = 0;
  while (start < (int)nameList.length()) {
    int c = nameList.indexOf(',', start);
    String f = (c < 0) ? nameList.substring(start) : nameList.substring(start, c);
    f.trim();
    if (f.length() > 0 && n.indexOf(f) >= 0) return true;
    if (c < 0) break;
    start = c + 1;
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

String genTsServer() {
  unsigned long ms = millis();
  unsigned long s  = ms / 1000;
  int hh = (s / 3600) % 24;
  int mm = (s / 60)   % 60;
  int ss = s % 60;
  char buf[40];
  snprintf(buf, sizeof(buf), "2026-10-04T%02d:%02d:%02d.%03lu000", hh, mm, ss, ms % 1000);
  return String(buf);
}

// ================== BLE CALLBACK ==================
class ScanCallbacks : public BLEAdvertisedDeviceCallbacks {
  void onResult(BLEAdvertisedDevice dev) {
    devicesTotalScanned++;

    String mac  = dev.getAddress().toString().c_str();
    String name = dev.getName().c_str();
    int    rssi = dev.getRSSI();
    mac.toLowerCase();

    String   eidHex   = "";
    uint8_t  batt     = 0;
    uint32_t tagEpoch = 0;
    bool     isRF     = false;

    if (dev.haveServiceUUID() &&
        dev.getServiceUUID().equals(BLEUUID((uint16_t)0xFEAA))) {
      String sd = dev.getServiceData();
      const uint8_t* p = (const uint8_t*)sd.c_str();
      size_t len = sd.length();

      int off = -1;
      if      (len >= 14 && p[0] == 0x50)                                 off = 0;
      else if (len >= 16 && p[0] == 0xAA && p[1] == 0xFE && p[2] == 0x50) off = 2;

      if (off >= 0 && len >= (size_t)(off + 14)) {
        char hex[17];
        for (int i = 0; i < 8; i++) sprintf(hex + i * 2, "%02X", p[off + 1 + i]);
        eidHex   = String(hex);
        batt     = p[off + 9];
        tagEpoch = ((uint32_t)p[off + 10] << 24) |
                   ((uint32_t)p[off + 11] << 16) |
                   ((uint32_t)p[off + 12] <<  8) |
                   ((uint32_t)p[off + 13]);
        isRF = true;
      }
    }

    bool isTarget = isRF || matchesFilter(mac, name);

    if (cfg.debugLogAll || isTarget) {
      Serial.printf("[SCAN] %-20s rssi=%4d name='%s'%s%s\n",
                    mac.c_str(), rssi, name.c_str(),
                    isRF ? " [RF]" : "",
                    isTarget ? "  <<< OBJETIVO" : "");
    }
    if (!isTarget) return;
    if (rssi < cfg.rssiMin) return;

    devicesTotalFiltered++;
    int idx = findDevice(mac);
    unsigned long ahora = millis();

    if (idx < 0) {
      idx = findFreeSlot();
      devices[idx].mac         = mac;
      devices[idx].name        = name.length() > 0 ? name : (isRF ? "RUNEFORGE-TAG" : "");
      devices[idx].family      = classifyFamily(name, mac, isRF);
      devices[idx].eid         = eidHex;
      devices[idx].batt        = batt;
      devices[idx].tagEpoch    = tagEpoch;
      devices[idx].isRuneforge = isRF;
      devices[idx].rssiRaw     = rssi;
      devices[idx].kalmanP     = cfg.kP;
      devices[idx].kalmanX     = (float)rssi;
      devices[idx].firstSeen   = ahora;
      devices[idx].lastSeen    = ahora;
      devices[idx].count       = 1;
      devices[idx].used        = true;
      devicesUniqueCount = 0;
      for (int i = 0; i < MAX_DEVICES; i++)
        if (devices[i].used) devicesUniqueCount++;
    } else {
      devices[idx].rssiRaw  = rssi;
      devices[idx].lastSeen = ahora;
      devices[idx].count++;
      if (eidHex.length() > 0) {
        devices[idx].eid         = eidHex;
        devices[idx].batt        = batt;
        devices[idx].tagEpoch    = tagEpoch;
        devices[idx].isRuneforge = true;
        if (devices[idx].family != "runeforge")
          devices[idx].family = "runeforge";
      } else if (name.length() > 0 && devices[idx].name.length() == 0) {
        devices[idx].name   = name;
        devices[idx].family = classifyFamily(name, mac);
      }
    }

    float rssiK = kalmanUpdate((float)rssi, devices[idx].kalmanP, devices[idx].kalmanX);

    if (cfg.mqttEnabled && mqttConnected) {
      StaticJsonDocument<512> doc;
      doc["mac"]         = mac;
      doc["name"]        = devices[idx].name;
      doc["family"]      = devices[idx].family;
      doc["rssi_raw"]    = rssi;
      doc["rssi_kalman"] = rssiK;
      doc["count"]       = devices[idx].count;
      doc["eid"]         = devices[idx].eid;
      doc["batt"]        = devices[idx].batt;
      doc["epoch"]       = devices[idx].tagEpoch;
      doc["finder_id"]   = FINDER_ID;
      doc["lat"]         = FINDER_LAT;
      doc["lon"]         = FINDER_LON;
      doc["ts"]          = ahora / 1000;

      char payload[512];
      serializeJson(doc, payload);

      String topic = String(cfg.mqttTopic) + "/" + FINDER_ID + "/report";
      if (mqtt.publish(topic.c_str(), payload)) {
        devicesTotalPublished++;
        Serial.printf("[TX] %s eid=%s rssi=%.1f\n",
                      topic.c_str(), devices[idx].eid.c_str(), rssiK);
      }
    }
  }
};

// ================== WiFi / AP ==================
void iniciarAP() {
  WiFiMode_t modo = cfg.apAlwaysOn ? WIFI_AP_STA : WIFI_AP;
  WiFi.mode(modo);
  bool ok = WiFi.softAP(cfg.apSSID, cfg.apPass, cfg.apChannel, 0, 8);
  apActivo = ok;
  if (ok) {
    Serial.printf("[AP] SSID:%s PASS:%s CH:%d IP:%s Mode:%s\n",
                  cfg.apSSID, cfg.apPass, cfg.apChannel,
                  WiFi.softAPIP().toString().c_str(),
                  cfg.apAlwaysOn ? "AP+STA" : "AP ONLY");
  } else {
    Serial.println("[AP] FALLO al crear AP");
  }
}

bool conectarWiFiMulti() {
  const char* ssids[]  = { cfg.ssid, cfg.wifiSSID2, cfg.wifiSSID3 };
  const char* passes[] = { cfg.pass, cfg.wifiPass2, cfg.wifiPass3 };

  if (cfg.apAlwaysOn) WiFi.mode(WIFI_AP_STA);
  else                WiFi.mode(WIFI_STA);
  WiFi.setTxPower(WIFI_POWER_11dBm);
  WiFi.setSleep(false);

  bool first = true;
  for (int i = 0; i < 3; i++) {
    if (strlen(ssids[i]) == 0) continue;
    Serial.printf("[WiFi] Slot %d -> '%s' ...\n", i + 1, ssids[i]);
    if (!first) { WiFi.disconnect(false, false); delay(200); }
    first = false;
    WiFi.begin(ssids[i], passes[i]);

    unsigned long t0 = millis();
    while (WiFi.status() != WL_CONNECTED && millis() - t0 < WIFI_TRY_TIMEOUT) {
      delay(300); Serial.print("."); esp_task_wdt_reset();
    }
    Serial.println();

    if (WiFi.status() == WL_CONNECTED) {
      strncpy(cfg.ssidActivo, ssids[i], sizeof(cfg.ssidActivo) - 1);
      cfg.ssidActivo[sizeof(cfg.ssidActivo) - 1] = 0;
      Serial.printf("[WiFi] OK slot %d: %s  IP:%s RSSI:%d\n",
                    i + 1, ssids[i], WiFi.localIP().toString().c_str(), WiFi.RSSI());
      if (cfg.apAlwaysOn && !apActivo) {
        WiFi.softAP(cfg.apSSID, cfg.apPass, cfg.apChannel, 0, 8);
        apActivo = true;
      }
      return true;
    }
    Serial.println(" FALLO");
  }
  cfg.ssidActivo[0] = 0;
  return false;
}

// ================== MQTT ==================
void conectarMQTT() {
  if (!cfg.mqttEnabled || WiFi.status() != WL_CONNECTED) return;
  if (mqtt.connected()) { mqttConnected = true; return; }

  const char* srv  = usarFallbackMQTT ? cfg.mqttFallbackServer : cfg.mqttServer;
  uint16_t    port = usarFallbackMQTT ? cfg.mqttFallbackPort   : cfg.mqttPort;
  if (strlen(srv) == 0) return;

  Serial.printf("[MQTT] -> %s:%d (%s)\n", srv, port, usarFallbackMQTT ? "FB" : "PRIM");
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
    if (cfg.mqttFallbackEnabled) usarFallbackMQTT = !usarFallbackMQTT;
  }
}

void mqttTick() {
  if (!cfg.mqttEnabled || WiFi.status() != WL_CONNECTED) return;
  if (mqtt.connected()) { mqtt.loop(); mqttConnected = true; }
  else if (millis() - ultimoMQTTCheck > 5000) {
    ultimoMQTTCheck = millis();
    conectarMQTT();
  }
}

// ================== HTTP API ==================
void addCors() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.sendHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  server.sendHeader("Access-Control-Allow-Headers", "Content-Type");
}

void handleStatus() {
  addCors();
  StaticJsonDocument<1024> doc;
  doc["state"]  = modoAP ? "AP_CONFIG" : (WiFi.status() == WL_CONNECTED ? "SCANNING" : "AP_ONLY");
  doc["mode"]   = cfg.apAlwaysOn ? (WiFi.status() == WL_CONNECTED ? "AP+STA" : "AP+STA_WAIT")
                                 : (modoAP ? "AP" : "STA");
  doc["ble_scanning"]    = bleScanning;
  doc["ble_auto"]        = false;
  doc["ip"]              = WiFi.localIP().toString();
  doc["ap_ip"]           = WiFi.softAPIP().toString();
  doc["ap_enabled"]      = apActivo;
  doc["ap_ssid"]         = cfg.apSSID;
  doc["rssi"]            = (WiFi.status() == WL_CONNECTED) ? WiFi.RSSI() : -100;
  doc["uptime"]          = millis() / 1000;
  doc["heap"]            = ESP.getFreeHeap();
  doc["wifi_ssid"]       = cfg.ssidActivo;
  doc["mqtt_connected"]  = mqttConnected;
  doc["mqtt_enabled"]    = cfg.mqttEnabled;
  doc["mqtt_server"]     = usarFallbackMQTT ? cfg.mqttFallbackServer : cfg.mqttServer;
  doc["mqtt_port"]       = usarFallbackMQTT ? cfg.mqttFallbackPort   : cfg.mqttPort;
  doc["mqtt_using_fallback"]   = usarFallbackMQTT;
  doc["mqtt_fallback_enabled"] = cfg.mqttFallbackEnabled;
  doc["scanned_total"]   = devicesTotalScanned;
  doc["filtered_total"]  = devicesTotalFiltered;
  doc["published_total"] = devicesTotalPublished;
  doc["unique_devices"]  = devicesUniqueCount;
  doc["filter_enabled"]  = cfg.filterEnabled;
  doc["rssi_min"]        = cfg.rssiMin;
  doc["active_scan"]     = cfg.activeScan;
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

void handleDispositivos() {
  addCors();
  DynamicJsonDocument doc(24576);
  JsonArray arr = doc.to<JsonArray>();
  unsigned long ahora = millis();
  for (int i = 0; i < MAX_DEVICES; i++) {
    if (!devices[i].used) continue;
    float edad = (ahora - devices[i].lastSeen) / 1000.0f;
    bool  vivo = edad < 30.0f;
    JsonObject o = arr.createNestedObject();
    o["mac"]         = devices[i].mac;
    o["name"]        = devices[i].name;
    o["family"]      = devices[i].family;
    o["rssi_raw"]    = devices[i].rssiRaw;
    o["rssi_kalman"] = devices[i].kalmanX;
    o["count"]       = devices[i].count;
    o["edad_seg"]    = edad;
    o["vivo"]        = vivo;
    o["ts_server"]   = genTsServer();
    o["eid"]         = devices[i].eid;
    o["batt"]        = devices[i].batt;
    o["epoch"]       = devices[i].tagEpoch;
    o["finder_id"]   = FINDER_ID;
    o["lat"]         = FINDER_LAT;
    o["lon"]         = FINDER_LON;
  }
  String out; serializeJson(doc, out);
  server.send(200, "application/json", out);
}

void handleClear() {
  addCors();
  for (int i = 0; i < MAX_DEVICES; i++) {
    devices[i].used = false;
    devices[i].mac = ""; devices[i].name = ""; devices[i].family = "";
    devices[i].eid = ""; devices[i].batt = 0; devices[i].tagEpoch = 0;
    devices[i].isRuneforge = false; devices[i].count = 0;
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
  char payload[256]; serializeJson(doc, payload);
  bool ok = mqtt.publish(cfg.mqttTopic, payload);
  server.send(200, "application/json", ok ? "{\"ok\":true}" : "{\"ok\":false}");
}

void handleWiFiScan() {
  addCors();
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
  bool ok = conectarWiFiMulti();
  String resp = String("{\"ok\":") + (ok ? "true" : "false") + ",\"ssid\":\"" + cfg.ssidActivo + "\"}";
  server.send(200, "application/json", resp);
}

void handleMQTTSwitch() {
  addCors();
  usarFallbackMQTT = !usarFallbackMQTT;
  mqtt.disconnect();
  mqttConnected = false;
  String resp = String("{\"ok\":true,\"using_fallback\":") + (usarFallbackMQTT ? "true" : "false") + "}";
  server.send(200, "application/json", resp);
}

void handleSettingsGet() {
  addCors();
  StaticJsonDocument<2048> doc;
  doc["ssid"]  = cfg.ssid;  doc["pass"]  = "********";
  doc["ssid2"] = cfg.wifiSSID2; doc["pass2"] = strlen(cfg.wifiPass2) > 0 ? "********" : "";
  doc["ssid3"] = cfg.wifiSSID3; doc["pass3"] = strlen(cfg.wifiPass3) > 0 ? "********" : "";
  doc["mdns"]  = cfg.mdns;
  doc["apSSID"]     = cfg.apSSID;
  doc["apPass"]     = cfg.apPass;
  doc["apChannel"]  = cfg.apChannel;
  doc["apAlwaysOn"] = cfg.apAlwaysOn;
  doc["mqttServer"]          = cfg.mqttServer;
  doc["mqttPort"]            = cfg.mqttPort;
  doc["mqttFallbackServer"]  = cfg.mqttFallbackServer;
  doc["mqttFallbackPort"]    = cfg.mqttFallbackPort;
  doc["mqttFallbackEnabled"] = cfg.mqttFallbackEnabled;
  doc["mqttTopic"]           = cfg.mqttTopic;
  doc["mqttClient"]          = cfg.mqttClient;
  doc["mqttEnabled"]         = cfg.mqttEnabled;
  doc["activeScan"]   = cfg.activeScan;
  doc["scanInterval"] = cfg.scanInterval;
  doc["scanWindow"]   = cfg.scanWindow;
  doc["scanTime"]     = cfg.scanTime;
  doc["filterEnabled"] = cfg.filterEnabled;
  doc["rssiMin"]       = cfg.rssiMin;
  doc["macPrefixes"]   = cfg.macPrefixes;
  doc["nameFilters"]   = cfg.nameFilters;
  doc["kQ"]  = cfg.kQ; doc["kR"] = cfg.kR; doc["kP"] = cfg.kP; doc["kX0"] = cfg.kX0;
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
    String r = String("{\"ok\":false,\"msg\":\"JSON invalido\"}");
    server.send(400, "application/json", r);
    return;
  }

  bool wifiChanged = false;
  String s;
  auto cp = [&](const char* key, char* dst, size_t n, bool wifi = false, const char* skip = nullptr) {
    if (!doc.containsKey(key)) return;
    s = doc[key].as<String>();
    if (s.length() == 0) return;
    if (skip && s == skip) return;
    if (String(dst) == s) return;
    strncpy(dst, s.c_str(), n - 1); dst[n - 1] = 0;
    if (wifi) wifiChanged = true;
  };
  cp("ssid",  cfg.ssid,       sizeof(cfg.ssid),       true);
  cp("pass",  cfg.pass,       sizeof(cfg.pass),       true, "********");
  cp("ssid2", cfg.wifiSSID2,  sizeof(cfg.wifiSSID2),  true);
  cp("pass2", cfg.wifiPass2,  sizeof(cfg.wifiPass2),  true, "********");
  cp("ssid3", cfg.wifiSSID3,  sizeof(cfg.wifiSSID3),  true);
  cp("pass3", cfg.wifiPass3,  sizeof(cfg.wifiPass3),  true, "********");
  cp("mdns",  cfg.mdns,       sizeof(cfg.mdns));
  cp("apSSID",cfg.apSSID,     sizeof(cfg.apSSID),     true);
  cp("apPass",cfg.apPass,     sizeof(cfg.apPass),     true);
  if (doc.containsKey("apChannel")) cfg.apChannel = constrain((int)doc["apChannel"], 1, 13);
  if (doc.containsKey("apAlwaysOn")) {
    bool b = doc["apAlwaysOn"].as<bool>();
    if (b != cfg.apAlwaysOn) { cfg.apAlwaysOn = b; wifiChanged = true; }
  }
  cp("mqttServer",         cfg.mqttServer,         sizeof(cfg.mqttServer));
  if (doc.containsKey("mqttPort")) cfg.mqttPort = constrain((int)doc["mqttPort"], 1, 65535);
  cp("mqttFallbackServer", cfg.mqttFallbackServer, sizeof(cfg.mqttFallbackServer));
  if (doc.containsKey("mqttFallbackPort")) cfg.mqttFallbackPort = constrain((int)doc["mqttFallbackPort"], 1, 65535);
  if (doc.containsKey("mqttFallbackEnabled")) cfg.mqttFallbackEnabled = doc["mqttFallbackEnabled"].as<bool>();
  cp("mqttTopic",  cfg.mqttTopic,  sizeof(cfg.mqttTopic));
  cp("mqttClient", cfg.mqttClient, sizeof(cfg.mqttClient));
  if (doc.containsKey("mqttEnabled")) cfg.mqttEnabled = doc["mqttEnabled"].as<bool>();
  if (doc.containsKey("activeScan"))   cfg.activeScan = doc["activeScan"].as<bool>();
  if (doc.containsKey("scanInterval")) cfg.scanInterval = constrain((int)doc["scanInterval"], 50, 1000);
  if (doc.containsKey("scanWindow"))   cfg.scanWindow   = constrain((int)doc["scanWindow"],   50, cfg.scanInterval);
  if (doc.containsKey("scanTime"))     cfg.scanTime     = constrain((int)doc["scanTime"], 0, 60);
  if (doc.containsKey("filterEnabled")) cfg.filterEnabled = doc["filterEnabled"].as<bool>();
  if (doc.containsKey("rssiMin"))       cfg.rssiMin = constrain((int)doc["rssiMin"], -120, -40);
  cp("macPrefixes", cfg.macPrefixes, sizeof(cfg.macPrefixes));
  cp("nameFilters", cfg.nameFilters, sizeof(cfg.nameFilters));
  if (doc.containsKey("kQ"))  cfg.kQ  = constrain(doc["kQ"].as<float>(),  0.0001f, 100.0f);
  if (doc.containsKey("kR"))  cfg.kR  = constrain(doc["kR"].as<float>(),  0.001f,  100.0f);
  if (doc.containsKey("kP"))  cfg.kP  = constrain(doc["kP"].as<float>(),  0.01f,  1000.0f);
  if (doc.containsKey("kX0")) cfg.kX0 = constrain(doc["kX0"].as<float>(), -120.0f, -40.0f);
  if (doc.containsKey("debugLogAll")) cfg.debugLogAll = doc["debugLogAll"].as<bool>();

  configSave();
  String resp = String("{\"ok\":true,\"reboot\":") + (wifiChanged ? "true" : "false") + "}";
  server.send(200, "application/json", resp);
  if (wifiChanged) { delay(1500); ESP.restart(); }
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
      server.send(200, "application/json", "{\"ok\":true,\"scanning\":true}");
    } catch (...) {
      server.send(500, "application/json", "{\"ok\":false}");
    }
  } else {
    server.send(200, "application/json", "{\"ok\":true,\"scanning\":true,\"msg\":\"ya activo\"}");
  }
}

void handleScanStop() {
  addCors();
  if (bleScanning) {
    try {
      pBLEScan->stop();
      bleScanning = false;
      server.send(200, "application/json", "{\"ok\":true,\"scanning\":false}");
    } catch (...) {
      server.send(500, "application/json", "{\"ok\":false}");
    }
  } else {
    server.send(200, "application/json", "{\"ok\":true,\"scanning\":false,\"msg\":\"ya detenido\"}");
  }
}

void handleScanStatus() {
  addCors();
  String j = String("{\"scanning\":") + (bleScanning ? "true" : "false")
           + ",\"scan_active\":" + (cfg.activeScan ? "true" : "false") + "}";
  server.send(200, "application/json", j);
}

// ================== SETUP / LOOP ==================
void setup() {
  Serial.begin(115200);
  delay(800);
  WRITE_PERI_REG(RTC_CNTL_BROWN_OUT_REG, 0);
  arranque = millis();

  Serial.println("\n============================================================");
  Serial.println("  SCANNER PRO ESP32 · RUNEFORGE V2 · v9.0 COLLAB");
  Serial.println("============================================================");

  configLoad();
  if (cfg.scanInterval < 300) cfg.scanInterval = 400;
  if (cfg.scanWindow > 120)   cfg.scanWindow   = 100;
  if (cfg.scanWindow > cfg.scanInterval) cfg.scanWindow = 100;

  esp_task_wdt_config_t twdt = {
    .timeout_ms = WDT_TIMEOUT_SECONDS * 1000,
    .idle_core_mask = (1 << portNUM_PROCESSORS) - 1,
    .trigger_panic = true
  };
  esp_task_wdt_reconfigure(&twdt);
  esp_task_wdt_add(NULL);
  esp_task_wdt_reset();

  if (cfg.apAlwaysOn) { WiFi.mode(WIFI_AP_STA); iniciarAP(); }
  else                { WiFi.mode(WIFI_STA); }

  BLEDevice::init("ScannerPRO");
  esp_coex_preference_set(ESP_COEX_PREFER_BALANCE);

  bool online = conectarWiFiMulti();
  if (online) {
    if (MDNS.begin(cfg.mdns)) {
      MDNS.addService("http", "tcp", 80);
      Serial.printf("mDNS: http://%s.local\n", cfg.mdns);
    }
    modoAP = false;
  } else {
    if (!apActivo) iniciarAP();
    modoAP = !cfg.apAlwaysOn;
  }
  delay(300);
  esp_task_wdt_reset();

  server.on("/", HTTP_GET, []() {
    server.sendHeader("Access-Control-Allow-Origin", "*");
    server.send_P(200, "text/html", index_html);
  });
  server.on("/settings", HTTP_GET, []() {
    server.sendHeader("Access-Control-Allow-Origin", "*");
    server.send_P(200, "text/html", settings_html);
  });
  server.on("/api/status",           HTTP_GET,  handleStatus);
  server.on("/api/devices",          HTTP_GET,  handleDevices);
  server.on("/api/dispositivos",     HTTP_GET,  handleDispositivos);
  server.on("/api/devices/clear",    HTTP_POST, handleClear);
  server.on("/api/publish_test",     HTTP_POST, handlePublishTest);
  server.on("/api/wifi_scan",        HTTP_GET,  handleWiFiScan);
  server.on("/api/wifi_reconnect",   HTTP_POST, handleWiFiReconnect);
  server.on("/api/mqtt_switch",      HTTP_POST, handleMQTTSwitch);
  server.on("/api/settings",         HTTP_GET,  handleSettingsGet);
  server.on("/api/settings",         HTTP_POST, handleSettingsPost);
  server.on("/api/settings/reset",   HTTP_POST, handleSettingsReset);
  server.on("/api/ping", HTTP_GET, []() {
    addCors();
    server.send(200, "text/plain", "pong v9.0 COLLAB " + WiFi.localIP().toString());
  });
  server.on("/api/scan/start",  HTTP_POST, handleScanStart);
  server.on("/api/scan/start",  HTTP_GET,  handleScanStart);
  server.on("/api/scan/stop",   HTTP_POST, handleScanStop);
  server.on("/api/scan/stop",   HTTP_GET,  handleScanStop);
  server.on("/api/scan/status", HTTP_GET,  handleScanStatus);
  server.on("/api/scan",        HTTP_GET,  handleScanStatus);
  server.onNotFound([]() {
    if (server.method() == HTTP_OPTIONS) { addCors(); server.send(200); }
    else server.send(404, "text/plain", "Not Found");
  });

  server.begin();
  Serial.println("WebServer puerto 80 listo");
  esp_task_wdt_reset();

  try {
    pBLEScan = BLEDevice::getScan();
    pBLEScan->setAdvertisedDeviceCallbacks(new ScanCallbacks(), true);
    pBLEScan->setActiveScan(cfg.activeScan);
    pBLEScan->setInterval(cfg.scanInterval);
    pBLEScan->setWindow(cfg.scanWindow);
    bleScanning = false;
    Serial.println("[BLE] manual, usa /api/scan/start");
  } catch (...) {
    Serial.println("[BLE] error config pero WebServer arriba");
  }
  esp_task_wdt_reset();
}

void loop() {
  esp_task_wdt_reset();
  server.handleClient();
  yield();

  if (bleScanning) {
    if (!pBLEScan->isScanning()) {
      if (scanBurstActive) { scanBurstActive = false; lastScanBurst = millis(); }
      if (millis() - lastScanBurst >= SCAN_PAUSE_MS) {
        try { pBLEScan->start(SCAN_BURST_SEC, false); scanBurstActive = true; } catch (...) {}
      }
    }
  } else {
    if (pBLEScan && pBLEScan->isScanning()) {
      try { pBLEScan->stop(); } catch (...) {}
      scanBurstActive = false;
    }
  }

  server.handleClient();
  mqttTick();
  yield();
  server.handleClient();

  if (WiFi.status() != WL_CONNECTED && millis() - ultimoWiFiCheck > 15000) {
    ultimoWiFiCheck = millis();
    Serial.println("[WiFi] Reintentando STA...");
    conectarWiFiMulti();
  }
}