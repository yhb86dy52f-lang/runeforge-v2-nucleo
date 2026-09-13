// curar_inbox.js - Procesa knowledge\00_INBOX (68 archivos) -> bitacoras_v2
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
    const stmt = db.prepare(`INSERT OR IGNORE INTO bitacoras_v2 (fecha,tipo,proyecto,texto_original,texto_limpio,estado,origen,parse_confidence,hash,meta_json) VALUES (@fecha,@tipo,@proyecto,@texto_original,@texto_limpio,@estado,@origen,@parse_confidence,@hash,@meta_json)`);
    stmt.run({
      fecha: parsed.fecha,
      tipo: parsed.tipo,
      proyecto: parsed.proyecto,
      texto_original: parsed.texto_original,
      texto_limpio: parsed.texto_limpio,
      estado: parsed.estado,
      origen: 'curacion_inbox',
      parse_confidence: parsed.parse_confidence,
      hash: parsed.hash,
      meta_json: JSON.stringify({ duda: parsed.duda||false })
    });
    db.close();
    return 'better-sqlite3';
  } catch(e){
    // fallback sql.js
    const initSqlJs = require('sql.js');
    const SQL = await initSqlJs();
    const buf = fs.readFileSync(DB_PATH);
    const db = new SQL.Database(buf);
    try{
      db.run(`INSERT OR IGNORE INTO bitacoras_v2 (fecha,tipo,proyecto,texto_original,texto_limpio,estado,origen,parse_confidence,hash) VALUES (?,?,?,?,?,?,?, ?,?)`, [parsed.fecha, parsed.tipo, parsed.proyecto, parsed.texto_original, parsed.texto_limpio, parsed.estado, 'curacion_inbox', parsed.parse_confidence, parsed.hash]);
    } catch(e2){ /* ignore duplicate */ }
    const data = db.export();
    fs.writeFileSync(DB_PATH, Buffer.from(data));
    return 'sql.js';
  }
}

async function main(){
  if(!fs.existsSync(INBOX)){ console.log('No existe', INBOX); return; }
  const files = fs.readdirSync(INBOX).filter(f=>!f.startsWith('.'));
  console.log(`Inbox: ${files.length} archivos`);
  let ok=0, dudas=0;
  for(const file of files){
    const full = path.join(INBOX, file);
    try{
      const stat = fs.statSync(full);
      if(stat.isDirectory()) continue;
      let txt = fs.readFileSync(full,'utf8').slice(0,2000);
      if(!txt.trim()) continue;
      const parsed = parser.parseBitacora(txt);
      if(parsed.duda){
        dudas++;
        console.log(` DUDA: ${file} -> ${parsed.tipo} ${parsed.respuesta?.slice(0,60)}`);
        continue;
      }
      await insertRow(parsed);
      ok++;
      // mover a procesados
      const destDir = path.join(ROOT, 'knowledge', parsed.proyecto==='Ciner' ? '01_MEMORIAS' : '02_PROYECTOS');
      fs.mkdirSync(destDir, {recursive:true});
      // no movemos, solo copiamos marca
    } catch(e){ console.log(` ERR ${file}: ${e.message}`); }
  }
  console.log(`\nCuracion terminada: ${ok} insertados, ${dudas} dudas`);
  // contar DB
  try{
    const initSqlJs = require('sql.js');
    const SQL = await initSqlJs();
    const buf = fs.readFileSync(DB_PATH);
    const db = new SQL.Database(buf);
    const res = db.exec('SELECT COUNT(*) as c FROM bitacoras_v2');
    console.log(`DB total ahora: ${res[0]?.values[0][0]} registros`);
  } catch(e){}
}

main();
