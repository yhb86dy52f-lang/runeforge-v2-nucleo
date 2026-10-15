"""
BLE-BRIDGE - Configuracion canon RUNEFORGE V2
Subsistema: puente MQTT -> HTTP para Scanner PRO
Fecha canon: 2026-10-03
"""
import os

# --- MQTT (broker local) ---
MQTT_BROKER    = "localhost"
MQTT_PORT      = 1883
MQTT_TOPIC     = "scannerpro/dispositivos"
MQTT_CLIENT_ID = "RuneforgeBLEBridge"

# --- HTTP ---
HTTP_HOST    = "0.0.0.0"
HTTP_PORT    = 5000
HTTP_THREADS = 4

# --- Persistencia ---
BASE_DIR  = os.path.dirname(os.path.abspath(__file__))
DATA_DIR  = os.path.join(BASE_DIR, "data")
DB_FILE   = os.path.join(DATA_DIR, "dispositivos.json")
HIST_FILE = os.path.join(DATA_DIR, "historial.jsonl")

# --- Logica de negocio ---
HISTORIAL_MAX       = 1000
TTL_DISPOSITIVO_SEG = 300
