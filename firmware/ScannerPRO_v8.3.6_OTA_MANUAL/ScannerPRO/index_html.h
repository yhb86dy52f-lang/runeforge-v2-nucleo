#pragma once
#include <Arduino.h>

const char index_html[] PROGMEM = R"HTML(
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
<title>Scanner PRO · Live v8.3</title>
<script src="https://cdn.tailwindcss.com"></script>
<script src="https://unpkg.com/lucide@latest"></script>
<style>
:root { color-scheme: dark; }
body { background: radial-gradient(circle at 20% 0%, #0f1b3d 0%, #070a14 55%, #03050a 100%); }
.glass { background: rgba(15,23,42,.65); backdrop-filter: blur(18px); border: 1px solid rgba(255,255,255,.07); }
.glass-strong { background: rgba(15,23,42,.85); backdrop-filter: blur(20px); border: 1px solid rgba(255,255,255,.1); }
.btn { transition: transform .12s ease, background .2s ease; }
.btn:active { transform: scale(.97); }
.fam-ciclope { border-left-color: #facc15; }
.fam-lmu     { border-left-color: #38bdf8; }
.fam-samsara { border-left-color: #fb923c; }
.fam-kw      { border-left-color: #10b981; }
.fam-apple   { border-left-color: #a78bfa; }
.fam-other   { border-left-color: #64748b; }
.tag { font-size: 10px; padding: 2px 6px; border-radius: 4px; font-weight: 800; text-transform: uppercase; }
.tag-ciclope { background: rgba(250,204,21,.15); color: #facc15; }
.tag-lmu     { background: rgba(56,189,248,.15); color: #38bdf8; }
.tag-samsara { background: rgba(251,146,60,.15); color: #fb923c; }
.tag-kw      { background: rgba(16,185,129,.15); color: #10b981; }
.tag-apple   { background: rgba(167,139,250,.15); color: #a78bfa; }
.tag-other   { background: rgba(100,116,139,.15); color: #94a3b8; }
</style>
</head>
<body class="text-slate-100 min-h-screen flex flex-col p-3 md:p-6 font-sans">

<header class="glass rounded-3xl p-4 flex justify-between items-center shadow-2xl mb-4 max-w-3xl mx-auto w-full">
  <div class="flex items-center gap-3">
    <div class="p-3 bg-gradient-to-tr from-cyan-500 to-violet-600 rounded-2xl shadow-lg shadow-cyan-500/20">
      <i data-lucide="radar" class="w-6 h-6 text-white"></i>
    </div>
    <div>
      <div class="flex items-center gap-2">
        <h1 class="text-xl font-black tracking-tight">Scanner PRO</h1>
        <span class="text-[10px] font-bold px-2 py-0.5 bg-cyan-500/20 text-cyan-300 border border-cyan-500/30 rounded-full">v8.3 FIELD</span>
      </div>
      <p class="text-[11px] text-slate-400 font-mono">
        RSSI <span id="rssi">--</span> · up <span id="uptime">--</span>s · heap <span id="heap">--</span>B
      </p>
    </div>
  </div>
  <div class="flex flex-col gap-1">
    <div class="flex items-center gap-2 bg-slate-900/80 px-3 py-1.5 rounded-2xl border border-slate-800">
      <span id="conn-dot" class="w-2.5 h-2.5 rounded-full bg-red-500 animate-pulse"></span>
      <span id="conn-text" class="text-xs font-bold">Offline</span>
    </div>
    <div class="flex items-center gap-2 bg-slate-900/60 px-3 py-1 rounded-xl border border-slate-800">
      <span id="ap-dot" class="w-2 h-2 rounded-full bg-slate-600"></span>
      <span id="ap-text" class="text-[10px] font-mono text-slate-400">AP --</span>
    </div>
  </div>
</header>

<main class="flex-1 space-y-4 max-w-3xl mx-auto w-full">

  <div class="grid grid-cols-2 md:grid-cols-4 gap-3">
    <div class="glass rounded-2xl p-4">
      <div class="flex items-center gap-2 text-[11px] text-slate-400 font-bold uppercase mb-1">
        <i data-lucide="antenna" class="w-3 h-3"></i> Escaneados
      </div>
      <div id="stat-scanned" class="text-2xl font-black text-cyan-300">0</div>
    </div>
    <div class="glass rounded-2xl p-4">
      <div class="flex items-center gap-2 text-[11px] text-slate-400 font-bold uppercase mb-1">
        <i data-lucide="filter" class="w-3 h-3"></i> Filtrados
      </div>
      <div id="stat-filtered" class="text-2xl font-black text-emerald-300">0</div>
    </div>
    <div class="glass rounded-2xl p-4">
      <div class="flex items-center gap-2 text-[11px] text-slate-400 font-bold uppercase mb-1">
        <i data-lucide="send" class="w-3 h-3"></i> Publicados
      </div>
      <div id="stat-published" class="text-2xl font-black text-orange-300">0</div>
    </div>
    <div class="glass rounded-2xl p-4">
      <div class="flex items-center gap-2 text-[11px] text-slate-400 font-bold uppercase mb-1">
        <i data-lucide="layers" class="w-3 h-3"></i> Únicos
      </div>
      <div id="stat-unique" class="text-2xl font-black text-violet-300">0</div>
    </div>
  </div>

  <div class="glass rounded-3xl p-4 flex flex-wrap gap-3 items-center justify-between">
    <div class="flex items-center gap-3 flex-wrap">
      <div class="flex items-center gap-2">
        <span class="w-2 h-2 rounded-full" id="mqtt-dot"></span>
        <span class="text-xs font-bold" id="mqtt-text">MQTT: --</span>
      </div>
      <div class="text-[11px] text-slate-500 font-mono" id="mqtt-server">--</div>
      <div class="text-[10px] text-amber-300 font-mono" id="wifi-active">WiFi: --</div>
    </div>
    <div class="flex gap-2 flex-wrap">
      <button onclick="clearDevices()" class="btn bg-slate-800 hover:bg-slate-700 px-3 py-1.5 rounded-lg text-xs font-bold flex items-center gap-1">
        <i data-lucide="trash-2" class="w-3 h-3"></i> Limpiar
      </button>
      <button onclick="publishTest()" class="btn bg-slate-800 hover:bg-slate-700 px-3 py-1.5 rounded-lg text-xs font-bold flex items-center gap-1">
        <i data-lucide="beaker" class="w-3 h-3"></i> Test MQTT
      </button>
      <a href="/api/dispositivos" target="_blank" class="btn bg-violet-600 hover:bg-violet-500 px-3 py-1.5 rounded-lg text-xs font-bold flex items-center gap-1">
        <i data-lucide="code-2" class="w-3 h-3"></i> /dispositivos
      </a>
      <a href="/settings" class="btn bg-cyan-600 hover:bg-cyan-500 px-3 py-1.5 rounded-lg text-xs font-bold flex items-center gap-1">
        <i data-lucide="settings" class="w-3 h-3"></i> Config
      </a>
      <a href="/update" class="btn bg-emerald-600 hover:bg-emerald-500 px-3 py-1.5 rounded-lg text-xs font-bold flex items-center gap-1">
        <i data-lucide="upload-cloud" class="w-3 h-3"></i> OTA
      </a>
    </div>
  </div>

  <div class="glass rounded-3xl p-4">
    <div class="flex items-center justify-between mb-3">
      <div class="flex items-center gap-2">
        <i data-lucide="list" class="w-5 h-5 text-cyan-400"></i>
        <h2 class="font-bold uppercase text-sm tracking-wide">Dispositivos en vivo</h2>
      </div>
      <span class="text-[11px] font-mono text-slate-500" id="filter-state">--</span>
    </div>
    <div id="devices" class="space-y-2">
      <div class="text-center text-slate-500 text-xs p-6 border-2 border-dashed border-slate-800 rounded-2xl">
        <i data-lucide="radar" class="w-8 h-8 mx-auto mb-2 opacity-30"></i>
        Esperando dispositivos...
      </div>
    </div>
  </div>

  <div class="glass rounded-2xl p-3 text-[11px] font-mono text-slate-400 space-y-1">
    <div>STA IP: <span id="ip">--</span> · Modo: <span id="mode">--</span> · SSID: <span id="ssid-activo">--</span></div>
    <div>AP IP: <span id="ap-ip">192.168.4.1</span> · AP SSID: <span id="ap-ssid">--</span> · mDNS: <a href="http://scanner-pro.local" class="text-cyan-400">scanner-pro.local</a></div>
  </div>
</main>

<footer class="text-center text-[11px] text-slate-500 font-mono mt-4">Scanner PRO v8.3 FIELD · RUNEFORGE V2 · Dual AP+STA</footer>

<script>
lucide.createIcons();

async function poll() {
  try {
    const r = await fetch('/api/status', {signal: AbortSignal.timeout(2000)});
    const d = await r.json();
    document.getElementById('conn-dot').className = "w-2.5 h-2.5 rounded-full bg-emerald-500";
    document.getElementById('conn-text').innerText = d.mode.includes("STA") ? "Online STA" : "AP Only";
    document.getElementById('rssi').innerText   = d.rssi;
    document.getElementById('uptime').innerText = d.uptime;
    document.getElementById('heap').innerText   = d.heap;
    document.getElementById('ip').innerText     = d.ip;
    document.getElementById('mode').innerText   = d.mode;
    document.getElementById('ssid-activo').innerText = d.wifi_ssid || "(ninguno)";

    document.getElementById('stat-scanned').innerText   = d.scanned_total;
    document.getElementById('stat-filtered').innerText  = d.filtered_total;
    document.getElementById('stat-published').innerText = d.published_total;
    document.getElementById('stat-unique').innerText    = d.unique_devices;

    // AP status
    const apDot = document.getElementById('ap-dot');
    const apTxt = document.getElementById('ap-text');
    const apIp = document.getElementById('ap-ip');
    const apSsid = document.getElementById('ap-ssid');
    if(d.ap_enabled){
      apDot.className = "w-2 h-2 rounded-full bg-cyan-400";
      apTxt.innerText = "AP ON " + (d.ap_ssid||"");
      apTxt.className = "text-[10px] font-mono text-cyan-300";
      apIp.innerText = d.ap_ip || "192.168.4.1";
      apSsid.innerText = d.ap_ssid || "--";
    } else {
      apDot.className = "w-2 h-2 rounded-full bg-slate-600";
      apTxt.innerText = "AP OFF";
      apTxt.className = "text-[10px] font-mono text-slate-500";
    }

    document.getElementById('wifi-active').innerText = "WiFi: " + (d.wifi_ssid || "AP") + " (" + d.rssi + "dBm)";

    const mqttDot = document.getElementById('mqtt-dot');
    const mqttTxt = document.getElementById('mqtt-text');
    if (d.mqtt_connected) {
      mqttDot.className = "w-2 h-2 rounded-full bg-emerald-500";
      mqttTxt.innerText = "MQTT: Conectado (" + (d.mqtt_using_fallback?"fallback":"primary") + ")";
      mqttTxt.className = "text-xs font-bold text-emerald-300";
    } else if (d.mqtt_enabled) {
      mqttDot.className = "w-2 h-2 rounded-full bg-red-500 animate-pulse";
      mqttTxt.innerText = "MQTT: Desconectado";
      mqttTxt.className = "text-xs font-bold text-red-400";
    } else {
      mqttDot.className = "w-2 h-2 rounded-full bg-slate-600";
      mqttTxt.innerText = "MQTT: OFF";
      mqttTxt.className = "text-xs font-bold text-slate-400";
    }
    document.getElementById('mqtt-server').innerText = d.mqtt_server + ":" + (d.mqtt_port||1883);

    document.getElementById('filter-state').innerText =
      (d.filter_enabled ? "Filtro ON" : "Filtro OFF") + " · RSSI ≥ " + d.rssi_min + " dBm · ActiveScan " + (d.active_scan?"ON":"OFF");

    await loadDevices();
  } catch(e) {
    document.getElementById('conn-dot').className = "w-2.5 h-2.5 rounded-full bg-red-500 animate-pulse";
    document.getElementById('conn-text').innerText = "Offline";
  }
}

async function loadDevices() {
  try {
    const r = await fetch('/api/dispositivos');
    const list = await r.json();

    if (list.length === 0) {
      document.getElementById('devices').innerHTML = `
        <div class="text-center text-slate-500 text-xs p-6 border-2 border-dashed border-slate-800 rounded-2xl">
          <i data-lucide="radar" class="w-8 h-8 mx-auto mb-2 opacity-30"></i>
          No hay dispositivos filtrados activos
        </div>`;
      lucide.createIcons();
      return;
    }

    list.sort((a, b) => b.rssi_kalman - a.rssi_kalman);

    document.getElementById('devices').innerHTML = list.map(x => `
      <div class="fam-${x.family||'other'} glass-strong rounded-2xl p-3 border-l-4 flex justify-between items-center">
        <div class="min-w-0 flex-1">
          <div class="flex items-center gap-2 flex-wrap">
            <span class="tag tag-${x.family||'other'}">${x.family||'other'}</span>
            <span class="font-bold text-sm truncate">${x.name || x.mac}</span>
            <span class="text-[9px] px-1.5 py-0.5 rounded ${x.vivo ? 'bg-emerald-500/20 text-emerald-300' : 'bg-slate-700 text-slate-400'}">${x.vivo?'VIVO':'PERDIDO'}</span>
          </div>
          <div class="text-[10px] text-slate-400 font-mono mt-1 flex gap-2 flex-wrap">
            <span class="bg-slate-800/60 px-1.5 py-0.5 rounded">${x.mac}</span>
            <span>edad ${x.edad_seg.toFixed(1)}s</span>
            <span>×${x.count}</span>
            <span class="hidden md:inline">${x.ts_server}</span>
          </div>
        </div>
        <div class="text-right ml-2 shrink-0">
          <div class="text-sm font-black ${x.vivo ? 'text-emerald-300' : 'text-slate-500'}">
            ${Math.round(x.rssi_kalman)} dBm
          </div>
          <div class="text-[9px] text-slate-500 font-mono">raw ${x.rssi_raw}</div>
        </div>
      </div>
    `).join('');
    lucide.createIcons();
  } catch(e) {}
}

async function clearDevices() {
  if (!confirm('¿Limpiar todos los dispositivos detectados?')) return;
  await fetch('/api/devices/clear', {method:'POST'});
  poll();
}

async function publishTest() {
  try {
    const r = await fetch('/api/publish_test', {method:'POST'});
    const d = await r.json();
    alert(d.ok ? '✔ Mensaje de prueba enviado al broker' : '✖ Error al publicar: ' + (d.msg||''));
  } catch(e) { alert('✖ Error: ' + e.message); }
}

setInterval(poll, 2000);
poll();
</script>
</body>
</html>
)HTML";
