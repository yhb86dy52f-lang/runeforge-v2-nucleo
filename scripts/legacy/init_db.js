const sql = require('sql.js');
const fs = require('fs');
const path = require('path');

const dbPath = path.join(__dirname, '..', 'data', 'runeforge.db');
const dir = path.dirname(dbPath);
if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });

const db = new sql.Database();
db.run(
  CREATE TABLE IF NOT EXISTS bitacoras_v2 (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    fecha TEXT NOT NULL,
    tipo TEXT,
    proyecto TEXT,
    texto_original TEXT,
    texto_limpio TEXT,
    estado TEXT DEFAULT 'pendiente',
    origen TEXT,
    parse_confidence TEXT,
    correccion_de INTEGER,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
  )
);
const data = db.export();
fs.writeFileSync(dbPath, Buffer.from(data));
console.log('DB creada en ' + dbPath + ' (' + data.length + ' bytes)');
