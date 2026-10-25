import sqlite3
import re
import time
import os
from datetime import datetime
from playwright.sync_api import sync_playwright
from playwright_stealth import Stealth

DB_PATH = r'C:\RUNEFORGE_V2_CORE\data\runeforge_telemetry.db'
BASE_URL = 'https://rastreo.tgarzaleal.com' 
PROFILE_DIR = r'C:\RUNEFORGE_V2_CORE\data\chrome_profile'
SCREENSHOT_PATH = r'C:\RUNEFORGE_V2_CORE\data\estado_actual.png'
OBSIDIAN_DIR = r'C:\RUNEFORGE_V2_CORE\Obsidian_Vault'

def init_dashboard_db():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS dashboard_stats (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TEXT,
            online INTEGER,
            offline INTEGER,
            stationary INTEGER,
            moving INTEGER
        )
    ''')
    conn.commit()
    return conn

def guardar_dashboard_en_db(online, offline, stationary, moving):
    conn = init_dashboard_db()
    cursor = conn.cursor()
    cursor.execute('''
        INSERT INTO dashboard_stats (timestamp, online, offline, stationary, moving)
        VALUES (?, ?, ?, ?, ?)
    ''', (datetime.now().isoformat(), online, offline, stationary, moving))
    conn.commit()
    conn.close()
    print("[OK] Estadísticas del Dashboard guardadas en SQLite.")

def crear_archivo_obsidian(titulo, seccion, datos_extraidos):
    fecha = datetime.now().strftime('%Y-%m-%d_%H-%M-%S')
    nombre_archivo = f"{seccion}_{fecha}.md"
    ruta_completa = os.path.join(OBSIDIAN_DIR, nombre_archivo)
    
    tags = f"runeforge/clipping, sello/purson, tgl-lab, fleet/intelligence, seccion/{seccion.lower().replace(' ', '_')}"
    fecha_actual = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    
    contenido = (
        f"---\n"
        f"title: \"{titulo}\"\n"
        f"source: \"{BASE_URL}\"\n"
        f"created: \"{fecha_actual}\"\n"
        f"status: \"operativo\"\n"
        f"sello: \"purson-astaroth\"\n"
        f"tags: [{tags}]\n"
        f"---\n\n"
        f"# Extraccion: {seccion}\n\n"
        f"> **Extractor:** Scraper Contextual RUNEFORGE\n\n"
        f"## Datos Extraidos\n\n"
        f"```text\n"
        f"{datos_extraidos}\n"
        f"```\n"
    )
    
    with open(ruta_completa, 'w', encoding='utf-8') as f:
        f.write(contenido)
    print(f"[OK] Archivo de Obsidian creado: {ruta_completa}")

def ejecutar_scraper_contextual():
    print(f"\n[{datetime.now().strftime('%H:%M:%S')}] Iniciando Scraper Contextual...")
    
    with sync_playwright() as p:
        context = p.chromium.launch_persistent_context(
            user_data_dir=PROFILE_DIR,
            headless=True,
            user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            viewport={'width': 1920, 'height': 1080}
        )
        page = context.pages[0]
        page.set_default_timeout(10000) 
        Stealth().use_sync(page)
        
        print(f"[{datetime.now().strftime('%H:%M:%S')}] Navegando a Wialon...")
        page.goto(BASE_URL, wait_until="domcontentloaded", timeout=60000)
        time.sleep(5) 
        
        print(f"[{datetime.now().strftime('%H:%M:%S')}] Detectando pestaña activa...")
        seccion_actual = "Desconocida"
        
        try:
            active_el = page.locator(".horizontal-bar-item.active").first
            seccion_actual = active_el.inner_text().strip()
        except:
            try:
                seccion_actual = page.title().strip()
            except:
                pass
                
        if not seccion_actual or seccion_actual == "Transportes Garza Leal":
            texto_check = page.locator("body").inner_text(timeout=5000)
            if "Dashboard" in texto_check:
                seccion_actual = "Dashboard"
        
        print(f"[INFO] Contexto detectado: {seccion_actual}")
        
        if "Dashboard" in seccion_actual:
            print("[INFO] Extrayendo estadísticas del Dashboard...")
            texto_pagina = page.inner_text('body')
            
            stats = {}
            online = re.search(r'Online\s+(\d+)', texto_pagina)
            offline = re.search(r'Offline\s+(\d+)', texto_pagina)
            stationary = re.search(r'Stationary\s+(\d+)', texto_pagina)
            moving = re.search(r'Moving\s+(\d+)', texto_pagina)
            
            online_val = int(online.group(1)) if online else 0
            offline_val = int(offline.group(1)) if offline else 0
            stationary_val = int(stationary.group(1)) if stationary else 0
            moving_val = int(moving.group(1)) if moving else 0

            stats['Online'] = online_val
            stats['Offline'] = offline_val
            stats['Stationary'] = stationary_val
            stats['Moving'] = moving_val
            
            resultado_limpio = "ESTADISTICAS DE FLOTA (DASHBOARD)\n\n"
            for key, value in stats.items():
                resultado_limpio += f"- {key}: {value}\n"
                print(f"   -> {key}: {value}")
            
            # Guardar en la base de datos SQLite
            guardar_dashboard_en_db(online_val, offline_val, stationary_val, moving_val)

            # Guardar en Obsidian
            crear_archivo_obsidian("Dashboard de Flota", "Dashboard", resultado_limpio)
            
        else:
            print(f"[WARN] No estás en el Dashboard (Estás en {seccion_actual}). Mueve la pestaña en Brave y vuelve a correr.")

        print(f"[{datetime.now().strftime('%H:%M:%S')}] Tomando captura...")
        page.screenshot(path=SCREENSHOT_PATH, full_page=False)
        context.close()
        
        if os.path.exists(SCREENSHOT_PATH):
            os.startfile(SCREENSHOT_PATH)

if __name__ == '__main__':
    ejecutar_scraper_contextual()