const fastify = require('fastify')({ logger: true });
const path = require('path');
const fs = require('fs');
const sqlite3 = require('sqlite3').verbose();

const DB_PATH = path.join(__dirname, 'db', 'database.db');
if(!fs.existsSync(path.join(__dirname, 'db'))){ fs.mkdirSync(path.join(__dirname, 'db'), {recursive:true}); }

const db = new sqlite3.Database(DB_PATH, (err)=>{
  if(err) console.error(err);
  else console.log('SQLite conectado:', DB_PATH);
});

function initDB(){
  const schema = fs.readFileSync(path.join(__dirname, 'db', 'schema.sql'), 'utf8');
  db.exec(schema, (err)=>{ if(err) console.error('schema error', err); else console.log('schema ok'); });
}
initDB();

fastify.register(require('@fastify/cors'), { origin: true });

// Static public
fastify.register(require('@fastify/static'), {
  root: path.join(__dirname, 'public'),
  prefix: '/',
});

// API SYNC desde PWA
fastify.post('/api/sync', async (req, reply)=>{
  const data = req.body;
  if(!Array.isArray(data)) return reply.code(400).send({error:'esperaba array'});
  let count=0;
  await new Promise((resolve, reject)=>{
    db.serialize(()=>{
      const stmt = db.prepare("INSERT INTO telemetria (esn, v0, v1, raw_escort, trama, timestamp, sync) VALUES (?,?,?,?,?,?,1)");
      for(let row of data){
        stmt.run(row.esn, row.v0, row.v1, row.raw_escort||0, row.trama||'', row.timestamp? new Date(row.timestamp).toISOString() : new Date().toISOString());
        count++;
      }
      stmt.finalize((e)=>{ if(e) reject(e); else resolve(); });
    });
  });
  return {ok:true, count};
});

fastify.get('/api/flota', async (req, reply)=>{
  return new Promise((resolve)=>{
    db.all("SELECT * FROM telemetria ORDER BY id DESC LIMIT 100", (err, rows)=>{
      if(err) resolve([]);
      else resolve(rows);
    });
  });
});

fastify.get('/api/unidades', async ()=>{
  return new Promise((resolve)=>{
    db.all("SELECT * FROM unidades", (err, rows)=> resolve(rows||[]));
  });
});

fastify.get('/api/health', async ()=>({ok:true, version:'V5 PRO 62K', db: DB_PATH}));

const start = async ()=>{
  try{
    await fastify.listen({ port: 3001, host: '0.0.0.0' });
    console.log('TGL LAB V5 PRO corriendo en http://localhost:3001');
  }catch(err){
    fastify.log.error(err);
    process.exit(1);
  }
};
start();

