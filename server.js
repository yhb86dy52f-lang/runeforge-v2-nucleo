const path = require('path');
const fastify = require('fastify')({ logger: true });
fastify.register(require('@fastify/cors'), { origin: true });
fastify.register(require('@fastify/static'), { root: path.join(__dirname, 'public'), prefix: '/' });

fastify.get('/health', async () => ({ ok:true, service:'runeforge-backend', port:3100, ts:new Date().toISOString() }));
fastify.get('/api/estatus', async () => ({ ok:true, backend:'online', relay:'online', ollama:'online', ts:new Date().toISOString() }));
fastify.get('/api/ollama/status', async () => {
  try { const r = await fetch('http://127.0.0.1:11434/api/tags'); const j = await r.json(); return { ok:true, count:(j.models||[]).length }; }
  catch(e){ return { ok:false, error:e.message }; }
});
fastify.post('/api/chat', async (req) => {
  const { message, model } = req.body || {};
  try {
    const r = await fetch('http://127.0.0.1:11434/api/generate', { method:'POST', headers:{'Content-Type':'application/json'}, body: JSON.stringify({ model: model||'qwen2.5:1.5b', prompt: message||'Hola', stream:false }) });
    const j = await r.json(); return { ok:true, response:j.response };
  } catch(e){ return { ok:false, error:e.message }; }
});
fastify.listen({ port:3100, host:'0.0.0.0' }, (err, addr) => { if(err){ fastify.log.error(err); process.exit(1);} console.log('BACKEND V2.6 OK '+addr); });
