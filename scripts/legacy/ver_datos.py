import sqlite3
import os

DB_PATH = r'C:\RUNEFORGE_V2_CORE\data\runeforge_telemetry.db'

def ver_ultimos_datos():
    if not os.path.exists(DB_PATH):
        print("❌ No se encontró la base de datos.")
        return

    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    
    # Consultamos los últimos 10 registros guardados
    cursor.execute("SELECT * FROM telemetry ORDER BY id DESC LIMIT 10")
    rows = cursor.fetchall()
    conn.close()

    print(f"\n=== ÚLTIMOS 10 REGISTROS GUARDADOS EN LA DB ===\n")
    for row in rows:
        volt = f"{row['voltage']:.2f} V" if row['voltage'] else "---"
        temp = f"{row['temperature']:.1f} °C" if row['temperature'] else "---"
        
        print(f"ID: {row['id']} | Tipo: {row['type']} | Fecha: {row['fecha_registro']}")
        print(f"   Voltaje: {volt} | Temp: {temp} | Origen: {row['source_file']}")
        print(f"   Raw: {row['raw_params'][:80]}...") # Muestra solo los primeros 80 chars
        print("-" * 50)

if __name__ == '__main__':
    ver_ultimos_datos()