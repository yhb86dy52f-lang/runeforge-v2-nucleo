import sqlite3
import re
import time
import os
import sys
from datetime import datetime
from playwright.sync_api import sync_playwright
from playwright_stealth import Stealth

DB_PATH = r'C:\RUNEFORGE_V2_CORE\data\runeforge_telemetry.db'
BASE_URL = 'https://rastreo.tgarzaleal.com' 
PROFILE_DIR = r'C:\RUNEFORGE_V2_CORE\data\chrome_profile'
OBSIDIAN_DIR = r'C:\RUNEFORGE_V2_CORE\Obsidian_Vault'

# --- FUNCIONES AUXILIARES ---
def to_signed_32(n):
    if n is None: return None
    n = int(n)
    return n - 0x100000000 if n >= 0x80000000 else n

def guardar_telemetria_en_db(texto_trama, fecha_str):
    clean_line = texto_trama.replace('\\_', '_')
    def extract_val(pattern):
        match = re.search(pattern, clean_line, re.IGNORECASE)
        return float(match.group(1)) if match else None

    volt = extract_val(r'accum_0[\s:=]+(\d+)')
    temp1_raw = extract_val(r'accum_2[\s:=]+(\d+)')
    fuel = extract_val(r'esc_lev_0[\s:=]+(\d+)')
    
    if volt is None and temp1_raw is None and fuel is None: return False
    tipo = 'KW' if fuel is not None else 'CT'
    temp1_final = (to_signed_32(temp1_raw) / 16.0) if temp1_raw is not None else None

    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute("SELECT id FROM telemetry WHERE raw_params = ?", (texto_trama[:500],))
    if cursor.fetchone():
        conn.close()
        return False

    cursor.execute(
        "INSERT INTO telemetry (timestamp, fecha_registro, source_file, type, voltage, temperature, temp2, fuel, raw_params) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
        (datetime.now().isoformat(), fecha_str, 'Scraper_Interactivo', tipo, (volt/1000.0 if volt else None), temp1_final, None, fuel, texto_trama[:500])
    )
    conn.commit()
    conn.close()
    return True

def guardar_dashboard_en_db(online, offline, stationary, moving):
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute('''CREATE TABLE IF NOT EXISTS dashboard_stats (id INTEGER PRIMARY KEY AUTOINCREMENT, timestamp TEXT, online INTEGER, offline INTEGER, stationary INTEGER, moving INTEGER)''')
    cursor.execute("INSERT INTO dashboard_stats (timestamp, online, offline, stationary, moving) VALUES (?, ?, ?, ?, ?)", (datetime.now().isoformat(), online, offline, stationary, moving))
    conn.commit()
    conn.close()

def crear_archivo_obsidian(titulo, seccion, texto_crudo):
    fecha = datetime.now().strftime('%Y-%m-%d_%H-%M-%S')
    ruta_completa = os.path.join(OBSIDIAN_DIR, f"{seccion}_{fecha}.md")
    
    contenido = (
        f"---\ntitle: \"{titulo}\"\nsource: \"{BASE_URL}\"\ncreated: \"{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\"\n"
        f"status: \"operativo\"\nsello: \"purson-astaroth\"\ntags: [runeforge/clipping, tgl-lab, seccion/{seccion.lower().replace(' ', '_')}]\n---\n\n"
        f"# Extraccion: {seccion}\n\n{texto_crudo}\n"
    )
    with open(ruta_completa, 'w', encoding='utf-8') as f:
        f.write(contenido)
    print(f"   [OK] Guardado en Obsidian: {ruta_completa}")

def click_visible(page, text_pattern):
    loc = page.locator(text_pattern)
    count = loc.count()
    for i in range(count):
        try:
            if loc.nth(i).is_visible():
                loc.nth(i).click(timeout=5000)
                return True
        except:
            continue
    return False

# --- LÓGICA PRINCIPAL ---
def ejecutar_opcion(opcion):
    print(f"\n[{datetime.now().strftime('%H:%M:%S')}] Iniciando robot para opción {opcion}...")
    
    with sync_playwright() as p:
        context = p.chromium.launch_persistent_context(
            user_data_dir=PROFILE_DIR,
            headless=True,
            user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            viewport={'width': 1920, 'height': 1080}
        )
        page = context.pages[0]
        page.set_default_timeout(15000) 
        Stealth().use_sync(page)
        
        print("   -> Navegando a Wialon...")
        page.goto(BASE_URL, wait_until="domcontentloaded", timeout=60000)
        
        try:
            page.wait_for_selector(".horizontal-bar-item", timeout=20000)
            time.sleep(3) 
        except:
            pass
        
        try:
            if opcion == "1":
                print("   -> Haciendo clic en Dashboard...")
                if click_visible(page, "text=/Dashboard|Cuadro de mando/i"):
                    time.sleep(7) 
                    texto = page.inner_text('body')
                    
                    online = re.search(r'Online\s+(\d+)', texto)
                    offline = re.search(r'Offline\s+(\d+)', texto)
                    stationary = re.search(r'Stationary\s+(\d+)', texto)
                    moving = re.search(r'Moving\s+(\d+)', texto)
                    
                    o_val = int(online.group(1)) if online else 0
                    off_val = int(offline.group(1)) if offline else 0
                    st_val = int(stationary.group(1)) if stationary else 0
                    mv_val = int(moving.group(1)) if moving else 0
                    
                    print(f"   -> KPIs Extraídos: Online {o_val} | Offline {off_val} | Stationary {st_val} | Moving {mv_val}")
                    guardar_dashboard_en_db(o_val, off_val, st_val, mv_val)
                    crear_archivo_obsidian("Dashboard de Flota", "Dashboard", f"Online: {o_val}\nOffline: {off_val}\nStationary: {st_val}\nMoving: {mv_val}")

            elif opcion == "2":
                print("   -> Haciendo clic en Mensajes...")
                if click_visible(page, "text=/Messages|Mensajes/i"):
                    time.sleep(4)
                    click_visible(page, "text=/Execute|Ejecutar/i")
                    time.sleep(6)
                    
                    texto = page.inner_text('body')
                    lineas = texto.split('\n')
                    tramas = [l.strip() for l in lineas if 'accum_0=' in l and 'rssi=' in l]
                    
                    nuevas = 0
                    for trama in tramas:
                        if guardar_telemetria_en_db(trama, datetime.now().strftime('%Y-%m-%d %H:%M:%S')):
                            nuevas += 1
                    print(f"   -> Se guardaron {nuevas} tramas nuevas en SQLite.")
                    crear_archivo_obsidian("Telemetria Mensajes", "Mensajes", texto)

            elif opcion == "3":
                print("   -> Haciendo clic en Monitoring (Mapa y Unidades)...")
                if click_visible(page, "text=/Monitoring|Seguimiento/i"):
                    time.sleep(7)
                    texto = page.inner_text('body')
                    crear_archivo_obsidian("Monitoreo de Flota", "Monitoring", texto)

            elif opcion == "4":
                print("   -> Haciendo clic en Monitoring (para ver los grupos)...")
                if click_visible(page, "text=/Monitoring|Seguimiento/i"):
                    time.sleep(5)
                    
                    print("   -> Extrayendo y normalizando grupos de unidades...")
                    grupos_raw = page.evaluate('''() => {
                        let treeNodes = document.querySelectorAll('.locations-tree .wui-tree-node-content, .wui-tree-node-content');
                        let results = [];
                        for (let node of treeNodes) {
                            let text = node.innerText.trim();
                            if (text) results.push(text);
                        }
                        return results;
                    }''')
                    
                    grupos_limpios = []
                    for g in grupos_raw:
                        g = g.replace('\n', ' ').strip()
                        match = re.search(r'^\((\d+)\)\s*(.+)$', g)
                        if match:
                            cantidad = match.group(1)
                            nombre = match.group(2).strip()
                            grupos_limpios.append(f"| {nombre} | {cantidad} |")
                        elif len(g) > 3 and not g.startswith('('):
                             grupos_limpios.append(f"| {g} | - |")

                    if not grupos_limpios:
                        texto_completo = page.inner_text('body')
                        matches = re.findall(r'\((\d+)\)\s*([A-Za-z0-9\*\!\.\-\s]+)', texto_completo)
                        for m in matches:
                            grupos_limpios.append(f"| {m[1].strip()} | {m[0]} |")

                    tabla_md = "## 📊 Agrupación de Unidades\n\n"
                    tabla_md += "| Nombre del Grupo | Cantidad de Unidades |\n"
                    tabla_md += "| :--- | :---: |\n"
                    
                    vistos = set()
                    for fila in grupos_limpios:
                        if fila not in vistos:
                            tabla_md += fila + "\n"
                            vistos.add(fila)

                    print(f"   -> Se encontraron y agruparon {len(vistos)} grupos.")
                    crear_archivo_obsidian("Grupos de Unidades", "Grupos", tabla_md)

        except Exception as e:
            print(f"   [ERROR] No se pudo completar la extracción: {e}")
        
        timestamp = datetime.now().strftime('%H-%M-%S')
        screenshot_path = rf'C:\RUNEFORGE_V2_CORE\data\estado_{timestamp}.png'
        
        print(f"   -> Tomando captura de pantalla ({timestamp})...")
        try:
            page.screenshot(path=screenshot_path, full_page=False)
            context.close()
            # ELIMINAMOS ESTA LÍNEA PARA QUE NO SE ABRA LA IMAGEN
            # os.startfile(screenshot_path)
            print(f"   [OK] Foto guardada silenciosamente.")
        except Exception as e:
            print(f"   [WARN] No se pudo guardar la foto: {e}")
            context.close()

def menu():
    while True:
        print("\n" + "="*40)
        print(" 🤖 RUNEFORGE SCRAPER INTERACTIVO 🤖")
        print("="*40)
        print(" 1. Extraer Dashboard (KPIs de Flota)")
        print(" 2. Extraer Mensajes (Telemetría)")
        print(" 3. Extraer Monitoring (Todo el texto)")
        print(" 4. Extraer y Agrupar Unidades (Tabla Limpia)")
        print(" 5. Salir")
        print("="*40)
        
        opcion = input(" 👉 Elige una opción (1-5): ").strip()
        
        if opcion in ['1', '2', '3', '4']:
            ejecutar_opcion(opcion)
        elif opcion == '5':
            print(" Saliendo del sistema... ¡Hasta luego!")
            sys.exit(0)
        else:
            print(" ❌ Opción no válida. Intenta de nuevo.")

if __name__ == '__main__':
    menu()