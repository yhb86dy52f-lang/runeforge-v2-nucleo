# ⚡ RUNEFORGE V2.6.2 · TGL LAB V5 PRO

> Sistema soberano de diagnóstico, calibración y gestión de flota para módulos LMU/ECU.
> Arquitectura Edge-First · Offline-Ready · Trazabilidad Inmutable.

---

## 📖 Tabla de Contenidos

- [Descripción](#-descripción)
- [Arquitectura](#-arquitectura)
- [Arranque](#-arranque)
- [Endpoints](#-endpoints)
- [Calibración 62K](#-calibración-62k)
- [Troubleshooting](#-troubleshooting)
- [Glosario](#-glosario)

---

## 🎯 Descripción

**RUNEFORGE** es el ecosistema principal. Aloja dos aplicaciones que colaboran en modo Cerebro ↔ Músculo:

| Rol | Aplicación | Puerto | Responsabilidad |
|---|---|---|---|
| 🧠 **Cerebro** | TGL LAB V5 PRO (Fastify) | `3001` | Dashboard, decodificador, telemetría, clippings, proxy a FlotaKW |
| 💪 **Músculo** | FlotaKW OS v3.2 (FastAPI) | `8000` | Ontología operativa, alta atómica, auditoría inmutable |
| 🤖 **LLM** | Ollama | `3100` | Validación semántica (opcional) |

**Filosofía:**

> *"Tu base de datos es tu única fuente de verdad."*

---

## 🏗 Arquitectura

    NAVEGADOR (Usuario)
         │
         ▼ http://127.0.0.1:3001
    ┌──────────────────────────────┐
    │ 🧠 CEREBRO (Fastify :3001)   │
    │   /health                    │
    │   /api/sync                  │
    │   /api/clipping              │
    │   /api/docs                  │
    │   /api/flota/* → PROXY       │
    └─────────┬────────────────────┘
              │
              ▼ fetch
    ┌──────────────────────────────┐
    │ 💪 MÚSCULO (FastAPI :8000)   │
    │   /unidades   /alta          │
    │   /auditoria  /tecnicos      │
    │   /stats      /docs          │
    └─────────┬────────────────────┘
              │
              ▼
        ┌───────────┐
        │ SQLite DB │
        │flotakw.db │
        └───────────┘

---

## 📋 Requisitos

| Componente | Versión mínima | Verificar |
|---|---|---|
| Windows | 10/11 | `winver` |
| Node.js | 20.x+ | `node --version` |
| Python | 3.12+ | `python --version` |
| PowerShell | 7.x+ | `$PSVersionTable.PSVersion` |
| Ollama (opcional) | última | `ollama --version` |

---

## 🚀 Instalación

### 1. Cerebro (Node.js)

    cd C:\RUNEFORGE_V2_CORE
    npm install

### 2. Músculo (Python)

    cd C:\RUNEFORGE_V2_CORE\FlotaKW_Completo_v3.2_SOBERANO\FlotaKW_Completo\flota-kw-os\backend
    pip install -r requirements.txt

### 3. Crear namespace packages

    $Backend = "C:\RUNEFORGE_V2_CORE\FlotaKW_Completo_v3.2_SOBERANO\FlotaKW_Completo\flota-kw-os\backend"
    @("app\__init__.py","app\routers\__init__.py","app\middleware\__init__.py",
      "app\services\__init__.py","app\utils\__init__.py") | ForEach-Object {
        New-Item -ItemType File -Path (Join-Path $Backend $_) -Force | Out-Null
    }

---

## ⚡ Arranque

### Terminal 1 — Músculo (:8000)

    cd C:\RUNEFORGE_V2_CORE\FlotaKW_Completo_v3.2_SOBERANO\FlotaKW_Completo\flota-kw-os\backend
    python -m uvicorn app.main:app --port 8000 --host 127.0.0.1

### Terminal 2 — Cerebro (:3001)

    cd C:\RUNEFORGE_V2_CORE
    node server.js

### Verificar

    Invoke-RestMethod http://127.0.0.1:3001/health
    Invoke-RestMethod http://127.0.0.1:8000/health
    Invoke-RestMethod http://127.0.0.1:3001/api/flota/health

---

## 🔌 Endpoints

### 🧠 Cerebro (Fastify · :3001)

| Método | Ruta | Descripción |
|---|---|---|
| GET | `/health` | Estado del sistema |
| POST | `/api/sync` | Sincronización telemetría |
| POST | `/api/clipping` | Guardar Markdown |
| GET | `/api/docs` | Listar documentación |
| GET | `/api/docs/:file` | Leer archivo de docs |
| GET | `/api/flota/health` | Proxy → estado del Músculo |
| GET | `/api/flota/unidades` | Proxy → lista unidades |
| GET | `/api/flota/unidades/:codigo` | Proxy → detalle unidad |
| GET | `/api/flota/tecnicos` | Proxy → técnicos activos |
| GET | `/api/flota/stats` | Proxy → estadísticas |
| POST | `/api/flota/alta` | Proxy → alta atómica |

### 💪 Músculo (FastAPI · :8000)

| Método | Ruta | Descripción |
|---|---|---|
| GET | `/` | Info ontología |
| GET | `/health` | Health check |
| GET | `/unidades` | Lista unidades (paginada) |
| GET | `/unidades/:codigo` | Detalle unidad |
| POST | `/alta` | Alta atómica (unidad + beacon + instalación + auditoría) |
| GET | `/tecnicos` | Técnicos activos |
| GET | `/auditoria` | Log auditoría |
| GET | `/stats` | Estadísticas |
| GET | `/docs` | Swagger UI |
| GET | `/redoc` | ReDoc |

---

## 🖥 Frontend

**Dashboard:** http://127.0.0.1:3001

Secciones:

1. Header con estado dual Cerebro/Músculo
2. **Flota KW** — tabla con búsqueda, alta, export JSON, auto-refresh
3. **Entrada Trama** — decodificador TLV + RAW/Target
4. **Telemetría** — KPIs V0/V1/T1/T2 + gráfica Canvas
5. **Diagnóstico** — estado de calibración
6. **Bitácora** — log de eventos

### Atajos de teclado

| Atajo | Acción |
|---|---|
| `Ctrl + Enter` | Decodificar trama |
| `Ctrl + S` | Guardar clipping |
| `Esc` | Cerrar modales |

---

## 📊 Esquemas de Datos

### Payload de Telemetría (JSON)

    {
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
      "trama": "!E4672073067FFFFFF010000...",
      "comandos": "!r3,62,34355\n!r3,63,41581\n!r0",
      "sync": 0,
      "timestamp": "2026-09-18T06:50:58.814Z"
    }

### SQLite Cerebro (`db/database.db`)

    CREATE TABLE telemetria (
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

    CREATE TABLE clippings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        esn TEXT NOT NULL,
        raw INTEGER,
        nivel TEXT,
        comandos TEXT,
        markdown TEXT,
        filename TEXT,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
    );

### SQLite Músculo (`flotakw.db`)

    CREATE TABLE Tecnicos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre VARCHAR(100) UNIQUE NOT NULL,
        activo BOOLEAN DEFAULT 1,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE Unidades (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        codigo VARCHAR(50) UNIQUE NOT NULL,
        estado VARCHAR(20) DEFAULT "DISPONIBLE",
        mac VARCHAR(50),
        tecnico VARCHAR(100),
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE Beacons (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        unidad_id INTEGER,
        mac VARCHAR(50) UNIQUE NOT NULL,
        gps_marca_modelo VARCHAR(100),
        tipo VARCHAR(20) DEFAULT "CALAMP",
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
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );

---

## 🔬 Calibración 62K

Constantes:

    VACIO      = 34355
    LLENO_REAL = 62000

Fórmulas:

    nivel_actual = (raw - VACIO) / (LLENO_REAL - VACIO) * 1000
    lleno_nuevo  = VACIO + (raw - VACIO) / (target / 1000)

Comandos:

| Comando | Descripción |
|---|---|
| `!r3,62,34355` | Reset VACÍO (constante) |
| `!r3,63,<LLENO>` | Set LLENO calculado |
| `!r3,62,34355` + `!r3,63,62000` | Tabla 62K definitiva |
| `!r0` | Reset general |

---

## 🔧 Troubleshooting

### ERR_CONNECTION_REFUSED en :3001

Causa: Cerebro no está corriendo.

    cd C:\RUNEFORGE_V2_CORE
    node server.js

### EADDRINUSE: address already in use :3001

Causa: Proceso node viejo sigue vivo.

    Get-NetTCPConnection -LocalPort 3001 -State Listen | ForEach-Object {
        Stop-Process -Id $_.OwningProcess -Force
    }

### /api/flota/health devuelve 404

Causa: Ruta no registrada en server.js.

Verifica que exista antes de fastify.listen:

    fastify.register(require("./src/routes/flota"));

### sqlite3.OperationalError: no such column

Causa: DB con esquema antiguo.

Solución: detener Músculo, borrar DB, reiniciar.

    $B = "C:\RUNEFORGE_V2_CORE\FlotaKW_Completo_v3.2_SOBERANO\FlotaKW_Completo\flota-kw-os\backend"
    Copy-Item "$B\flotakw.db" "$B\flotakw.db.bak" -Force
    Remove-Item "$B\flotakw.db" -Force
    cd $B
    python -m uvicorn app.main:app --port 8000 --host 127.0.0.1

### AttributeError: type object has no attribute

Causa: models.py reducido por RUN_SOBERANO.bat.
Solución: restaurar models.py con todos los campos (gps_marca_modelo, tipo, beacon_id, fecha_instalacion, etc).

### PM2 EPERM pipe rpc.sock

Causa: Permisos del daemon PM2 en Node 24 + Windows.
Solución: no usar PM2. Usar Start-Process node directo.

---

## 📚 Glosario

| Término | Significado |
|---|---|
| TGL | Sistema/empresa de logística pesada |
| ESN | Electronic Serial Number (10 dígitos) |
| TLV | Type-Length-Value (formato de trama hex) |
| LMU/ECU | Unidad de monitoreo de carga / Unidad de control electrónico |
| 62K | Modelo de calibración basado en rango 34355–62000 |
| Clipping | Informe Markdown compatible con Obsidian |
| Beacon | Dispositivo GPS/telemetría asociado a una unidad |
| Alta atómica | Transacción que crea unidad + beacon + instalación + auditoría |
| Cerebro | Fastify que orquesta y sirve el frontend |
| Músculo | FastAPI con la ontología operativa |
| Soberano | Sin dependencias cloud; todo local |
| Offline-Ready | Funciona sin internet (IndexedDB + sync diferido) |
| trace_id | Identificador único para rastrear una transacción |

---

## 🎯 Roadmap

- [x] Backend Fastify operativo
- [x] Proxy Cerebro → Músculo
- [x] Alta atómica con auditoría
- [x] Generación de etiquetas con QR
- [x] Clippings Markdown
- [x] Dashboard con gestión de flota
- [ ] Autenticación (Bearer token)
- [ ] WebSockets para telemetría en vivo
- [ ] Tests automatizados (Jest + Pytest)
- [ ] Docker Compose
- [ ] Integración Tailscale mesh
- [ ] Reportes PDF semanales
- [ ] Predicción con Ollama

---

## 📞 Contacto

- Cerebro: http://127.0.0.1:3001
- Músculo: http://127.0.0.1:8000/docs
- Docs:    http://127.0.0.1:3001/api/docs

---

*RUNEFORGE V2.6.2 · Soberano · 2026*
