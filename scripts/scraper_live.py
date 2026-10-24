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

def to_signed_32(n):
    if n is None: return None
    n = int(n)
    return n - 0x100000000 if n >= 0x80000000 else n

def guardar_en_db(texto_trama, fecha_str):
    clean_line = texto_trama.replace('\\_', '_')
    
    def extract_val(pattern):
        match = re.search(pattern, clean_line, re.IGNORECASE)
        return float(match.group(1)) if match else None

    volt = extract_val(r'accum_0[\s:=]+(\d+)')
    temp1_raw = extract_val(r'accum_2[\s:=]+(\d+)')
    temp2_raw = extract_val(r'accum_3[\s:=]+(\d+)')
    fuel = extract_val(r'esc_lev_0[\s:=]+(\d+)')
    
    if volt is None and temp1_raw is None and fuel is None:
        return False

    tipo = 'KW' if fuel is not None else 'CT'
    
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    cursor.execute("SELECT id FROM telemetry WHERE raw_params = ?", (texto_trama[:500],))
    if cursor.fetchone():
        conn.close()
        return False

    temp1_final = (to_signed_32(temp1_raw) / 16.0) if temp1_raw is not None else None
    temp2_final = (to_signed_32(temp2_raw) / 16.0) if temp2_raw is not None else None

    cursor.execute('''
        INSERT INTO telemetry (timestamp, fecha_registro, source_file, type, voltage, temperature, temp2, fuel, raw_params)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', (
        datetime.now().isoformat(), fecha_str, 'Scraper_Live_Wialon', tipo, 
        (volt/1000.0 if volt else None), 
        temp1_final, 
        temp2_final, 
        fuel, 
        texto_trama[:500]
    ))
    conn.commit()
    conn.close()
    return True

def scrapear_wialon():
    print(f"\n[{datetime.now().strftime('%H:%M:%S')}] Iniciando extracción...")
    
    with sync_playwright() as p:
        context = p.chromium.launch_persistent_context(
            user_data_dir=PROFILE_DIR,
            headless=True,
            user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            viewport={'width': 1920, 'height': 1080}
        )
        page = context.pages[0]
        Stealth().use_sync(page)
        
        print(f"[{datetime.now().strftime('%H:%M:%S')}] Navegando a Wialon...")
        page.goto(BASE_URL, wait_until="domcontentloaded", timeout=60000)
        
        # Damos 10 segundos fijos para que cargue el dashboard inicial
        time.sleep(10)

        print(f"[{datetime.now().strftime('%H:%M:%S')}] Buscando pestaña de Mensajes...")
        try:
            # Esperamos hasta 15s a que el menú sea VISIBLE
            menu_locator = page.locator("text=/Messages|Mensajes/i").first
            menu_locator.wait_for(state="visible", timeout=15000)
            
            # Hacemos clic con force=True para ignorar capas invisibles de carga
            menu_locator.click(timeout=5000, force=True)
            print("✅ Pestaña de Mensajes seleccionada.")
            time.sleep(4) # Esperar a que cargue el formulario
        except Exception as e:
            print(f"⚠️ Error buscando pestaña: {e}")
            # Tomamos captura para ver qué pasó si falla aquí
            page.screenshot(path=SCREENSHOT_PATH)
            os.startfile(SCREENSHOT_PATH)

        print(f"[{datetime.now().strftime('%H:%M:%S')}] Buscando botón de Ejecutar...")
        try:
            btn_locator = page.locator("text=/Execute|Ejecutar/i").first
            btn_locator.wait_for(state="visible", timeout=10000)
            btn_locator.click(timeout=5000, force=True)
            print("✅ Clic en Ejecutar realizado. Esperando que la tabla cargue...")
            
            # Esperamos a que aparezca el texto 'rssi='
            page.wait_for_selector("text=rssi=", timeout=20000)
            print("✅ ¡Tabla cargada exitosamente!")
            time.sleep(3) 
            
        except Exception as e:
            print(f"⚠️ Ocurrió un detalle buscando los datos: {e}")

        # Extraer los datos
        texto_pagina = page.inner_text('body')
        context.close()

        lineas = texto_pagina.split('\n')
        tramas_encontradas = []
        for linea in lineas:
            if 'accum_0=' in linea and 'rssi=' in linea:
                tramas_encontradas.append(linea.strip())

        nuevas_tramas = 0
        fecha_actual = datetime.now().strftime('%Y-%m-%d %H:%M:%S')

        for trama in tramas_encontradas:
            if guardar_en_db(trama, fecha_actual):
                nuevas_tramas += 1

        print(f"[{datetime.now().strftime('%H:%M:%S')}] Se guardaron {nuevas_tramas} tramas NUEVAS en la base de datos.")

if __name__ == '__main__':
    scrapear_wialon()