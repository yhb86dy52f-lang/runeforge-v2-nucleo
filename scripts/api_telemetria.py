import sqlite3
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
import os

app = FastAPI(title="RUNEFORGE Telemetry API")

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

@app.get("/api/dashboard")
def get_dashboard_stats():
    conn = get_db_connection()
    cursor = conn.cursor()
    
    # Verificar si la tabla existe antes de consultar
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='dashboard_stats'")
    if not cursor.fetchone():
        conn.close()
        return {"error": "Tabla dashboard_stats no encontrada. Corre el scraper primero."}
        
    # Obtener el último registro guardado
    cursor.execute("SELECT * FROM dashboard_stats ORDER BY id DESC LIMIT 1")
    row = cursor.fetchone()
    conn.close()
    
    if row:
        return dict(row)
    else:
        return {"error": "No hay datos en el dashboard."}

if __name__ == "__main__":
    print("Iniciando API en http://127.0.0.1:8000")
    uvicorn.run(app, host="127.0.0.1", port=8000)