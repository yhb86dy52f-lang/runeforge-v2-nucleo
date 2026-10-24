const fs = require('fs');
const path = require('path');
const ROOT = path.join(__dirname, '..', '..');
const INBOX = path.join(ROOT, 'knowledge', '00_INBOX');
const DB_PATH = path.join(ROOT, 'data', 'runeforge.db');
const parser = require('./services/bitacora_parser.js');
async function insertRow(parsed){
  try{
    const Database = require('better-sqlite3');
    const db = new Database(DB_PATH);
    db.prepare(`INSERT OR IGNORE INTO bitacoras_v2 (fecha,tipo,proyecto,texto_original,texto_limpio,estado,origen,parse_confidence,hash,meta_json) VALUES (@fecha,@tipo,@proyecto,@texto_original,@texto_limpio,@estado,@origen,@parse_confidence,@hash,@meta_json)`).run({
      fecha: parsed.fecha, tipo: parsed.tipo, proyecto: parsed.proyecto,
      texto_original: parsed.texto_original, texto_limpio: parsed.texto_limpio,
      estado: parsed.estado, origen: 'curacion_inbox', parse_confidence: parsed.parse_confidence, hash: parsed.hash, meta_json: JSON.stringify({ duda: parsed.duda||false })
    });
    db.close();
  } catch(e){
    const initSqlJs = require('sql.js');
    const SQL = await initSqlJs();
    const buf = fs.readFileSync(DB_PATH);
    const db = new SQL.Database(buf);
    try{ db.run(`INSERT OR IGNORE INTO bitacoras_v2 (fecha,tipo,proyecto,texto_original,texto_limpio,estado,origen,parse_confidence,hash) VALUES (?,?,?,?,?,?,?, ?,?)`, [parsed.fecha, parsed.tipo, parsed.proyecto, parsed.texto_original, parsed.texto_limpio, parsed.estado, 'curacion_inbox', parsed.parse_confidence, parsed.hash]); }catch{}
    fs.writeFileSync(DB_PATH, Buffer.from(db.export()));
  }
}
async function main(){
  const files = fs.readdirSync(INBOX).filter(f=>!f.startsWith('.'));
  console.log(`Inbox: ${files.length} archivos`);
  let ok=0,dudas=0;
  for(const file of files){
    try{
      const txt = fs.readFileSync(path.join(INBOX,file),'utf8').slice(0,2000);
      if(!txt.trim()) continue;
      const parsed = parser.parseBitacora(txt);
      if(parsed.duda){ dudas++; continue; }
      await insertRow(parsed); ok++;
    }catch(e){ console.log(`ERR ${file}: ${e.message}`); }
  }
  console.log(`Curacion: ${ok} insertados, ${dudas} dudas`);
}
main();
