-- schema_bitacoras_v2.sql - Runeforge Etapa 1 v2
-- SQLite WAL - tabla honesta para T/P/A/H/R + parsing robusto

PRAGMA journal_mode=WAL;
PRAGMA synchronous=NORMAL;
PRAGMA auto_vacuum=NONE;
PRAGMA wal_autocheckpoint=1000;

CREATE TABLE IF NOT EXISTS bitacoras_v2 (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  fecha TEXT NOT NULL, -- ISO8601 2026-08-15T22:44:00-06:00
  tipo TEXT NOT NULL CHECK(tipo IN ('T','P','A','H','R','U')), -- T_telemetria P_problema A_actividad H_habito R_tarea U_unknown
  proyecto TEXT NOT NULL DEFAULT 'personal', -- Ciner / personal / Runeforge
  texto_original TEXT NOT NULL, -- nunca se pierde
  texto_limpio TEXT, -- normalizado
  estado TEXT NOT NULL DEFAULT 'pendiente' CHECK(estado IN ('pendiente','en_progreso','resuelto','hecho','archivado','duda')),
  origen TEXT NOT NULL DEFAULT 'manual', -- telegram, form_n8n, whatsapp, manual, import
  parse_confidence TEXT NOT NULL DEFAULT 'baja' CHECK(parse_confidence IN ('alta','media','baja')),
  correccion_de INTEGER REFERENCES bitacoras_v2(id),
  hash TEXT UNIQUE, -- SHA256 corto texto+fecha para deduplicar
  meta_json TEXT, -- {sensor, km, etc}
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
  updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now'))
);

CREATE INDEX IF NOT EXISTS idx_bitacoras_fecha ON bitacoras_v2(fecha DESC);
CREATE INDEX IF NOT EXISTS idx_bitacoras_tipo ON bitacoras_v2(tipo);
CREATE INDEX IF NOT EXISTS idx_bitacoras_proyecto ON bitacoras_v2(proyecto);
CREATE INDEX IF NOT EXISTS idx_bitacoras_estado ON bitacoras_v2(estado);
CREATE INDEX IF NOT EXISTS idx_bitacoras_hash ON bitacoras_v2(hash);

-- Vista trabajo vs personal (misma tabla)
CREATE VIEW IF NOT EXISTS v_ciner AS SELECT * FROM bitacoras_v2 WHERE proyecto='Ciner' AND estado!='archivado' ORDER BY fecha DESC;
CREATE VIEW IF NOT EXISTS v_personal AS SELECT * FROM bitacoras_v2 WHERE proyecto!='Ciner' ORDER BY fecha DESC;
CREATE VIEW IF NOT EXISTS v_dudas AS SELECT * FROM bitacoras_v2 WHERE parse_confidence='baja' OR estado='duda' ORDER BY created_at DESC;

-- Trigger updated_at
CREATE TRIGGER IF NOT EXISTS trg_bitacoras_updated AFTER UPDATE ON bitacoras_v2 BEGIN UPDATE bitacoras_v2 SET updated_at=strftime('%Y-%m-%dT%H:%M:%fZ','now') WHERE id=NEW.id; END;

-- Seed ejemplo honesto
INSERT OR IGNORE INTO bitacoras_v2 (fecha, tipo, proyecto, texto_original, texto_limpio, estado, origen, parse_confidence, hash) VALUES
('2026-08-15T22:44:00-06:00','T','Ciner','T Ciner sensor km 42 fallo intermitente','sensor km 42 fallo intermitente','pendiente','manual','alta','demo_hash_001');
