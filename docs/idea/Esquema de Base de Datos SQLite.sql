-- Tabla para almacenar la telemetría cruda y calculada
CREATE TABLE IF NOT EXISTS telemetria (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    esn TEXT NOT NULL,
    v0 REAL,
    v1 REAL,
    t1 REAL,
    t2 REAL,
    raw_escort INTEGER,
    nivel TEXT,
    target INTEGER,
    lleno_calculado INTEGER,
    vacio INTEGER DEFAULT 34355,
    lleno_real INTEGER DEFAULT 62000,
    trama TEXT,
    comandos TEXT,
    sync INTEGER DEFAULT 0, -- 0 = Pendiente, 1 = Sincronizado
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Tabla para almacenar los clippings generados (metadatos)
CREATE TABLE IF NOT EXISTS clippings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    esn TEXT NOT NULL,
    raw INTEGER,
    nivel TEXT,
    comandos TEXT,
    markdown TEXT, -- Contenido completo del archivo .md
    filename TEXT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Índices para búsquedas rápidas
CREATE INDEX IF NOT EXISTS idx_telemetria_esn ON telemetria(esn);
CREATE INDEX IF NOT EXISTS idx_telemetria_sync ON telemetria(sync);
CREATE INDEX IF NOT EXISTS idx_clippings_esn ON clippings(esn);