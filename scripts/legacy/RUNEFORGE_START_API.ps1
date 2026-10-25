$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$capture = New-Object System.Collections.ArrayList
function Log($msg) {
    Write-Host $msg
    $capture.Add($msg) | Out-Null
}

Log "=== CREANDO API BACKEND (FASTAPI) ==="

$basePath = "C:\RUNEFORGE_V2_CORE"
$pyScriptPath = "$basePath\scripts\api_telemetria.py"

# 1. Asegurar que FastAPI y Uvicorn estén instalados
Log "Verificando dependencias (FastAPI, Uvicorn)..."
$pythonCmd = "python"
if (Test-Path "C:\Users\nesth\AppData\Local\Programs\Python\Python311\python.exe") {
    $pythonCmd = "C:\Users\nesth\AppData\Local\Programs\Python\Python311\python.exe"
}
& $pythonCmd -m pip install fastapi uvicorn > $null 2>&1

# 2. Crear el código de la API
$pythonCode = @"
import sqlite3
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn

app = FastAPI(title="RUNEFORGE Telemetry API")

# Permitir peticiones desde cualquier origen (para que tu HTML/Tauri pueda conectarse)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

DB_PATH = r'C:\RUNEFORGE_V2_CORE\data\runeforge_telemetry.db'

def get_db_connection():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

@app.get("/")
def read_root():
    return {"status": "ok", "message": "Runeforge API is running"}

@app.get("/api/telemetry")
def get_telemetry(limit: int = 50, type: str = None):
    conn = get_db_connection()
    cursor = conn.cursor()
    
    query = "SELECT * FROM telemetry ORDER BY id DESC LIMIT ?"
    params = [limit]
    
    if type:
        query = "SELECT * FROM telemetry WHERE type = ? ORDER BY id DESC LIMIT ?"
        params = [type.upper(), limit]
        
    cursor.execute(query, params)
    rows = cursor.fetchall()
    conn.close()
    
    return [dict(row) for row in rows]

@app.get("/api/stats")
def get_stats():
    conn = get_db_connection()
    cursor = conn.cursor()
    
    cursor.execute("SELECT type, COUNT(*) as count FROM telemetry GROUP BY type")
    stats = {row["type"]: row["count"] for row in cursor.fetchall()}
    
    conn.close()
    return {"total_registros": sum(stats.values()), "por_tipo": stats}

if __name__ == "__main__":
    print("Iniciando API en http://127.0.0.1:8000")
    uvicorn.run(app, host="127.0.0.1", port=8000)
"@

[System.IO.File]::WriteAllText($pyScriptPath, $pythonCode, [System.Text.Encoding]::UTF8)
Log "API generada en: $pyScriptPath"

Log "Iniciando servidor API en segundo plano..."
# Iniciar la API en una ventana separada para que no bloquee la terminal actual
Start-Process -FilePath $pythonCmd -ArgumentList "`"$pyScriptPath`"" -WindowStyle Normal

Log "=== API INICIADA ==="
Log "Abre tu navegador y visita: http://127.0.0.1:8000/api/telemetry?limit=5"
Log "También puedes ver las estadísticas en: http://127.0.0.1:8000/api/stats"
$capture | Set-Clipboard
