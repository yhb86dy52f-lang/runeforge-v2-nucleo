#!/usr/bin/env python3
"""BLE-BRIDGE - Puente MQTT -> HTTP para Scanner PRO v8.1 - RUNEFORGE V2"""
import json, os, threading, time
from datetime import datetime
from pathlib import Path
from flask import Flask, jsonify, request, send_from_directory
from flask_cors import CORS
import paho.mqtt.client as mqtt
from waitress import serve
import config

dispositivos = {}
historial = []
lock = threading.Lock()
mqtt_connected = False
db_dirty = False

app = Flask(__name__, static_folder="static", static_url_path="")
CORS(app)

def cargar_db():
    global dispositivos, historial
    if os.path.exists(config.DB_FILE):
        try:
            with open(config.DB_FILE, "r", encoding="utf-8") as f:
                dispositivos = json.load(f)
            print(f"[DB] Cargada: {len(dispositivos)} dispositivos")
        except Exception as e:
            print(f"[DB] Error: {e}")
    if os.path.exists(config.HIST_FILE):
        try:
            with open(config.HIST_FILE, "r", encoding="utf-8") as f:
                lineas = f.readlines()
                historial = [json.loads(l) for l in lineas[-config.HISTORIAL_MAX:]]
            print(f"[DB] Historial: {len(historial)} eventos")
        except Exception as e:
            print(f"[DB] Error hist: {e}")

def guardar_db():
    Path(config.DATA_DIR).mkdir(parents=True, exist_ok=True)
    with open(config.DB_FILE, "w", encoding="utf-8") as f:
        json.dump(dispositivos, f, indent=2, ensure_ascii=False)

def append_historial(evento):
    Path(config.DATA_DIR).mkdir(parents=True, exist_ok=True)
    with open(config.HIST_FILE, "a", encoding="utf-8") as f:
        f.write(json.dumps(evento, ensure_ascii=False) + "\n")

def loop_persistencia():
    global db_dirty
    while True:
        time.sleep(5)
        if db_dirty:
            with lock:
                guardar_db()
                db_dirty = False

def on_connect(client, userdata, flags, rc):
    global mqtt_connected
    if rc == 0:
        mqtt_connected = True
        client.subscribe(config.MQTT_TOPIC)
        print(f"[MQTT] Conectado -> {config.MQTT_TOPIC}")
    else:
        mqtt_connected = False
        print(f"[MQTT] Error rc={rc}")

def on_disconnect(client, userdata, rc):
    global mqtt_connected
    mqtt_connected = False
    print(f"[MQTT] Desconectado rc={rc}")

def on_message(client, userdata, msg):
    global db_dirty
    try:
        payload = json.loads(msg.payload.decode())
        mac = payload.get("mac", "unknown").lower()
        payload["mac"] = mac
        payload["ts_server"] = datetime.now().isoformat()
        payload["ts_unix"] = time.time()
        with lock:
            dispositivos[mac] = payload
            historial.append(payload)
            if len(historial) > config.HISTORIAL_MAX:
                historial.pop(0)
            db_dirty = True
        append_historial(payload)
        print(f"[RX] {mac} | Kalman: {payload.get('rssi_kalman', 0):.1f}")
    except Exception as e:
        print(f"[RX] Error: {e}")

def iniciar_mqtt():
    client = mqtt.Client(client_id=config.MQTT_CLIENT_ID, clean_session=True)
    client.on_connect = on_connect
    client.on_disconnect = on_disconnect
    client.on_message = on_message
    while True:
        try:
            client.connect(config.MQTT_BROKER, config.MQTT_PORT, 60)
            client.loop_forever()
        except Exception as e:
            print(f"[MQTT] Reintentando en 5s: {e}")
            time.sleep(5)

@app.route("/", methods=["GET"])
def index():
    static_idx = os.path.join(config.BASE_DIR, "static", "index.html")
    if os.path.exists(static_idx):
        return send_from_directory(os.path.join(config.BASE_DIR, "static"), "index.html")
    return jsonify({"servicio": "BLE-BRIDGE", "version": "1.0", "canon": "RUNEFORGE V2"})

@app.route("/health", methods=["GET"])
def health():
    return jsonify({
        "status": "ok",
        "mqtt_connected": mqtt_connected,
        "dispositivos_activos": len(dispositivos),
        "historial_eventos": len(historial),
        "timestamp": datetime.now().isoformat()
    })

@app.route("/api/dispositivos", methods=["GET"])
def get_dispositivos():
    ahora = time.time()
    with lock:
        lista = []
        for mac, d in dispositivos.items():
            edad = ahora - d.get("ts_unix", ahora)
            item = dict(d)
            item["vivo"] = edad < config.TTL_DISPOSITIVO_SEG
            item["edad_seg"] = round(edad, 1)
            lista.append(item)
    lista.sort(key=lambda x: (not x["vivo"], -(x.get("rssi_kalman") or -999)))
    return jsonify(lista)

@app.route("/api/dispositivo/<mac>", methods=["GET"])
def get_dispositivo(mac):
    with lock:
        d = dispositivos.get(mac.lower())
    if not d:
        return jsonify({"error": "no encontrado", "mac": mac}), 404
    return jsonify(d)

@app.route("/api/historial", methods=["GET"])
def get_historial():
    n = int(request.args.get("n", 100))
    with lock:
        return jsonify(historial[-n:])

@app.route("/api/stats", methods=["GET"])
def get_stats():
    with lock:
        cats = {}
        for d in dispositivos.values():
            name = (d.get("name") or "").upper()
            mac = d.get("mac", "")
            if mac.startswith("c3:00") or "CICLOPE" in name: c = "ciclope"
            elif "LMU" in name or "EX7" in name: c = "lmu"
            elif "AT11" in name or "SAMSARA" in name: c = "samsara"
            elif "PB705" in name or "KW" in name: c = "kw"
            elif "APPLE" in name or "FIND" in name: c = "apple"
            else: c = "otros"
            cats[c] = cats.get(c, 0) + 1
    return jsonify(cats)

@app.route("/api/log/batch", methods=["POST"])
def log_batch():
    try:
        data = request.get_json(force=True)
        print(f"[LOG-HTML] {json.dumps(data, ensure_ascii=False)[:200]}")
    except Exception as e:
        print(f"[LOG] Error: {e}")
    return jsonify({"ok": True})

def main():
    print("=" * 60)
    print("  BLE-BRIDGE - RUNEFORGE V2")
    print("=" * 60)
    print(f"  MQTT: {config.MQTT_BROKER}:{config.MQTT_PORT}")
    print(f"  HTTP: http://{config.HTTP_HOST}:{config.HTTP_PORT}")
    print(f"  DB  : {config.DB_FILE}")
    print("=" * 60)
    cargar_db()
    threading.Thread(target=iniciar_mqtt, daemon=True).start()
    threading.Thread(target=loop_persistencia, daemon=True).start()
    serve(app, host=config.HTTP_HOST, port=config.HTTP_PORT, threads=config.HTTP_THREADS)

if __name__ == "__main__":
    main()
