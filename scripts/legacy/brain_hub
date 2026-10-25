import json
import time
import socket
import psutil
import os
from datetime import datetime

NEURONS = {
    "whisper_ai": {"port": 8081, "type": "Local AI", "icon": "cpu"},
    "ollama_llm": {"port": 11434, "type": "LLM Local", "icon": "brain"},
    "fastify_api": {"port": 3001, "type": "Backend Node", "icon": "server"}
}

DASHBOARD_DIR = r"C:\RUNEFORGE_V2_CORE\nexus-dashboard\public"
if not os.path.exists(DASHBOARD_DIR): os.makedirs(DASHBOARD_DIR)

def check_port(port):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.settimeout(0.5)
        return s.connect_ex(('127.0.0.1', port)) == 0

if __name__ == "__main__":
    print("⚡ [NEXUS BRAIN] Monitor iniciado.")
    try:
        while True:
            nodes = [{"id": k, "status": "online" if check_port(v["port"]) else "offline", "type": v["type"], "port": v["port"]} for k, v in NEURONS.items()]
            
            ecosystem_data = {"timestamp": datetime.now().isoformat(), "nodes": nodes}
            health_data = {
                "timestamp": datetime.now().isoformat(),
                "core": {"cpu_percent": psutil.cpu_percent(interval=0.1), "ram_percent": psutil.virtual_memory().percent},
                "hardware": {"GPU_Name": "GTX 1660 SUPER", "Disk_Type": "HDD"}
            }
            
            with open(os.path.join(DASHBOARD_DIR, "ecosystem.json"), "w", encoding="utf-8") as f: json.dump(ecosystem_data, f, indent=4)
            with open(os.path.join(DASHBOARD_DIR, "system_health.json"), "w", encoding="utf-8") as f: json.dump(health_data, f, indent=4)
            time.sleep(2)
    except KeyboardInterrupt:
        print("\n[!] Monitor detenido.")