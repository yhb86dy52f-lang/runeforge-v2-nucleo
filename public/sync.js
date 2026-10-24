const API_URL = window.location.origin + '/api/sync';
async function syncConPC(){
  if(!navigator.onLine) return;
  let pendientes=await db.telemetria.where('sync').equals(0).toArray();
  if(pendientes.length===0) return;
  try{
    let res=await fetch(API_URL,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(pendientes)});
    if(res.ok){
      let data=await res.json();
      for(let p of pendientes){ await db.telemetria.update(p.id,{sync:1}); }
      console.log('SYNC OK:', data.count);
    }
  }catch(e){ console.warn('SYNC FAIL offline', e); }
}
window.addEventListener('online',syncConPC);
setInterval(syncConPC, 15000);
