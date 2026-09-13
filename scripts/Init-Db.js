// init_db.js FIX v2 - funciona sin better-sqlite3 usando sql.js puro JS
const fs = require('fs');
const path = require('path');
const dbPath = path.join(process.cwd(), 'data', 'runeforge.db');
const schemaPath = path.join(process.cwd(), 'scripts', 'schema_bitacoras_v2.sql');

fs.mkdirSync(path.dirname(dbPath), {recursive:true});

let schema = fs.readFileSync(schemaPath, 'utf8');

async function createWithSqlJs(){
  try{
    const initSqlJs = require('sql.js');
    const SQL = await initSqlJs();
    const db = new SQL.Database();
    db.exec(schema);
    const data = db.export();
    const buffer = Buffer.from(data);
    fs.writeFileSync(dbPath, buffer);
    console.log(`DB creada en ${dbPath} con sql.js (${buffer.length} bytes)`);
    // verifica
    const db2 = new SQL.Database(buffer);
    const res = db2.exec('SELECT COUNT(*) as c FROM bitacoras_v2');
    console.log(`Registros iniciales: ${res[0]?.values[0][0] ?? 0}`);
    return true;
  } catch(e){
    console.log('sql.js fallo:', e.message);
    return false;
  }
}

async function main(){
  // 1. intenta better-sqlite3
  try{
    const Database = require('better-sqlite3');
    const db = new Database(dbPath);
    db.exec(schema);
    const c = db.prepare('SELECT COUNT(*) as c FROM bitacoras_v2').get();
    console.log(`DB creada en ${dbPath} con better-sqlite3, registros: ${c.c}`);
    return;
  } catch(e){
    console.log('better-sqlite3 no disponible:', e.message);
  }
  // 2. intenta sql.js
  if(await createWithSqlJs()) return;

  // 3. fallback: intenta sqlite3 CLI si existe
  console.log('Intentando sqlite3 CLI...');
  const { execSync } = require('child_process');
  try{
    execSync(`sqlite3 "${dbPath}" < "${schemaPath}"`, {stdio:'inherit'});
    console.log(`DB creada via sqlite3 CLI en ${dbPath}`);
    return;
  } catch(e){
    console.log('sqlite3 CLI no disponible');
  }

  // 4. ultimo fallback: crea archivo vacio y avisa
  console.log('No se pudo crear DB con drivers. Instalando sql.js...');
  try{
    execSync('npm i sql.js --silent', {stdio:'inherit'});
    if(await createWithSqlJs()) return;
  } catch(e){}

  console.error('FALLO: instala manualmente: npm i sql.js  o  winget install SQLite.SQLite');
  if(!fs.existsSync(dbPath)) fs.writeFileSync(dbPath, Buffer.alloc(0));
}

main();
