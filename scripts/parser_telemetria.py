import sqlite3
import os
import re
from datetime import datetime

DB_PATH = r'C:\RUNEFORGE_V2_CORE\data\runeforge_telemetry.db'
DOCS_PATH = r'C:\RUNEFORGE_V2_CORE\docs\telemetria'

def init_db():
    if os.path.exists(DB_PATH):
        os.remove(DB_PATH)
        
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute('''
        CREATE TABLE telemetry (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TEXT,
            fecha_registro TEXT,
            source_file TEXT,
            type TEXT,
            voltage REAL,
            temperature REAL,
            temp2 REAL,
            fuel REAL,
            raw_params TEXT
        )
    ''')
    conn.commit()
    return conn

def extract_val(pattern, text):
    match = re.search(pattern, text, re.IGNORECASE)
    return float(match.group(1)) if match else None

def parse_file(filepath, conn):
    filename = os.path.basename(filepath)
    print(f'  -> Procesando: {filename}')
    
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        lines = f.readlines()

    count = 0
    for line in lines:
        line = line.strip()
        if not line or line.startswith('| ---'):
            continue

        # Formato 1: Tablas con Parametros Crudos (ej: accum_0=13224)
        if 'accum_0=' in line or 'accum\_0=' in line or 'accum_0' in line:
            clean_line = line.replace('\\_', '_')
            
            volt = extract_val(r'accum_0[\s:=]+(\d+)', clean_line)
            temp1 = extract_val(r'accum_2[\s:=]+(\d+)', clean_line)
            temp2 = extract_val(r'accum_3[\s:=]+(\d+)', clean_line)
            fuel = extract_val(r'esc_lev_0[\s:=]+(\d+)', clean_line)
            
            date_match = re.search(r'(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})', line)
            fecha = date_match.group(1) if date_match else datetime.now().isoformat()

            if volt is not None or temp1 is not None or fuel is not None:
                tipo = 'KW' if fuel is not None else 'CT'
                cursor = conn.cursor()
                cursor.execute('''
                    INSERT INTO telemetry (timestamp, fecha_registro, source_file, type, voltage, temperature, temp2, fuel, raw_params)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                ''', (
                    datetime.now().isoformat(), fecha, filename, tipo, 
                    (volt/1000.0 if volt else None), 
                    (temp1/16.0 if temp1 else None), 
                    (temp2/16.0 if temp2 else None), 
                    fuel, 
                    line[:500]
                ))
                count += 1

        # Formato 2: Tablas ya Procesadas (ej: | 12.62 V | 4.10 V | 26.50 C |)
        elif line.startswith('|') and ('V' in line or 'C' in line):
            parts = [p.strip() for p in line.split('|')]
            if len(parts) > 5:
                volt = None
                temp = None
                
                for part in parts:
                    # Limpiamos backslashes de Markdown antes de buscar
                    clean_part = part.replace('\\', '')
                    
                    # Buscamos voltaje (evitando GPS y cabeceras)
                    if ' V' in clean_part and 'Volt' not in clean_part and 'GPS' not in clean_part:
                        v_match = re.search(r'(\d+(?:\.\d+)?)\s*V', clean_part)
                        if v_match:
                            volt = float(v_match.group(1))
                            break
                
                for part in parts:
                    clean_part = part.replace('\\', '')
                    
                    # Buscamos temperatura (asegurando que haya al menos un digito, ignorando '-')
                    if 'C' in clean_part and '°' not in clean_part:
                        t_match = re.search(r'(-?\d+(?:\.\d+)?)\s*°?C', clean_part)
                        if t_match:
                            temp = float(t_match.group(1))
                            break
                            
                date_match = re.search(r'(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})', line)
                fecha = date_match.group(1) if date_match else datetime.now().isoformat()

                if volt is not None or temp is not None:
                    cursor = conn.cursor()
                    cursor.execute('''
                        INSERT INTO telemetry (timestamp, fecha_registro, source_file, type, voltage, temperature, temp2, fuel, raw_params)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                    ''', (datetime.now().isoformat(), fecha, filename, 'PROCESADO', volt, temp, None, None, line[:500]))
                    count += 1

    conn.commit()
    print(f'     Registros insertados: {count}')

def main():
    print('=== INICIANDO PARSEO DE TELEMETRIA ===')
    conn = init_db()

    if not os.path.exists(DOCS_PATH):
        print(f'Error: No existe la ruta {DOCS_PATH}')
        return

    for file in os.listdir(DOCS_PATH):
        if file.endswith('.md') or file.endswith('.html'):
            filepath = os.path.join(DOCS_PATH, file)
            parse_file(filepath, conn)
            
    conn.close()
    print('=== PARSEO COMPLETADO ===')

if __name__ == '__main__':
    main()