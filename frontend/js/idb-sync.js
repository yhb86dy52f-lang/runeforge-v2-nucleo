const DB_NAME='runeforge-v25'; 
let queue=JSON.parse(localStorage.getItem('rf_queue')||'[]');
export function saveOffline(type,payload){
  const item={type,payload,ts:Date.now(), deviceId: localStorage.getItem('rf_device')||'anon'};
  queue.push(item);
  localStorage.setItem('rf_queue', JSON.stringify(queue));
  if(navigator.onLine) syncNow();
}
export async function syncNow(){
  if(!queue.length) return;
  try{
    const r=await fetch('/api/sync',{method:'POST', headers:{'Content-Type':'application/json'}, body: JSON.stringify({queue})});
    const d=await r.json();
    if(d.ok){ queue=[]; localStorage.setItem('rf_queue','[]'); console.log('SYNC OK',d.merged); }
  }catch(e){ console.log('Offline, guardado local', e); }
}
window.addEventListener('online', syncNow);
setInterval(syncNow, 10000);
