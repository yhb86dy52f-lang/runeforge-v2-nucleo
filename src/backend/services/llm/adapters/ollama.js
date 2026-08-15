const BaseProvider=require('../BaseProvider');
class OllamaProvider extends BaseProvider{
  constructor(profile,env){
    super(profile,env);this.name='ollama';
    let ep=this.expandEnv(profile.endpoint||'http://127.0.0.1:11434');
    if(ep==='0.0.0.0'||!ep.startsWith('http')) ep='http://127.0.0.1:11434';
    this.endpoint=ep.replace(/\/$/,'');
  }
  async health(){
    try{
      const controller=new AbortController();const t=setTimeout(()=>controller.abort(),3000);
      const res=await fetch(`${this.endpoint}/api/tags`,{signal:controller.signal});clearTimeout(t);
      const data=await res.json();const models=(data.models||[]).map(m=>m.name);
      return {ok:true,online:true,provider:'ollama',endpoint:this.endpoint,models,count:models.length,vram:this.limits};
    }catch(e){return {ok:false,online:false,provider:'ollama',endpoint:this.endpoint,error:e.message};}
  }
  async chat(input,options={}){
    const messages=this.formatMessages(input);const model=options.model||this.getModel(options.modelAlias||'default');const params=this.getParams(options);
    const body={model,messages,stream:false,keep_alive:params.keep_alive||'10m',options:{temperature:Number(params.temperature??0.7),top_p:Number(params.top_p??0.9),top_k:Number(params.top_k??40),num_ctx:Number(params.num_ctx??4096),num_predict:Number(params.num_predict??512),repeat_penalty:Number(params.repeat_penalty??1.1),seed:Number(params.seed??-1)}};
    if(options.system){body.messages=[{role:'system',content:options.system},...messages];}
    const res=await fetch(`${this.endpoint}/api/chat`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(body)});
    if(!res.ok){const txt=await res.text();throw new Error(`Ollama chat ${res.status}: ${txt}`);}
    const data=await res.json();const content=data.message?.content||data.response||'';
    return {ok:true,provider:'ollama',model,response:content,content,meta:{model,eval_count:data.eval_count,prompt_eval_count:data.prompt_eval_count,eval_duration:data.eval_duration,prompt_eval_duration:data.prompt_eval_duration,total_duration:data.total_duration,load_duration:data.load_duration}};
  }
  async generate(prompt,options={}){
    const model=options.model||this.getModel('default');const params=this.getParams(options);
    const body={model,prompt,stream:false,keep_alive:params.keep_alive||'10m',options:{temperature:Number(params.temperature??0.7),num_ctx:Number(params.num_ctx??4096),num_predict:Number(params.num_predict??512)}};
    const res=await fetch(`${this.endpoint}/api/generate`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(body)});
    if(!res.ok) throw new Error(`Ollama generate ${res.status}`);const data=await res.json();return {ok:true,provider:'ollama',model,response:data.response,meta:data};
  }
  async embed(text){
    const model=this.getModel('embed');const res=await fetch(`${this.endpoint}/api/embeddings`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({model,prompt:text})});
    if(!res.ok) throw new Error(`Ollama embed ${res.status}`);const data=await res.json();return {ok:true,embedding:data.embedding,model};
  }
  async ps(){try{const res=await fetch(`${this.endpoint}/api/ps`);return await res.json();}catch{return {models:[]};}}
}
module.exports=OllamaProvider;
