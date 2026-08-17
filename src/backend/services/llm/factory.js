const fs=require('fs');const path=require('path');const BaseProvider=require('./BaseProvider');
function expandEnvString(str,env){
  if(typeof str!=='string') return str;
  return str.replace(/\$\{([^}:\-]+)(?::-(.*?))?\}/g,(_,name,def)=>{
    const v=env[name];if(v!==undefined&&v!==''&&v!=='0.0.0.0') return v;
    if(name==='OLLAMA_HOST'&&(v==='0.0.0.0'||!v)) return def||'http://127.0.0.1:11434';
    return def!==undefined?def:'';
  }).replace(/\$([A-Z0-9_]+)/g,(_,name)=>{if(name==='HOST') return '';return env[name]||'';});
}
function expandObject(obj,env){
  if(typeof obj==='string') return expandEnvString(obj,env);
  if(Array.isArray(obj)) return obj.map(v=>expandObject(v,env));
  if(obj&&typeof obj==='object'){const r={};for(const k of Object.keys(obj)) r[k]=expandObject(obj[k],env);return r;}
  return obj;
}
function loadDotEnv(basePath){
  const envPath=path.join(basePath,'.env');const env={};
  if(!fs.existsSync(envPath)) return {...process.env,OLLAMA_HOST:process.env.OLLAMA_HOST||'http://127.0.0.1:11434'};
  try{
    const content=fs.readFileSync(envPath,'utf8');
    for(const line of content.split('\n')){
      const trimmed=line.trim();if(!trimmed||trimmed.startsWith('#')) continue;
      const eq=trimmed.indexOf('=');if(eq===-1) continue;
      const key=trimmed.slice(0,eq).trim();let val=trimmed.slice(eq+1).trim();
      if((val.startsWith('"')&&val.endsWith('"'))||(val.startsWith("'")&&val.endsWith("'"))){val=val.slice(1,-1);}
      env[key]=val;
    }
  }catch{}
  return {...env,...process.env,OLLAMA_HOST:env.OLLAMA_HOST||process.env.OLLAMA_HOST||'http://127.0.0.1:11434'};
}
function loadProfiles(basePath='C:\\RUNEFORGE_V2_CORE'){
  const env=loadDotEnv(basePath);const configPath=path.join(basePath,'config','llm-profiles.json');
  let raw={profiles:{}};if(fs.existsSync(configPath)){try{raw=JSON.parse(fs.readFileSync(configPath,'utf8'));}catch(e){raw={profiles:{},error:e.message};}}
  let expanded=expandObject(raw,env);
  if(expanded.profiles?.ollama?.endpoint==='0.0.0.0'||!expanded.profiles?.ollama?.endpoint?.startsWith('http')){expanded.profiles.ollama.endpoint='http://127.0.0.1:11434';}
  return {profiles:expanded.profiles||{},raw:expanded,env,configPath};
}
function createProvider(name='ollama',basePath='C:\\RUNEFORGE_V2_CORE'){
  const {profiles,env}=loadProfiles(basePath);const prof=profiles[name];
  if(!prof) throw new Error(`Profile ${name} not found`);
  const providerType=prof.provider||name;let Adapter;
  try{
    if(providerType==='ollama') Adapter=require('./adapters/ollama');
    else Adapter=require('./BaseProvider');
  }catch{Adapter=require('./BaseProvider');}
  const expandedProfile=expandObject(prof,env);
  if(expandedProfile.endpoint==='0.0.0.0'||!expandedProfile.endpoint?.startsWith('http')){expandedProfile.endpoint='http://127.0.0.1:11434';}
  return new Adapter(expandedProfile,env);
}
function listProviders(basePath){const {profiles}=loadProfiles(basePath);return Object.keys(profiles);}
module.exports={loadProfiles,createProvider,listProviders,expandEnvString,expandObject,loadDotEnv};
