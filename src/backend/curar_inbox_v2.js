const fs=require('fs');const path=require('path');const ROOT=path.join(__dirname,'..','..');const INBOX=path.join(ROOT,'knowledge','00_INBOX');const DB=path.join(ROOT,'data','runeforge.db');const parser=require('./services/bitacora_parser.js');
async function insertRow(p){
  try{
    const Database=require('better-sqlite3');const db=new Database(DB);
    db.prepare(`INSERT OR IGNORE INTO bitacoras_v2 (fecha,tipo,proyecto,texto_original,texto_limpio,estado,origen,parse_confidence,hash) VALUES (@fecha,@tipo,@proyecto,@texto_original,@texto_limpio,@estado,@origen,@parse_confidence,@hash)`).run({fecha:p.fecha,tipo:p.tipo,proyecto:p.proyecto,texto_original:p.texto_original,texto_limpio:p.texto_limpio,estado:p.estado,origen:'curacion',parse_confidence:p.parse_confidence,hash:p.hash});
    db.close();
  }catch(e){
    const initSqlJs=require('sql.js');const SQL=await initSqlJs();const buf=fs.readFileSync(DB);const db=new SQL.Database(buf);
    try{db.run(`INSERT OR IGNORE INTO bitacoras_v2 (fecha,tipo,proyecto,texto_original,texto_limpio,estado,origen,parse_confidence,hash) VALUES (?,?,?,?,?,?,?, ?,?)`,[p.fecha,p.tipo,p.proyecto,p.texto_original,p.texto_limpio,p.estado,'curacion',p.parse_confidence,p.hash]);}catch{}
    fs.writeFileSync(DB,Buffer.from(db.export()));
  }
}
(async()=>{
  const files=fs.readdirSync(INBOX,{withFileTypes:true});
  let ok=0,dudas=0,skip=0;
  for(const entry of files){
    if(entry.isDirectory()){skip++;continue;}
    const full=path.join(INBOX,entry.name);
    try{
      const txt=fs.readFileSync(full,'utf8').slice(0,2000);
      if(!txt.trim()){skip++;continue;}
      const parsed=parser.parseBitacora(txt);
      if(parsed.duda){dudas++;continue;}
      await insertRow(parsed); ok++;
      // archiva el archivo procesado
      const archive=path.join(ROOT,'knowledge','99_ARCHIVE_INBOX'); fs.mkdirSync(archive,{recursive:true});
      try{ fs.renameSync(full, path.join(archive, entry.name)); }catch{}
    }catch(e){ console.log(`ERR ${entry.name}: ${e.message}`); }
  }
  console.log(`Curacion v2: ${ok} insertados, ${dudas} dudas, ${skip} carpetas/vacios saltados`);
})();
