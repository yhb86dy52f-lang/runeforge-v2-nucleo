$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$capture = New-Object System.Collections.ArrayList
function Log($msg) {
    Write-Host $msg
    $capture.Add($msg) | Out-Null
}

Log "=== INICIANDO PIPELINE DE INGESTA CANÓNICA (v3 - Regex Agresivo + Diagnóstico) ==="

$basePath = "C:\RUNEFORGE_V2_CORE"
$dataPath = "$basePath\data"
$docsPath = "$basePath\docs\telemetria"
$pyScriptPath = "$basePath\scripts\scrapling_ingest.py"
$dbPath = "$dataPath\runeforge_telemetry.db"

if (-not (Test-Path $dataPath)) { New-Item -ItemType Directory -Force -Path $dataPath | Out-Null }

$pythonCode = @"
import sqlite3
import os
import re
from datetime import datetime
try:
    from scrapling import Adaptor
except ImportError:
    from scrapling.parser import Adaptor

DB_PATH = r'$dbPath'
DOCS_PATH = r'$docsPath'

def init_db():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS telemetry (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TEXT,
            type TEXT,
            mid TEXT,
            voltage REAL,
            temperature REAL,
            fuel_level REAL,
            raw_data TEXT
        )
    ''')
    conn.commit()
    return conn

def extract_data(text, source, conn):
    # [^0-9]* ignora CUALQUIER cosa (letras, símbolos, saltos) hasta encontrar un número.
    mids = re.findall(r'MID[^A-Za-z0-9]*([A-Za-z0-9]+)', text, re.IGNORECASE)
    volts = re.findall(r'accum_0[^0-9]*([0-9]+)', text, re.IGNORECASE)
    temps = re.findall(r'accum_2[^0-9]*([0-9]+)', text, re.IGNORECASE)
    fuels = re.findall(r'esc_lev_0[^0-9]*([0-9]+)', text, re.IGNORECASE)

    num_records = max(len(mids), len(volts), len(temps), len(fuels))
    
    if num_records == 0:
        # DIAGNÓSTICO: Si no encuentra nada, mostrar una muestra del texto
        snippet = text[:150].replace('\n', ' ').replace('\r', '')
        print(f'  -> {source}: 0 registros. MUESTRA: [{snippet}...]')
        return 0

    count = 0
    for i in range(num_records):
        mid = mids[i] if i < len(mids) else 'UNKNOWN'
        volt = float(volts[i]) / 1000.0 if i < len(volts) else None
        temp = float(temps[i]) / 16.0 if i < len(temps) else None
        fuel = float(fuels[i]) if i < len(fuels) else None

        tipo = 'KW' if fuel is not None else 'CT'

        cursor = conn.cursor()
        cursor.execute('''
            INSERT INTO telemetry (timestamp, type, mid, voltage, temperature, fuel_level, raw_data)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ''', (datetime.now().isoformat(), tipo, mid, volt, temp, fuel, text[:1000]))
        count += 1

    conn.commit()
    return count

def parse_html_with_scrapling(filepath, conn):
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()
    try:
        parser = Adaptor(content)
        text_nodes = parser.css('body::text').getall()
        text_content = " ".join(text_nodes) if text_nodes else content
    except Exception:
        text_content = re.sub(r'<[^>]+>', ' ', content)
    return extract_data(text_content, os.path.basename(filepath), conn)

def parse_md(filepath, conn):
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()
    return extract_data(content, os.path.basename(filepath), conn)

def main():
    print('=== INICIANDO SCRAPLING DATA INGESTION v3 ===')
    conn = init_db()

    if not os.path.exists(DOCS_PATH):
        print(f'Error: No existe la ruta {DOCS_PATH}')
        return

    for file in os.listdir(DOCS_PATH):
        filepath = os.path.join(DOCS_PATH, file)
        if file.endswith('.html'):
            count = parse_html_with_scrapling(filepath, conn)
            if count > 0: print(f'  -> {file}: {count} registros insertados')
        elif file.endswith('.md'):
            count = parse_md(filepath, conn)
            if count > 0: print(f'  -> {file}: {count} registros insertados')

    conn.close()
    print('=== INGESTA COMPLETADA ===')

if __name__ == '__main__':
    main()
"@

[System.IO.File]::WriteAllText($pyScriptPath, $pythonCode, [System.Text.Encoding]::UTF8)
Log "Script de Python generado en: $pyScriptPath"

Log "Ejecutando pipeline de Scrapling v3..."
$pythonCmd = "python"
if (Test-Path "C:\Users\nesth\AppData\Local\Programs\Python\Python311\python.exe") {
    $pythonCmd = "C:\Users\nesth\AppData\Local\Programs\Python\Python311\python.exe"
}

$output = & $pythonCmd $pyScriptPath 2>&1
foreach ($line in $output) {
    Log $line
}

Log "=== PIPELINE FINALIZADO ==="
$capture | Set-Clipboard
Log "Reporte copiado al portapapeles."
