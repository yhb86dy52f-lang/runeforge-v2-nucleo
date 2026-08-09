const model = "qwen2.5:1.5b";
const ollamaUrl = "http://127.0.0.1:11434/api/chat";
const sysmsg = "Eres RF_LOCAL_AI de Runeforge. Runeforge es un ecosistema local-first: PC Windows backend, Ollama en PC, Tailscale red privada, WhatsApp canal/adaptador, iPhone consola ligera. Flujo obligatorio: INPUT -> ROUTER -> SKILL -> ACTION -> TRACE -> RESPONSE. Responde breve, tecnico y en espanol. No inventes. No ejecutes comandos.";
function hashId(v){let h=0;for(const c of String(v||"")){h=((h<<5)-h)+c.charCodeAt(0);h|=0;}return "hash_"+Math.abs(h);}
function normalizeInbound(text){return {rf_schema:"rf.whatsapp.inbound_message.v1",received_at:new Date().toISOString(),channel:"whatsapp",from_hash:hashId("5210000000000"),message_id:"wamid.DRYRUN_LOCAL_AI",type:"text",text,route:text.startsWith("/ai")?"chat_local_ai":text.startsWith("/help")?"help":"blocked",trace_id:"rf_wa_ai_"+Date.now(),policy:"DRYRUN_ONLY_NO_SHELL"};}
function buildWhatsAppReply(to,body){return {messaging_product:"whatsapp",to,type:"text",text:{body}};}
const inbound = normalizeInbound("/ai Explica en 2 lineas que es Runeforge");
const userPrompt = inbound.text.replace(/^\/ai\s*/,"").trim();
let aiOk=false; let answer=""; let error=null;
try {
  const controller = new AbortController();
  const timer = setTimeout(()=>controller.abort(),180000);
  const payload = {model,messages:[{role:"system",content:sysmsg},{role:"user",content:userPrompt}],stream:false};
  const response = await fetch(ollamaUrl,{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify(payload),signal:controller.signal});
  clearTimeout(timer);
  const data = await response.json();
  answer = data?.message?.content || "";
  aiOk = Boolean(response.ok && answer);
} catch(e) { error = String(e?.message || e); }
const outbound = buildWhatsAppReply("DRYRUN_USER_WA_ID", aiOk ? answer : "RF_LOCAL_AI_ERROR_DRYRUN");
const outboundOk = outbound.messaging_product==="whatsapp" && outbound.to && outbound.type==="text" && outbound.text && outbound.text.body;
const result = {rf_schema:"rf.whatsapp.local_ai.route.dryrun.v1",created_at:new Date().toISOString(),estado:(aiOk&&outboundOk)?"RF_WHATSAPP_LOCAL_AI_ROUTE_DRYRUN_OK":"RF_WHATSAPP_LOCAL_AI_ROUTE_DRYRUN_FAIL",inbound,local_ai:{model,ollama_url:ollamaUrl,ok:aiOk,error},outbound_payload:outbound,outbound_payload_ok:Boolean(outboundOk),backend:"NO_TOCADO",pm2:"NO_TOCADO",firewall:"NO_TOCADO",secrets:"NO_IMPRESOS",real_whatsapp_send:"NO_REAL_SEND",siguiente:(aiOk&&outboundOk)?"RF_WHATSAPP_MVP_CURRENT_STATUS_V1":"REVISAR_OLLAMA_LOCAL"};
console.log(JSON.stringify(result,null,2));
