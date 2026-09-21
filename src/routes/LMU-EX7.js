'use strict'
module.exports = async function(fastify){
  const FLOTA='http://127.0.0.1:8000'
  const LLM='http://127.0.0.1:3100'
  async function pf(url,opts={}){
    const c=new AbortController(); const t=setTimeout(()=>c.abort(),15000);
    try{ const r=await fetch(url,{...opts,signal:c.signal}); const txt=await r.text(); let d; try{d=JSON.parse(txt)}catch{d={raw:txt}}; return {status:r.status,data:d,[STRIPPED] } finally{ clearTimeout(t) }
  }
  fastify.post('/api/flota/alta', async (req,reply)=>{
    const trace=req.id; const {codigo,mac,tecnico,gps_marca_modelo}=req.body;
    let llm=null; try{ const lr=await pf(`${LLM}/api/chat`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({message:`Valida MAC ${mac} ${codigo} JSON`,model:'qwen2.5:1.5b',stream:false,trace_id:trace})}); if(lr.ok) llm=lr.data }catch{}
    const fr=await pf(`${FLOTA}/api/v1/alta`,{method:'POST',headers:{'Content-Type':'application/json','X-Trace-Id':trace},body:JSON.stringify({codigo,mac,tecnico,gps_marca_modelo})});
    if(!fr.ok) return reply.status(fr.status).send({error:'FlotaKW fallo',trace_id:trace,detalle:fr.data,llm});
    return reply.send({...fr.data,proxy:'runeforge-3001',trace_id:trace,llm,soberano:true});
  });
  fastify.get('/api/flota/unidades', async (req,reply)=>{ const qs=new URLSearchParams(req.query).toString(); const r=await pf(`${FLOTA}/api/v1/unidades?${qs}`); return reply.status(r.status).send(r.data) });
  fastify.get('/api/flota/health', async ()=>({runeforge:'UP 3001',flotakw:'check 8000',fusion:'SOBERANA WAL'}));
}