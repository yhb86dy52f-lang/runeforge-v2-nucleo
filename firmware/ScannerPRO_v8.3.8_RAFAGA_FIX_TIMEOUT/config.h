#pragma once
#include <Arduino.h>
#include <Preferences.h>

struct Config {
  char     ssid[64];
  char     pass[64];
  char     wifiSSID2[64];
  char     wifiPass2[64];
  char     wifiSSID3[64];
  char     wifiPass3[64];
  char     ssidActivo[64];
  char     mdns[32];
  char     apSSID[32];
  char     apPass[32];
  uint8_t  apChannel;
  bool     apAlwaysOn;
  char     mqttServer[64];
  uint16_t mqttPort;
  char     mqttFallbackServer[64];
  uint16_t mqttFallbackPort;
  bool     mqttFallbackEnabled;
  char     mqttTopic[64];
  char     mqttClient[32];
  bool     mqttEnabled;
  bool     activeScan;
  uint16_t scanInterval;
  uint16_t scanWindow;
  uint16_t scanTime;
  bool     filterEnabled;
  int8_t   rssiMin;
  char     macPrefixes[128];
  char     nameFilters[192];
  float    kQ;
  float    kR;
  float    kP;
  float    kX0;
  bool     debugLogAll;
};

Config cfg;
Preferences prefs;

void configDefaults(Config &c) {
  strncpy(c.ssid, "517388haieksja_2.4G", sizeof(c.ssid)-1); c.ssid[sizeof(c.ssid)-1]=0;
  strncpy(c.pass, "bebecillogordillo",   sizeof(c.pass)-1); c.pass[sizeof(c.pass)-1]=0;
  c.wifiSSID2[0]=0; c.wifiPass2[0]=0;
  c.wifiSSID3[0]=0; c.wifiPass3[0]=0;
  c.ssidActivo[0]=0;
  strncpy(c.mdns, "scanner-pro", sizeof(c.mdns)-1); c.mdns[sizeof(c.mdns)-1]=0;
  strncpy(c.apSSID, "ScannerPRO-Setup", sizeof(c.apSSID)-1); c.apSSID[sizeof(c.apSSID)-1]=0;
  strncpy(c.apPass, "12345678", sizeof(c.apPass)-1); c.apPass[sizeof(c.apPass)-1]=0;
  c.apChannel=6;
  c.apAlwaysOn=true;
  strncpy(c.mqttServer, "192.168.100.8", sizeof(c.mqttServer)-1); c.mqttServer[sizeof(c.mqttServer)-1]=0;
  c.mqttPort=1883;
  strncpy(c.mqttFallbackServer, "broker.hivemq.com", sizeof(c.mqttFallbackServer)-1); c.mqttFallbackServer[sizeof(c.mqttFallbackServer)-1]=0;
  c.mqttFallbackPort=1883;
  c.mqttFallbackEnabled=false;
  strncpy(c.mqttTopic, "scannerpro/dispositivos", sizeof(c.mqttTopic)-1); c.mqttTopic[sizeof(c.mqttTopic)-1]=0;
  strncpy(c.mqttClient, "ESP32Scanner", sizeof(c.mqttClient)-1); c.mqttClient[sizeof(c.mqttClient)-1]=0;
  c.mqttEnabled=true;
  c.activeScan=false;
  c.scanInterval=200;
  c.scanWindow=150;
  c.scanTime=0;
  c.filterEnabled=true;
  c.rssiMin=-90;
  strncpy(c.macPrefixes, "c3:00,bdva", sizeof(c.macPrefixes)-1); c.macPrefixes[sizeof(c.macPrefixes)-1]=0;
  strncpy(c.nameFilters, "LMU,PB705,AT11,SAMSARA,KW,FIND MY,APPLE,TILE,BDVA,CICLOPE", sizeof(c.nameFilters)-1); c.nameFilters[sizeof(c.nameFilters)-1]=0;
  c.kQ=0.01f; c.kR=0.50f; c.kP=1.00f; c.kX0=-75.0f;
  c.debugLogAll=false;
}
void configLoad() {
  configDefaults(cfg);
  prefs.begin("scannerpro", true);
  prefs.getString("ssid", cfg.ssid, sizeof(cfg.ssid));
  prefs.getString("pass", cfg.pass, sizeof(cfg.pass));
  prefs.getString("ssid2", cfg.wifiSSID2, sizeof(cfg.wifiSSID2));
  prefs.getString("pass2", cfg.wifiPass2, sizeof(cfg.wifiPass2));
  prefs.getString("ssid3", cfg.wifiSSID3, sizeof(cfg.wifiSSID3));
  prefs.getString("pass3", cfg.wifiPass3, sizeof(cfg.wifiPass3));
  prefs.getString("mdns", cfg.mdns, sizeof(cfg.mdns));
  prefs.getString("apSSID", cfg.apSSID, sizeof(cfg.apSSID));
  prefs.getString("apPass", cfg.apPass, sizeof(cfg.apPass));
  cfg.apChannel = prefs.getUChar("apCh", cfg.apChannel);
  cfg.apAlwaysOn = prefs.getBool("apAlways", cfg.apAlwaysOn);
  prefs.getString("mqttSrv", cfg.mqttServer, sizeof(cfg.mqttServer));
  cfg.mqttPort = prefs.getUShort("mqttPort", cfg.mqttPort);
  prefs.getString("mqttFbSrv", cfg.mqttFallbackServer, sizeof(cfg.mqttFallbackServer));
  cfg.mqttFallbackPort = prefs.getUShort("mqttFbPort", cfg.mqttFallbackPort);
  cfg.mqttFallbackEnabled = prefs.getBool("mqttFbEn", cfg.mqttFallbackEnabled);
  prefs.getString("mqttTop", cfg.mqttTopic, sizeof(cfg.mqttTopic));
  prefs.getString("mqttCli", cfg.mqttClient, sizeof(cfg.mqttClient));
  cfg.mqttEnabled = prefs.getBool("mqttEn", cfg.mqttEnabled);
  cfg.activeScan = prefs.getBool("scanAct", cfg.activeScan);
  cfg.scanInterval = prefs.getUShort("scanInt", cfg.scanInterval);
  cfg.scanWindow = prefs.getUShort("scanWin", cfg.scanWindow);
  cfg.scanTime = prefs.getUShort("scanTime", cfg.scanTime);
  cfg.filterEnabled = prefs.getBool("fltEn", cfg.filterEnabled);
  cfg.rssiMin = prefs.getChar("rssiMin", cfg.rssiMin);
  prefs.getString("macPre", cfg.macPrefixes, sizeof(cfg.macPrefixes));
  prefs.getString("nameFlt", cfg.nameFilters, sizeof(cfg.nameFilters));
  cfg.kQ = prefs.getFloat("kQ", cfg.kQ);
  cfg.kR = prefs.getFloat("kR", cfg.kR);
  cfg.kP = prefs.getFloat("kP", cfg.kP);
  cfg.kX0 = prefs.getFloat("kX0", cfg.kX0);
  cfg.debugLogAll = prefs.getBool("dbgAll", cfg.debugLogAll);
  prefs.end();
  cfg.scanInterval = constrain(cfg.scanInterval, 50, 1000);
  cfg.scanWindow = constrain(cfg.scanWindow, 50, cfg.scanInterval);
  cfg.scanTime = constrain(cfg.scanTime, 0, 60);
  cfg.rssiMin = constrain(cfg.rssiMin, -120, -40);
  if (cfg.kQ < 0.0001f) cfg.kQ = 0.0001f;
  if (cfg.kR < 0.001f) cfg.kR = 0.001f;
}
void configSave() {
  prefs.begin("scannerpro", false);
  prefs.putString("ssid", cfg.ssid);
  prefs.putString("pass", cfg.pass);
  prefs.putString("ssid2", cfg.wifiSSID2);
  prefs.putString("pass2", cfg.wifiPass2);
  prefs.putString("ssid3", cfg.wifiSSID3);
  prefs.putString("pass3", cfg.wifiPass3);
  prefs.putString("mdns", cfg.mdns);
  prefs.putString("apSSID", cfg.apSSID);
  prefs.putString("apPass", cfg.apPass);
  prefs.putUChar("apCh", cfg.apChannel);
  prefs.putBool("apAlways", cfg.apAlwaysOn);
  prefs.putString("mqttSrv", cfg.mqttServer);
  prefs.putUShort("mqttPort", cfg.mqttPort);
  prefs.putString("mqttFbSrv", cfg.mqttFallbackServer);
  prefs.putUShort("mqttFbPort", cfg.mqttFallbackPort);
  prefs.putBool("mqttFbEn", cfg.mqttFallbackEnabled);
  prefs.putString("mqttTop", cfg.mqttTopic);
  prefs.putString("mqttCli", cfg.mqttClient);
  prefs.putBool("mqttEn", cfg.mqttEnabled);
  prefs.putBool("scanAct", cfg.activeScan);
  prefs.putUShort("scanInt", cfg.scanInterval);
  prefs.putUShort("scanWin", cfg.scanWindow);
  prefs.putUShort("scanTime", cfg.scanTime);
  prefs.putBool("fltEn", cfg.filterEnabled);
  prefs.putChar("rssiMin", cfg.rssiMin);
  prefs.putString("macPre", cfg.macPrefixes);
  prefs.putString("nameFlt", cfg.nameFilters);
  prefs.putFloat("kQ", cfg.kQ);
  prefs.putFloat("kR", cfg.kR);
  prefs.putFloat("kP", cfg.kP);
  prefs.putFloat("kX0", cfg.kX0);
  prefs.putBool("dbgAll", cfg.debugLogAll);
  prefs.end();
}
void configFactoryReset() {
  prefs.begin("scannerpro", false);
  prefs.clear();
  prefs.end();
  configDefaults(cfg);
}
