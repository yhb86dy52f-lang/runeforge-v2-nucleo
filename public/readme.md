# ⚡ RUNEFORGE V2.6.2 · TGL LAB V5 PRO

> Sistema soberano de diagnóstico, calibración y gestión de flota para módulos electrónicos LMU/ECU.
> Arquitectura Edge-First · Offline-Ready · Trazabilidad Inmutable.

---

## 📖 Tabla de Contenidos

- [Descripción General](#-descripción-general)
- [Arquitectura](#-arquitectura)
- [Requisitos](#-requisitos)
- [Instalación](#-instalación)
- [Arranque](#-arranque)
- [Estructura del Proyecto](#-estructura-del-proyecto)
- [Endpoints](#-endpoints)
- [Frontend](#-frontend)
- [Esquemas de Datos](#-esquemas-de-datos)
- [Lógica de Calibración 62K](#-lógica-de-calibración-62k)
- [Troubleshooting](#-troubleshooting)
- [Glosario](#-glosario)

---

## 🎯 Descripción General

**RUNEFORGE** es el ecosistema principal. Aloja dos aplicaciones que colaboran en modo **Cerebro ↔ Músculo**:

| Rol | Aplicación | Puerto | Responsabilidad |
|---|---|---|---|
| 🧠 **Cerebro** | TGL LAB V5 PRO (Fastify) | `3001` | Dashboard, decodificador de tramas, telemetría, clippings, proxy a FlotaKW |
| 💪 **Músculo** | FlotaKW OS v3.2 (FastAPI) | `8000` | Ontología operativa, alta atómica de unidades, auditoría inmutable |
| 🤖 **LLM** | Ollama | `3100` | Validación semántica (opcional) |

**Filosofía:**
> *"Tu base de datos es tu única fuente de verdad."*

**Capacidades:**
- Decodificación de tramas hex (formato TLV) en tiempo real
- Cálculo de calibración "62K" para sensores de nivel/voltaje
- Generación de informes Markdown (clippings) compatibles con Obsidian
- Alta atómica de unidades con trazabilidad completa
- Operación offline-first con IndexedDB
- Proxy transparente Cerebro → Músculo con `trace_id`

---

## 🏗 Arquitectura
┌─────────────────────────────────────────────────────────────┐
│ NAVEGADOR (Usuario) │
│ http://127.0.0.1:3001 │
└──────────────────────────┬──────────────────────────────────┘
│ HTTP
▼
┌─────────────────────────────────────────────────────────────┐
│ 🧠 CEREBRO · Fastify · :3001 · server.js │
│ │
│ /health → Estado del sistema │
│ /api/sync → Sincronización telemetría │
│ /api/clipping → Guardar Markdown │
│ /api/docs → Servir documentación │
│ /api/flota/* → PROXY → Músculo │
└──────────┬────────────────────────────────┬─────────────────┘
│ │
│ fetch │ fetch
▼ ▼
┌──────────────────────┐ ┌──────────────────────────┐
│ 💪 MÚSCULO │ │ 🤖 OLLAMA │
│ FastAPI · :8000 │ │ LLM · :3100 │
│ │ │ │
│ /unidades │ │ /api/chat │
│ /alta │ │ │
│ /auditoria │ │ │
│ /tecnicos │ │ │
│ /stats │ │ │
└──────────┬───────────┘ └──────────────────────────┘
│
▼
┌──────────────┐
│ SQLite │
│ flotakw.db │
└──────────────┘

text

---

## 📋 Requisitos

| Componente | Versión mínima | Verificar |
|---|---|---|
| **Windows** | 10/11 | `winver` |
| **Node.js** | 20.x+ | `node --version` |
| **Python** | 3.12+ | `python --version` |
| **PowerShell** | 7.x+ | `$PSVersionTable.PSVersion` |
| **Ollama** (opcional) | última | `ollama --version` |

**Dependencias Node** (en `C:\RUNEFORGE_V2_CORE`):
- `fastify` — framework HTTP
- `@fastify/cors` — CORS
- `@fastify/static` (opcional) — servir `public/`

**Dependencias Python** (en `FlotaKW.../backend`):
fastapi==0.110.2
uvicorn[standard]==0.29.0
sqlalchemy==2.0.30
pydantic==2.8.2
pydantic-settings==2.4.0
structlog==24.1.0
qrcode[pil]==8.0
python-multipart==0.0.9
python-dateutil==2.9.0

text

---

## 🚀 Instalación

### 1. Clonar/ubicar los proyectos

```powershell
# Cerebro
cd C:\RUNEFORGE_V2_CORE
npm install

# Músculo
cd C:\RUNEFORGE_V2_CORE\FlotaKW_Completo_v3.2_SOBERANO\FlotaKW_Completo\flota-kw-os\backend
pip install -r requirements.txt
2. Crear archivos __init__.py (namespace packages)
powershell
$Backend = 'C:\RUNEFORGE_V2_CORE\FlotaKW_Completo_v3.2_SOBERANO\FlotaKW_Completo\flota-kw-os\backend'
@("app\__init__.py","app\routers\__init__.py","app\middleware\__init__.py","app\services\__init__.py","app\utils\__init__.py") | ForEach-Object {
    $f = Join-Path $Backend $_
    if (-not (Test-Path $f)) { New-Item -ItemType File -Path $f -Force | Out-Null }
}
3. Configurar .env del Músculo
powershell
cd $Backend
"DATABASE_URL=sqlite:///./flotakw.db" | Set-Content .env -Encoding UTF8
⚡ Arranque
Opción A — Script único (recomendado)
Guarda como start-all.ps1 en C:\RUNEFORGE_V2_CORE:

powershell
# ============================================================
# RUNEFORGE · ARRANQUE COMPLETO
# ============================================================
$Root = 'C:\RUNEFORGE_V2_CORE'
$Backend = "$Root\FlotaKW_Completo_v3.2_SOBERANO\FlotaKW_Completo\flota-kw-os\backend"

Write-Host "════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  RUNEFORGE V2.6.2 · SOBERANO" -ForegroundColor Green
Write-Host "════════════════════════════════════════" -ForegroundColor Cyan

# 1. Limpiar procesos viejos
Get-Process node,python -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep 2

# 2. Arrancar Músculo (uvicorn :8000)
Write-Host "`n[1/2] Arrancando MÚSCULO :8000..." -ForegroundColor Yellow
Start-Process -FilePath 'python' `
    -ArgumentList '-m','uvicorn','app.main:app','--port','8000','--host','127.0.0.1' `
    -WorkingDirectory $Backend `
    -WindowStyle Minimized
Start-Sleep 5

# 3. Arrancar Cerebro (node :3001)
Write-Host "[2/2] Arrancando CEREBRO :3001..." -ForegroundColor Yellow
Start-Process -FilePath 'node' -ArgumentList 'server.js' -WorkingDirectory $Root -WindowStyle Minimized
Start-Sleep 4

# 4. Verificar
Write-Host "`n=== VERIFICACIÓN ===" -ForegroundColor Cyan
try {
    $h = Invoke-RestMethod http://127.0.0.1:3001/health -TimeoutSec 3
    Write-Host "  ✅ CEREBRO :3001 → $($h.status) v$($h.version)" -ForegroundColor Green
} catch {
    Write-Host "  ❌ CEREBRO :3001 no responde" -ForegroundColor Red
}
try {
    $m = Invoke-RestMethod http://127.0.0.1:8000/health -TimeoutSec 3
    Write-Host "  ✅ MÚSCULO :8000 → $($m.status)" -ForegroundColor Green
} catch {
    Write-Host "  ❌ MÚSCULO :8000 no responde" -ForegroundColor Red
}

# 5. Abrir navegador
Start-Process 'http://127.0.0.1:3001'
Write-Host "`n🎉 Sistema listo: http://127.0.0.1:3001" -ForegroundColor Green
Ejecuta:

powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
cd C:\RUNEFORGE_V2_CORE
.\start-all.ps1
Opción B — Manual
powershell
# Terminal 1 — Músculo
cd C:\RUNEFORGE_V2_CORE\FlotaKW_Completo_v3.2_SOBERANO\FlotaKW_Completo\flota-kw-os\backend
python -m uvicorn app.main:app --port 8000 --host 127.0.0.1

# Terminal 2 — Cerebro
cd C:\RUNEFORGE_V2_CORE
node server.js
Opción C — Tarea programada (auto-start)
powershell
$Root    = 'C:\RUNEFORGE_V2_CORE'
$Backend = "$Root\FlotaKW_Completo_v3.2_SOBERANO\FlotaKW_Completo\flota-kw-os\backend"

Register-ScheduledTask -TaskName 'RUNEFORGE_Cerebro' `
    -Action (New-ScheduledTaskAction -Execute 'node' -Argument 'server.js' -WorkingDirectory $Root) `
    -Trigger (New-ScheduledTaskTrigger -AtLogOn) -Force

Register-ScheduledTask -TaskName 'RUNEFORGE_Musculo' `
    -Action (New-ScheduledTaskAction -Execute 'python' -Argument '-m uvicorn app.main:app --port 8000 --host 127.0.0.1' -WorkingDirectory $Backend) `
    -Trigger (New-ScheduledTaskTrigger -AtLogOn) -Force
📁 Estructura del Proyecto
text
C:\RUNEFORGE_V2_CORE\
│
├── server.js                          # 🧠 Cerebro (Fastify)
├── package.json
├── ecosystem.config.js                # Config PM2 (opcional)
│
├── public/                            # Frontend del Cerebro
│   ├── index.html                     # Dashboard principal
│   ├── sync.js                        # Sincronización offline
│   └── db.js                          # IndexedDB (Dexie)
│
├── src/
│   └── routes/
│       ├── vault.js                   # Rutas de bóveda
│       └── flota.js                   # 🚦 Proxy → FlotaKW
│
├── db/
│   └── database.db                    # SQLite del Cerebro (clippings)
│
├── clippings/                         # 📄 Markdowns generados
│   └── *.md
│
├── docs/
│   └── idea/                          # Documentación servida
│       ├── INDEX.md
│       ├── Concepto.txt
│       ├── Arquitectura.txt
│       └── *.md · *.json · *.sql
│
├── logs/
│   └── server.log
│
└── FlotaKW_Completo_v3.2_SOBERANO/
    └── FlotaKW_Completo/
        └── flota-kw-os/
            └── backend/               # 💪 Músculo (FastAPI)
                ├── flotakw.db         # SQLite principal
                ├── .env
                ├── requirements.txt
                ├── RUN_SOBERANO.bat
                ├── app/
                │   ├── __init__.py
                │   ├── main.py        # Punto de entrada FastAPI
                │   ├── config.py
                │   ├── database.py
                │   ├── models.py      # SQLAlchemy models
                │   ├── schemas.py     # Pydantic schemas
                │   ├── routers/
                │   │   ├── unidades.py
                │   │   └── etiquetas.py
                │   ├── services/
                │   │   └── alta_service.py
                │   ├── middleware/
                │   │   └── tracing.py
                │   └── utils/
                │       └── etiqueta.py
                └── uvicorn.log
🔌 Endpoints
🧠 Cerebro (Fastify · :3001)
Método	Ruta	Descripción
GET	/health	Estado del sistema + versión + clippings
POST	/api/sync	Sincronización de telemetría offline
POST	/api/clipping	Guardar Markdown en clippings/
GET	/api/docs	Listar documentación disponible
GET	/api/docs/:file	Leer archivo específico de documentación
GET	/api/flota/health	Proxy → estado del Músculo
GET	/api/flota/unidades	Proxy → lista unidades
GET	/api/flota/unidades/:codigo	Proxy → detalle unidad
GET	/api/flota/tecnicos	Proxy → técnicos activos
GET	/api/flota/stats	Proxy → estadísticas
POST	/api/flota/alta	Proxy → alta atómica unidad
💪 Músculo (FastAPI · :8000)
Método	Ruta	Descripción
GET	/	Info ontología operativa
GET	/health	Health check
GET	/unidades	Lista unidades (paginada)
GET	/unidades/:codigo	Detalle unidad
POST	/alta	Alta atómica (unidad + beacon + instalación + auditoría)
GET	/tecnicos	Técnicos activos
GET	/auditoria	Log de auditoría
GET	/stats	Estadísticas globales
GET	/docs	Swagger UI
GET	/redoc	ReDoc
🖥 Frontend
Dashboard principal (http://127.0.0.1:3001)
Secciones:

Header — Estado dual Cerebro/Músculo, reloj en vivo

Flota KW — Tabla de unidades con:

Búsqueda por código/MAC/técnico

Modal de alta con validación

Export JSON

Auto-refresh cada 30s

Entrada Trama — Decodificador TLV + RAW/Target

Telemetría — KPIs V0/V1/T1/T2 + gráfica Canvas

Diagnóstico — Estado de calibración

Bitácora — Log de eventos con timestamps

Atajos de teclado
Atajo	Acción
Ctrl + Enter	Decodificar trama
Ctrl + S	Guardar clipping
Esc	Cerrar modales
📊 Esquemas de Datos
1. Payload de Telemetría (JSON)
json
{
  "id": 1,
  "esn": "4672073067",
  "v0": 12.585,
  "v1": 12.585,
  "t1": 25.0,
  "t2": 25.0,
  "raw_escort": 40858,
  "nivel": "235/1000",
  "target": 900,
  "lleno_calculado": 41581,
  "vacio": 34355,
  "lleno_real": 62000,
  "trama": "!E4672073067FFFFFF0100006A9083546A9083540F39E338C24A52B70000000000D015020014FFAD8F060600FFFF040000312900000FEC0000024400000292",
  "comandos": "!r3,62,34355\n!r3,63,41581\n!r0",
  "sync": 0,
  "timestamp": "2026-09-18T06:50:58.814Z"
}
2. Clipping Markdown (plantilla)
markdown
---
title: "TGL LAB V5 PRO"
source: "http://localhost:3001/"
created: "2026-09-18T06:50:58.814Z"
esn: "4672073067"
trama: "!E4672073067FFFFFF0100006A908354..."
nivel: "235/1000"
raw_escort: "40858"
target: "900"
lleno_calculado: "41581"
comandos: "!r3,62,34355 | !r3,63,41581 | !r0"
estado: "calibrado"
tags: [runeforge/clipping, tgl-lab, telemetry, calibracion]
---

# TGL LAB - 4672073067
RAW: 40858 | Nivel: 235/1000 | Target: 900

V0: 12.585V V1: 12.585V T1: 25.0C T2: 25.0C

## Comandos de Calibración
\`\`\`
!r3,62,34355
!r3,63,41581
!r3,62,34355
!r3,63,62000
!r0
\`\`\`

## Trama Original
\`\`\`
!E4672073067FFFFFF0100006A9083546A9083540F39E338C24A52B7...
\`\`\`
3. SQLite (Cerebro · db/database.db)
sql
CREATE TABLE IF NOT EXISTS telemetria (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    esn TEXT NOT NULL,
    v0 REAL, v1 REAL, t1 REAL, t2 REAL,
    raw_escort INTEGER,
    nivel TEXT,
    target INTEGER,
    lleno_calculado INTEGER,
    vacio INTEGER DEFAULT 34355,
    lleno_real INTEGER DEFAULT 62000,
    trama TEXT,
    comandos TEXT,
    sync INTEGER DEFAULT 0,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS clippings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    esn TEXT NOT NULL,
    raw INTEGER,
    nivel TEXT,
    comandos TEXT,
    markdown TEXT,
    filename TEXT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_telemetria_esn ON telemetria(esn);
CREATE INDEX IF NOT EXISTS idx_telemetria_sync ON telemetria(sync);
CREATE INDEX IF NOT EXISTS idx_clippings_esn ON clippings(esn);
4. SQLite (Músculo · flotakw.db)
sql
CREATE TABLE Tecnicos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre VARCHAR(100) UNIQUE NOT NULL,
    activo BOOLEAN DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Unidades (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    codigo VARCHAR(50) UNIQUE NOT NULL,
    estado VARCHAR(20) DEFAULT 'DISPONIBLE',
    mac VARCHAR(50),
    tecnico VARCHAR(100),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Beacons (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    unidad_id INTEGER,
    mac VARCHAR(50) UNIQUE NOT NULL,
    gps_marca_modelo VARCHAR(100),
    tipo VARCHAR(20) DEFAULT 'CALAMP',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Instalaciones (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    unidad_id INTEGER,
    beacon_id INTEGER,
    tecnico VARCHAR(100),
    fecha_instalacion DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Auditoria (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tabla_afectada VARCHAR(50),
    operacion VARCHAR(20),
    registro_id VARCHAR(50),
    datos_anterior TEXT,
    datos_nuevo TEXT,
    usuario VARCHAR(100),
    trace_id VARCHAR(50),
    accion VARCHAR(100),
    detalle VARCHAR(500),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
🔬 Lógica de Calibración 62K
Constantes:

javascript
VACIO      = 34355
LLENO_REAL = 62000
Fórmulas:

javascript
// Nivel actual (0-1000)
nivelActual = (raw_escort - VACIO) / (LLENO_REAL - VACIO) * 1000

// Nuevo valor de llenado para un target dado
LLENO_NUEVO = VACIO + (raw_escort - VACIO) / (target / 1000)
Comandos de calibración:

Comando	Descripción
!r3,62,34355	Reset VACÍO (constante)
!r3,63,<LLENO>	Set LLENO calculado
!r3,62,34355 + !r3,63,62000	Tabla 62K definitiva
!r0	Reset general
🔧 Troubleshooting
❌ ERR_CONNECTION_REFUSED en 127.0.0.1:3001
Causa: Cerebro no está corriendo.

powershell
cd C:\RUNEFORGE_V2_CORE
node server.js
❌ EADDRINUSE: address already in use :3001
Causa: Proceso node viejo sigue vivo.

powershell
Get-NetTCPConnection -LocalPort 3001 -State Listen | ForEach-Object {
    Stop-Process -Id $_.OwningProcess -Force
}
❌ /api/flota/health devuelve 404
Causa: Ruta /api/flota no registrada en server.js.

Solución: Verifica que server.js tenga:

javascript
fastify.register(require('./src/routes/flota'));
antes de fastify.listen(...). Reinicia el Cerebro.

❌ sqlite3.OperationalError: no such column
Causa: DB con esquema antiguo incompatible con el código nuevo.

Solución: Detén el Músculo, borra flotakw.db, reinícialo. Se regenera automáticamente.

powershell
# Detener
Get-Process python | Stop-Process -Force

# Backup + borrar
$B = 'C:\RUNEFORGE_V2_CORE\FlotaKW_Completo_v3.2_SOBERANO\FlotaKW_Completo\flota-kw-os\backend'
Copy-Item "$B\flotakw.db" "$B\flotakw.db.bak" -Force
Remove-Item "$B\flotakw.db" -Force

# Rearrancar
cd $B
python -m uvicorn app.main:app --port 8000 --host 127.0.0.1
❌ AttributeError: type object 'X' has no attribute 'Y'
Causa: El RUN_SOBERANO.bat sobrescribió models.py con una versión reducida.

Solución: Restaura models.py con todos los campos (gps_marca_modelo, tipo, beacon_id, fecha_instalacion, etc.).

❌ PM2 EPERM \\.\pipe\rpc.sock
Causa: Permisos del daemon PM2 en Node 24 + Windows.

Solución: No usar PM2. Usar Start-Process node directo o Tarea Programada.

❌ Músculo arranca pero /unidades da 500
Causa: Conflicto entre modelos y routers.

Solución:

powershell
$B = 'C:\RUNEFORGE_V2_CORE\FlotaKW_Completo_v3.2_SOBERANO\FlotaKW_Completo\flota-kw-os\backend'
Get-Content "$B\uvicorn.log.err" -Tail 40
Busca el AttributeError y alinea models.py con lo que espera el router.

📚 Glosario
Término	Significado
TGL	Sistema/empresa de logística pesada
ESN	Electronic Serial Number (10 dígitos)
TLV	Type-Length-Value (formato de trama hex)
LMU/ECU	Unidad de monitoreo de carga / Unidad de control electrónico
62K	Modelo de calibración basado en rango 34355–62000
Clipping	Informe Markdown compatible con Obsidian
Beacon	Dispositivo GPS/telemetría asociado a una unidad
Alta atómica	Transacción que crea unidad+beacon+instalación+auditoría en un solo commit
Cerebro	Fastify que orquesta y sirve el frontend
Músculo	FastAPI con la ontología operativa
Soberano	Sin dependencias cloud; todo local
Offline-Ready	Funciona sin internet (IndexedDB + sync diferido)
trace_id	Identificador único para rastrear una transacción completa
🎯 Roadmap
☑ Backend Fastify operativo
☑ Proxy Cerebro → Músculo
☑ Alta atómica con auditoría
☑ Generación de etiquetas con QR
☑ Clippings Markdown
☑ Dashboard con gestión de flota
□ Autenticación (Bearer token / API key)
□ WebSockets para telemetría en vivo
□ Tests automatizados (Jest + Pytest)
□ OpenAPI/Swagger del Cerebro
□ Docker Compose
□ Integración Tailscale para red mesh
□ Reportes PDF semanales
□ Predicción con Ollama
📄 Licencia
Uso interno · RUNEFORGE · TGL LAB

👥 Contribuidores
Runeforge Team — Arquitectura y desarrollo

TGL LAB — Operaciones de campo y validación

📞 Contacto
Cerebro: http://127.0.0.1:3001

Músculo: http://127.0.0.1:8000/docs

Docs: http://127.0.0.1:3001/api/docs

RUNEFORGE V2.6.2 · Soberano · 2026

text

---

**Instrucciones para guardarlo:**

```powershell
$readme = @'
...pega aquí todo el contenido de arriba...
'@

# O más simple: guarda el contenido en un archivo
notepad 'C:\RUNEFORGE_V2_CORE\README.md'
Luego Ctrl+F5 en http://127.0.0.1:3001/api/docs para verlo desde el endpoint (el Cerebro ya sirve esa carpeta).