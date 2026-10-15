#pragma once
#include <Arduino.h>

const char settings_html[] PROGMEM = R"HTML(
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Scanner PRO · Configuración v8.3</title>
<script src="https://cdn.tailwindcss.com"></script>
<script src="https://unpkg.com/lucide@latest"></script>
<style>
body { background: radial-gradient(circle at 20% 0%, #0f1b3d 0%, #070a14 55%, #03050a 100%); }
.glass { background: rgba(15,23,42,.65); backdrop-filter: blur(18px); border: 1px solid rgba(255,255,255,.07); }
.btn { transition: transform .12s ease, background .2s ease; }
.btn:active { transform: scale(.97); }
input[type=number], input[type=text], input[type=password] {
  background: #0f172a; border: 1px solid #334155; border-radius: .75rem;
  padding: .5rem .75rem; color: #e2e8f0; width: 100%; font-family: ui-monospace, monospace;
}
input:focus, textarea:focus { outline: 2px solid #06b6d4; }
label { font-size: .75rem; color: #94a3b8; text-transform: uppercase; letter-spacing: .05em; font-weight: 700; }
textarea { background:#0f172a; border:1px solid #334155; border-radius:.75rem; padding:.5rem .75rem; color:#e2e8f0; width:100%; font-family: ui-monospace, monospace; font-size:.8rem; }
.wifi-item { transition: background .15s ease; }
.wifi-item:hover { background: rgba(6,182,212,.15); }
</style>
</head>
<body class="text-slate-100 min-h-screen p-3 md:p-6 font-sans">

<header class="glass rounded-3xl p-4 flex justify-between items-center shadow-2xl mb-4 max-w-2xl mx-auto">
  <div class="flex items-center gap-3">
    <div class="p-3 bg-gradient-to-tr from-cyan-500 to-violet-600 rounded-2xl">
      <i data-lucide="settings" class="w-6 h-6 text-white"></i>
    </div>
    <div>
      <h1 class="text-xl font-black">Configuración</h1>
      <p class="text-[11px] text-slate-400 font-mono">v8.3 FIELD · AP+STA + Fallback</p>
    </div>
  </div>
  <a href="/" class="btn bg-slate-800/80 hover:bg-slate-700 px-3 py-2 rounded-xl text-xs font-bold flex items-center gap-2">
    <i data-lucide="arrow-left" class="w-4 h-4"></i> Volver
  </a>
</header>

<main class="max-w-2xl mx-auto space-y-4">

  <!-- AP PROPIO - NUEVO PARA TRABAJO EN CAMPO -->
  <section class="glass rounded-3xl p-5 space-y-3 border border-cyan-400/30 bg-gradient-to-br from-cyan-950/20 to-transparent">
    <div class="flex items-center justify-between">
      <div class="flex items-center gap-2">
        <i data-lucide="router" class="w-5 h-5 text-cyan-300"></i>
        <h2 class="font-bold uppercase text-sm tracking-wide">Red Propia ESP (Modo Campo)</h2>
      </div>
      <div class="flex items-center gap-2">
        <label class="cursor-pointer text-[10px]">SIEMPRE ON</label>
        <input id="apAlwaysOn" type="checkbox" class="w-5 h-5 accent-cyan-500">
      </div>
    </div>
    <p class="text-[11px] text-cyan-200/60">Cuando está ON, el ESP crea su propia WiFi <b>además</b> de conectarse a casa. Fuera de casa, te conectas directo al ESP en 192.168.4.1. Ideal para yarda / carretera.</p>
    <div class="grid grid-cols-2 gap-3">
      <div><label>SSID AP (tu red)</label><input id="apSSID" type="text" maxlength="31" placeholder="ScannerPRO-Setup"></div>
      <div><label>PASS AP</label><input id="apPass" type="text" maxlength="63" placeholder="12345678"></div>
      <div><label>Canal AP (1-13)</label><input id="apChannel" type="number" min="1" max="13"></div>
      <div class="flex items-end"><div class="text-[10px] text-slate-400">IP AP siempre: <b>192.168.4.1</b><br>Conéctate y abre esa IP</div></div>
    </div>
  </section>

  <section class="glass rounded-3xl p-5 space-y-3 border border-cyan-500/20">
    <div class="flex items-center justify-between">
      <div class="flex items-center gap-2">
        <i data-lucide="wifi" class="w-5 h-5 text-cyan-400"></i>
        <h2 class="font-bold uppercase text-sm tracking-wide">Redes WiFi Cliente (3 slots)</h2>
      </div>
      <button onclick="scanWiFi()" class="btn bg-cyan-600 hover:bg-cyan-500 px-3 py-1.5 rounded-lg text-xs font-bold flex items-center gap-1">
        <i data-lucide="radar" class="w-3 h-3"></i> Escanear
      </button>
    </div>
    <p class="text-[11px] text-slate-500">El ESP32 intenta en orden: Slot 1 → Slot 2 → Slot 3. Slot 1 casa, Slot2 hotspot celular, Slot3 yarda.</p>

    <div class="space-y-3 pt-2">
      <div class="border border-slate-700 rounded-xl p-3 space-y-2">
        <div class="text-[10px] font-bold text-cyan-300">SLOT 1 (primario casa)</div>
        <div><label>SSID</label><input id="ssid" type="text" maxlength="63"></div>
        <div><label>Contraseña</label><input id="pass" type="password" maxlength="63" placeholder="(sin cambios)"></div>
      </div>
      <div class="border border-slate-700 rounded-xl p-3 space-y-2">
        <div class="text-[10px] font-bold text-violet-300">SLOT 2 (hotspot celular)</div>
        <div><label>SSID</label><input id="ssid2" type="text" maxlength="63" placeholder="(vacío = desactivado)"></div>
        <div><label>Contraseña</label><input id="pass2" type="password" maxlength="63" placeholder="(sin cambios)"></div>
      </div>
      <div class="border border-slate-700 rounded-xl p-3 space-y-2">
        <div class="text-[10px] font-bold text-amber-300">SLOT 3 (yarda / otro)</div>
        <div><label>SSID</label><input id="ssid3" type="text" maxlength="63" placeholder="(vacío = desactivado)"></div>
        <div><label>Contraseña</label><input id="pass3" type="password" maxlength="63" placeholder="(sin cambios)"></div>
      </div>
      <div><label>mDNS (nombre.local)</label><input id="mdns" type="text" maxlength="31"></div>
    </div>

    <div class="flex gap-2 pt-2">
      <button onclick="wifiReconnect()" class="btn bg-slate-800 hover:bg-slate-700 px-3 py-2 rounded-lg text-xs font-bold flex items-center gap-1 flex-1">
        <i data-lucide="refresh-cw" class="w-3 h-3"></i> Forzar reconexión STA
      </button>
    </div>

    <div id="scan-result" class="hidden mt-2 bg-slate-900/60 rounded-xl p-3 max-h-64 overflow-y-auto"></div>
    <p class="text-[11px] text-amber-400/80">⚠ Cambiar SSID/pass requiere reiniciar.</p>
  </section>

  <section class="glass rounded-3xl p-5 space-y-3 border border-emerald-500/20">
    <div class="flex items-center justify-between">
      <div class="flex items-center gap-2">
        <i data-lucide="radio-tower" class="w-5 h-5 text-emerald-400"></i>
        <h2 class="font-bold uppercase text-sm tracking-wide">MQTT</h2>
      </div>
      <div class="flex items-center gap-2">
        <label class="cursor-pointer text-[10px]">HABILITADO</label>
        <input id="mqttEnabled" type="checkbox" class="w-5 h-5 accent-emerald-500">
      </div>
    </div>

    <div class="border border-emerald-500/30 rounded-xl p-3 space-y-2">
      <div class="text-[10px] font-bold text-emerald-300">BROKER PRIMARIO (LAN local)</div>
      <div class="grid grid-cols-2 gap-3">
        <div class="col-span-2 md:col-span-1"><label>Servidor</label><input id="mqttServer" type="text" maxlength="63"></div>
        <div><label>Puerto</label><input id="mqttPort" type="number" min="1" max="65535"></div>
      </div>
    </div>

    <div class="flex items-center justify-between p-2 bg-slate-900/60 rounded-xl border border-slate-700">
      <div>
        <p class="text-xs font-bold">Usar broker FALLBACK</p>
        <p class="text-[10px] text-slate-400">Cuando el primario falla (útil fuera de casa)</p>
      </div>
      <input id="mqttFallbackEnabled" type="checkbox" class="w-5 h-5 accent-emerald-500">
    </div>

    <div class="border border-violet-500/30 rounded-xl p-3 space-y-2">
      <div class="text-[10px] font-bold text-violet-300">BROKER FALLBACK (internet)</div>
      <div class="grid grid-cols-2 gap-3">
        <div class="col-span-2 md:col-span-1"><label>Servidor</label><input id="mqttFallbackServer" type="text" maxlength="63" placeholder="broker.hivemq.com"></div>
        <div><label>Puerto fallback</label><input id="mqttFallbackPort" type="number" min="1" max="65535"></div>
      </div>
      <div class="flex gap-2 pt-2">
        <button onclick="mqttSwitch()" class="btn bg-slate-800 hover:bg-slate-700 px-3 py-1.5 rounded-lg text-xs font-bold flex items-center gap-1">
          <i data-lucide="shuffle" class="w-3 h-3"></i> Switch Primary/Fallback
        </button>
      </div>
    </div>

    <div class="grid grid-cols-2 gap-3">
      <div><label>Topic</label><input id="mqttTopic" type="text" maxlength="63"></div>
      <div><label>Client ID</label><input id="mqttClient" type="text" maxlength="31"></div>
    </div>
  </section>

  <section class="glass rounded-3xl p-5 space-y-3">
    <div class="flex items-center gap-2">
      <i data-lucide="filter" class="w-5 h-5 text-cyan-400"></i>
      <h2 class="font-bold uppercase text-sm tracking-wide">Filtros BLE</h2>
    </div>
    <div class="flex items-center justify-between p-2 bg-slate-900/60 rounded-xl border border-slate-700">
      <div>
        <p class="text-xs font-bold">Filtro habilitado</p>
        <p class="text-[10px] text-slate-400">Si OFF, deja pasar todo</p>
      </div>
      <input id="filterEnabled" type="checkbox" class="w-5 h-5 accent-cyan-500">
    </div>
    <div class="grid grid-cols-2 gap-3">
      <div><label>RSSI mínimo (ej -90)</label><input id="rssiMin" type="number" min="-120" max="-40"></div>
      <div><label>Scan Interval ms</label><input id="scanInterval" type="number" min="50" max="1000"></div>
      <div><label>Scan Window ms</label><input id="scanWindow" type="number" min="50" max="1000"></div>
      <div class="flex items-center gap-2 pt-5">
        <input id="activeScan" type="checkbox" class="w-5 h-5 accent-cyan-500">
        <label>Active Scan</label>
      </div>
    </div>
    <div><label>Prefijos MAC (coma)</label><textarea id="macPrefixes" rows="2"></textarea></div>
    <div><label>Filtros Nombre (coma)</label><textarea id="nameFilters" rows="3"></textarea></div>
  </section>

  <section class="glass rounded-3xl p-5 space-y-3">
    <div class="flex items-center gap-2">
      <i data-lucide="activity" class="w-5 h-5 text-violet-400"></i>
      <h2 class="font-bold uppercase text-sm tracking-wide">Kalman + Debug</h2>
    </div>
    <div class="grid grid-cols-2 gap-3">
      <div><label>Q</label><input id="kQ" type="number" step="0.0001" min="0.0001" max="100"></div>
      <div><label>R</label><input id="kR" type="number" step="0.001" min="0.001" max="100"></div>
      <div><label>P (covarianza)</label><input id="kP" type="number" step="0.01" min="0.01" max="1000"></div>
      <div><label>X₀ RSSI inicial</label><input id="kX0" type="number" step="1" min="-120" max="-40"></div>
    </div>
    <div class="flex items-center justify-between p-3 bg-slate-900/60 rounded-xl border border-slate-700">
      <div>
        <p class="text-sm font-bold">Debug: log todos los dispositivos</p>
        <p class="text-[11px] text-slate-400">Si OFF, solo imprime los que pasan filtro</p>
      </div>
      <input id="debugLogAll" type="checkbox" class="w-6 h-6 accent-cyan-500">
    </div>
  </section>

  <div class="grid grid-cols-2 gap-3">
    <button onclick="save()" class="btn bg-gradient-to-r from-cyan-600 to-emerald-600 font-black py-3.5 rounded-2xl flex items-center justify-center gap-2">
      <i data-lucide="save" class="w-5 h-5"></i> GUARDAR
    </button>
    <button onclick="reset()" class="btn bg-gradient-to-r from-red-600 to-rose-700 font-black py-3.5 rounded-2xl flex items-center justify-center gap-2">
      <i data-lucide="rotate-ccw" class="w-5 h-5"></i> FÁBRICA
    </button>
  </div>

  <div id="msg" class="hidden glass rounded-2xl p-3 text-center text-sm font-bold"></div>

  <div class="glass rounded-2xl p-3 flex justify-between text-[11px] font-mono text-slate-400">
    <span>IP: <span id="ip">---</span> · SSID: <span id="cur-ssid">--</span></span>
    <a href="/update" class="text-emerald-400 font-bold">OTA ↗</a>
  </div>
</main>

<footer class="text-center text-[11px] text-slate-500 font-mono mt-4">Scanner PRO v8.3 FIELD · RUNEFORGE V2</footer>

<script>
lucide.createIcons();

const intFields   = ['mqttPort','mqttFallbackPort','scanInterval','scanWindow','scanTime','rssiMin','apChannel'];
const floatFields = ['kQ','kR','kP','kX0'];
const textFields  = ['ssid','pass','ssid2','pass2','ssid3','pass3','mdns','mqttServer','mqttFallbackServer','mqttTopic','mqttClient','macPrefixes','nameFilters','apSSID','apPass'];
const boolFields  = ['mqttEnabled','mqttFallbackEnabled','activeScan','filterEnabled','debugLogAll','apAlwaysOn'];

async function load(){
  try {
    const r = await fetch('/api/settings');
    const d = await r.json();
    intFields.forEach(f => { const el=document.getElementById(f); if(el) el.value = d[f] ?? 0; });
    floatFields.forEach(f => { const el=document.getElementById(f); if(el) el.value = d[f] ?? 0; });
    textFields.forEach(f => { const el=document.getElementById(f); if(el) el.value = d[f] ?? ''; });
    boolFields.forEach(f => { const el=document.getElementById(f); if(el) el.checked = !!d[f]; });
    document.getElementById('ip').innerText = d.ip || '---';
    const st = await (await fetch('/api/status')).json();
    document.getElementById('cur-ssid').innerText = st.wifi_ssid || st.ap_ssid || '--';
  } catch(e){ toast('Error cargando', 'red'); }
}

async function save(){
  const body = {};
  intFields.forEach(f => { const el=document.getElementById(f); if(el) body[f] = parseInt(el.value, 10) || 0; });
  floatFields.forEach(f => { const el=document.getElementById(f); if(el) body[f] = parseFloat(el.value) || 0; });
  textFields.forEach(f => { const el=document.getElementById(f); if(el) body[f] = el.value; });
  boolFields.forEach(f => { const el=document.getElementById(f); if(el) body[f] = el.checked; });
  try {
    const r = await fetch('/api/settings', {
      method: 'POST',
      headers: {'Content-Type':'application/json'},
      body: JSON.stringify(body)
    });
    const d = await r.json();
    toast(d.ok ? '✔ Guardado' : '✖ ' + (d.msg || 'Error'), d.ok ? 'ok' : 'red');
    if (d.reboot) { toast('WiFi/AP cambiado. Reiniciando...', 'ok'); setTimeout(()=>location.href='/', 5000); }
  } catch(e){ toast('Error guardando', 'red'); }
}

async function reset(){
  if (!confirm('¿Resetear todo a fábrica?')) return;
  await fetch('/api/settings/reset', {method:'POST'});
  toast('Reset aplicado. Reiniciando...', 'ok');
  setTimeout(()=>location.href='/', 4000);
}

async function scanWiFi(){
  const box = document.getElementById('scan-result');
  box.classList.remove('hidden');
  box.innerHTML = '<div class="text-center text-xs text-cyan-400 py-2">📡 Escaneando...</div>';
  try {
    const r = await fetch('/api/wifi_scan', {signal: AbortSignal.timeout(15000)});
    const d = await r.json();
    if (!d.networks || d.networks.length === 0) {
      box.innerHTML = '<div class="text-center text-xs text-slate-500 py-2">No se encontraron redes</div>';
      return;
    }
    d.networks.sort((a,b) => b.rssi - a.rssi);
    box.innerHTML = `
      <div class="text-[10px] font-bold text-cyan-300 mb-2">${d.count} redes encontradas · toca para copiar SSID</div>
      ${d.networks.map(n => `
        <div class="wifi-item flex items-center justify-between px-2 py-1.5 rounded cursor-pointer" onclick="copySSID('${n.ssid.replace(/'/g, "\\'")}')">
          <div class="flex items-center gap-2 truncate">
            <i data-lucide="${n.encrypted ? 'lock' : 'unlock'}" class="w-3 h-3 ${n.encrypted ? 'text-amber-400' : 'text-emerald-400'}"></i>
            <span class="text-xs truncate">${n.ssid || '(oculto)'}</span>
          </div>
          <div class="text-[10px] font-mono ${n.rssi > -60 ? 'text-emerald-400' : n.rssi > -75 ? 'text-amber-400' : 'text-slate-500'}">${n.rssi} dBm · ch${n.channel}</div>
        </div>
      `).join('')}
    `;
    lucide.createIcons();
  } catch(e) {
    box.innerHTML = '<div class="text-center text-xs text-red-400 py-2">Error: ' + e.message + '</div>';
  }
}

function copySSID(ssid){
  navigator.clipboard.writeText(ssid).then(()=>{
    toast('SSID copiado: ' + ssid, 'ok');
  });
}

async function wifiReconnect(){
  toast('Reconectando WiFi STA...', 'ok');
  try {
    const r = await fetch('/api/wifi_reconnect', {method:'POST'});
    const d = await r.json();
    toast(d.ok ? '✔ Conectado a ' + d.ssid : '✖ No se pudo conectar, queda AP', d.ok ? 'ok' : 'red');
  } catch(e){ toast('Error', 'red'); }
}

async function mqttSwitch(){
  try {
    const r = await fetch('/api/mqtt_switch', {method:'POST'});
    const d = await r.json();
    toast(d.using_fallback ? 'Cambiado a FALLBACK' : 'Cambiado a PRIMARY', 'ok');
  } catch(e){ toast('Error', 'red'); }
}

function toast(txt, kind){
  const m = document.getElementById('msg');
  m.classList.remove('hidden');
  m.className = 'glass rounded-2xl p-3 text-center text-sm font-bold ' +
    (kind==='ok' ? 'text-emerald-400 border border-emerald-500/40'
                 : 'text-red-400 border border-red-500/40');
  m.innerText = txt;
  setTimeout(()=>m.classList.add('hidden'), 3500);
}

load();
</script>
</body>
</html>
)HTML";
