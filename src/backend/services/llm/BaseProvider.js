class BaseProvider {
  constructor(profile={},env=process.env){
    this.profile=profile;this.env=env;this.name=profile.provider||'base';
    this.endpoint=this.expandEnv(profile.endpoint||'');
    if(this.endpoint==='0.0.0.0'||!this.endpoint.startsWith('http')){this.endpoint='http://127.0.0.1:11434';}
    this.models=profile.models||{default:'qwen2.5:1.5b'};this.params=profile.params||{};this.limits=profile.limits||{};
  }
  expandEnv(str){
    if(typeof str!=='string') return str;
    return str.replace(/\$\{([^}:\-]+)(?::-(.*?))?\}/g,(_,varName,defVal)=>{
      const v=this.env[varName];
      if(v!==undefined&&v!==''&&v!=='0.0.0.0') return v;
      if(varName==='OLLAMA_HOST'&&(v==='0.0.0.0'||!v)) return defVal||'http://127.0.0.1:11434';
      return defVal!==undefined?defVal:'';
    }).replace(/\$([A-Z0-9_]+)/g,(_,varName)=>{if(varName==='HOST') return '';return this.env[varName]||'';});
  }
  expandObject(obj){
    if(typeof obj==='string') return this.expandEnv(obj);
    if(Array.isArray(obj)) return obj.map(v=>this.expandObject(v));
    if(obj&&typeof obj==='object'){const r={};for(const k of Object.keys(obj)) r[k]=this.expandObject(obj[k]);return r;}
    return obj;
  }
  getModel(alias='default'){const m=this.models[alias]||this.models.default||'qwen2.5:1.5b';return this.expandEnv(m);}
  getParams(overrides={}){const base=this.expandObject(this.params);return {...base,...overrides};}
  async health(){return {ok:true,provider:this.name,endpoint:this.endpoint,model:this.getModel()};}
  async chat(messages,options={}){throw new Error(`chat() not implemented in ${this.name}`);}
  async embed(text){throw new Error(`embed() not implemented in ${this.name}`);}
  async listModels(){return Object.values(this.models);}
  formatMessages(input){if(typeof input==='string') return [{role:'user',content:input}];if(Array.isArray(input)) return input;return [{role:'user',content:String(input)}];}
}
module.exports=BaseProvider;
