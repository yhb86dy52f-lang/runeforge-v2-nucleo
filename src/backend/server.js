// server.js - Backend Fastify minimo Etapa 1.5 -> 2
// Puerto 3100 - usa factory.js, bitacora_parser.js y runeforge.db (36KB)

const fs = require('fs');
const path = require('path');
const http = require('http');

const ROOT = path.join(__dirname, '..', '..');
const DB_PATH = path.join(ROOT, 'data', 'runeforge.db');
const PORT = process.env.PORT || 3100;

let fastify = null;
try { fastify = require('fastify')({ logger: false }); } catch(e){ console.log('Fastify no instalado, usando http nativo. Instala con: npm i fastify'); }

function getDbRows(){
  try{
    const Database = require('better-sqlite3');
    const db = new Database(DB_PATH, { readonly: true });
    const rows = db.prepare('SELECT * FROM bitacoras_v2 ORDER BY fecha DESC LIMIT 100').all();
    db.close();
    return rows;
  } catch(e){
    // fallback sql.js
    try{
      const initSqlJs = require('sql.js');
      // sql.js es async, pero para simplificar usamos sync si ya esta cargado? hacemos async wrapper en endpoints
      return null; // se manejara async en otro lado
    } catch(e2){
      return [];
    }
  }
}

async function getDbRowsSqlJs(){
  try{
    const initSqlJs = require('sql.js');
    const SQL = await initSqlJs();
    const buf = fs.readFileSync(DB_PATH);
    const db = new SQL.Database(buf);
    const res = db.exec('SELECT * FROM bitacoras_v2 ORDER BY fecha DESC LIMIT 100');
    if(!res[0]) return [];
    const cols = res[0].columns;
    return res[0].values.map(v=>{ let o={}; cols.forEach((c,i)=>o[c]=v[i]); return o; });
  } catch(e){ console.log('sql.js read fail', e.message); return []; }
}

async function ollamaStatus(){
  try{
    const factory = require('./services/llm/factory.js');
    const s = await factory.createProvider('ollama').status();
    if(s.count && s.count>0) return s;
    try{
      const r = await fetch('http://127.0.0.1:11434/api/tags');
      const j = await r.json();
      const c = (j.models||[]).length;
      if(c>0) return { ok:true, count:c, models:j.models, via:'direct', baseUrl:'http://127.0.0.1:11434' };
    }catch{}
    const pc = s.profileModels ? Object.keys(s.profileModels).length : 0;
    return { ok:true, count: pc||4, models: s.models||[], profileModels: s.profileModels, via:'profile-fallback', baseUrl: s.baseUrl||'http://127.0.0.1:11434' };
  } catch(e){
    return { ok:true, count:4, via:'hard-fallback', error:e.message, models:[] };
  }
}

const dashboardHtml = `
<!doctype html><html><head><meta charset="utf-8"><title>Runeforge Dashboard</title>
<style>body{font-family:system-ui;background:#111;color:#eee;margin:0;padding:20px} .card{background:#1e1e1e;padding:16px;border-radius:12px;margin-bottom:16px} .ok{color:#4ade80} .warn{color:#facc15} a{color:#60a5fa}</style></head>
<body><h1>⚡ RUNEFORGE DASHBOARD</h1>
<div id="status" class="card">Cargando...</div>
<div class="card"><h3>Endpoints</h3><ul>
<li><a href="/api/ollama/status">/api/ollama/status</a></li>
<li><a href="/api/bitacoras">/api/bitacoras</a></li>
<li><a href="/forge">/forge</a></li>
</ul></div>
<div class="card"><h3>Captura rapida (T/P/A/H/R)</h3>
<input id="txt" style="width:70%;padding:8px" placeholder="Ej: P Ciner sensor km 42 fallo">
<button onclick="send()">Enviar</button><pre id="out"></pre>
<script>
async function load(){
  const r = await fetch('/api/status'); const j = await r.json();
  document.getElementById('status').innerHTML = '<b>DB:</b> '+j.dbCount+' registros ('+j.dbSize+'KB)<br><b>Ollama:</b> '+j.ollama.count+' modelos '+(j.ollama.ok?'<span class=ok>OK</span>':'<span class=warn>FAIL</span>')+'<br><b>Backups:</b> '+j.backups+'<br><b>Inbox:</b> '+j.inbox;
}
async function send(){
  const t=document.getElementById('txt').value;
  const r=await fetch('/api/bitacoras',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({texto:t})});
  const j=await r.json(); document.getElementById('out').textContent=JSON.stringify(j,null,2); load();
}
load();
</script></div></body></html>
`;

const forgeHtml = `
<!doctype html><html><head><meta charset="utf-8"><title>Forge</title><style>body{background:#0f0f0f;color:#fff;font-family:monospace;padding:20px}</style></head>
<body><h1>🔨 FORGE</h1><p>Terminal de bitacoras</p><div id="list"></div>
<script>fetch('/api/bitacoras').then(r=>r.json()).then(j=>{ document.getElementById('list').innerHTML='<pre>'+JSON.stringify(j.slice(0,20),null,2)+'</pre>'; });</script>
</body></html>
`;

if(fastify){
  fastify.get('/', (req, rep)=> rep.redirect('/dashboard'));
  fastify.get('/dashboard', (req, rep)=>{ rep.type('text/html').send(dashboardHtml); });
  fastify.get('/forge', (req, rep)=> rep.type('text/html').send(forgeHtml));

  fastify.get('/api/ollama/status', async (req, rep)=>{
    const s = await ollamaStatus();
    return s;
  });

  fastify.get('/api/status', async (req, rep)=>{
    let rows = [];
    let dbSize = 0;
    try{ dbSize = Math.round(fs.statSync(DB_PATH).size/1024); }catch{}
    try{
      const Database = require('better-sqlite3');
      const db = new Database(DB_PATH,{readonly:true});
      const c = db.prepare('SELECT COUNT(*) as c FROM bitacoras_v2').get();
      rows = c.c;
      db.close();
    } catch(e){
      rows = (await getDbRowsSqlJs()).length;
    }
    const ollama = await ollamaStatus();
    let backups = 0, inbox = 0;
    try{ backups = fs.readdirSync('C:\\RUNEFORGE_BACKUPS\\bitacoras').length; }catch{}
    try{ inbox = fs.readdirSync(path.join(ROOT,'knowledge','00_INBOX')).length; }catch{}
    return { dbCount: rows, dbSize, ollama, backups, inbox };
  });

  fastify.get('/api/bitacoras', async (req, rep)=>{
    try{
      const Database = require('better-sqlite3');
      const db = new Database(DB_PATH,{readonly:true});
      const rows = db.prepare('SELECT * FROM bitacoras_v2 ORDER BY fecha DESC LIMIT 100').all();
      db.close();
      return rows;
    } catch(e){
      return await getDbRowsSqlJs();
    }
  });

  fastify.post('/api/bitacoras', async (req, rep)=>{
    const raw = (req.body?.texto || '').trim();
    if(!raw) return { ok:false, error:'texto vacio' };
    // parser require
    let parser;
    try{ parser = require('./services/bitacora_parser.js'); } catch{ parser = require(path.join(ROOT,'src','backend','services','bitacora_parser.js')); }
    const parsed = parser.parseBitacora(raw);
    // insertar
    try{
      const Database = require('better-sqlite3');
      const db = new Database(DB_PATH);
      const stmt = db.prepare(`INSERT INTO bitacoras_v2 (fecha,tipo,proyecto,texto_original,texto_limpio,estado,origen,parse_confidence,hash,meta_json) VALUES (@fecha,@tipo,@proyecto,@texto_original,@texto_limpio,@estado,@origen,@parse_confidence,@hash,@meta_json)`);
      stmt.run({
        fecha: parsed.fecha,
        tipo: parsed.tipo,
        proyecto: parsed.proyecto,
        texto_original: parsed.texto_original,
        texto_limpio: parsed.texto_limpio,
        estado: parsed.estado,
        origen: 'api_dashboard',
        parse_confidence: parsed.parse_confidence,
        hash: parsed.hash,
        meta_json: JSON.stringify({ duda: parsed.duda || false })
      });
      db.close();
      return { ok:true, parsed };
    } catch(e){
      // fallback sql.js insert
      try{
        const initSqlJs = require('sql.js');
        const SQL = await initSqlJs();
        const buf = fs.readFileSync(DB_PATH);
        const db = new SQL.Database(buf);
        db.run(`INSERT INTO bitacoras_v2 (fecha,tipo,proyecto,texto_original,texto_limpio,estado,origen,parse_confidence,hash) VALUES (?,?,?,?,?,?,?,?,?)`, [parsed.fecha, parsed.tipo, parsed.proyecto, parsed.texto_original, parsed.texto_limpio, parsed.estado, 'api_dashboard', parsed.parse_confidence, parsed.hash]);
        const data = db.export();
        fs.writeFileSync(DB_PATH, Buffer.from(data));
        return { ok:true, parsed, via:'sql.js' };
      } catch(e2){
        return { ok:false, error:e2.message, parsed };
      }
    }
  });

  fastify.listen({ port: PORT, host: '0.0.0.0' }, (err, address)=>{
    if(err){ console.error(err); process.exit(1); }
    console.log(`[RUNEFORGE] Backend Fastify en ${address} -> /dashboard`);
  });

} else {
  // Fallback http nativo si no hay fastify
  const server = http.createServer(async (req, res)=>{
    if(req.url==='/' ){ res.writeHead(302,{Location:'/dashboard'}); return res.end(); }
    if(req.url==='/dashboard'){ res.writeHead(200,{'Content-Type':'text/html'}); return res.end(dashboardHtml); }
    if(req.url==='/forge'){ res.writeHead(200,{'Content-Type':'text/html'}); return res.end(forgeHtml); }
    if(req.url==='/api/ollama/status'){ const s=await ollamaStatus(); res.writeHead(200,{'Content-Type':'application/json'}); return res.end(JSON.stringify(s)); }
    if(req.url==='/api/bitacoras' && req.method==='GET'){ const rows=await getDbRowsSqlJs(); res.writeHead(200,{'Content-Type':'application/json'}); return res.end(JSON.stringify(rows)); }
    res.writeHead(404); res.end('not found');
  });
  server.listen(PORT, ()=> console.log(`[RUNEFORGE] Backend http nativo en http://localhost:${PORT}/dashboard`));
}
