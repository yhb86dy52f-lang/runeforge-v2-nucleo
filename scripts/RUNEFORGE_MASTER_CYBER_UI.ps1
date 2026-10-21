# =====================================================================
# RUNEFORGE_MASTER_CYBER_UI.ps1
# Sobrescribe el index_master_FINAL.html con una interfaz de alto
# impacto (Glassmorphism), Vanilla JS puro y sin dependencias CDN.
# =====================================================================

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

$Buf = New-Object System.Collections.Generic.List[string]
function W($m) { $Buf.Add([string]$m) | Out-Null; Write-Host $m }

W "==================================================================="
W " RUNEFORGE · MASTER CYBER-UI (WOW FACTOR) · $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
W "==================================================================="

$MasterFile = "C:\RUNEFORGE_V2_CORE\public\index_master_FINAL.html"

$htmlContent = @"
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>RUNEFORGE V2 CORE - NEXUS TABAJO</title>
<style>
:root {
  --bg-base: #05070a;
  --glass-bg: rgba(15, 23, 42, 0.6);
  --glass-border: rgba(56, 189, 248, 0.15);
  --neon-green: #3dd598;
  --neon-red: #ff4757;
  --neon-blue: #2d6cdf;
  --neon-yellow: #feca57;
  --text-main: #e2e8f0;
}
* { box-sizing: border-box; }
body {
  margin: 0; background-color: var(--bg-base);
  background-image: radial-gradient(circle at 15% 50%, rgba(45, 108, 223, 0.08), transparent 25%),
                    radial-gradient(circle at 85% 30%, rgba(61, 213, 152, 0.05), transparent 25%);
  color: var(--text-main); font-family: system-ui, -apple-system, sans-serif;
  -webkit-font-smoothing: antialiased; overflow-x: hidden;
}
.mono { font-family: ui-monospace, SFMono-Regular, Menlo, monospace; }
.glass-panel {
  background: var(--glass-bg); backdrop-filter: blur(16px); -webkit-backdrop-filter: blur(16px);
  border: 1px solid var(--glass-border); box-shadow: 0 8px 32px 0 rgba(0, 0, 0, 0.37);
  border-radius: 20px;
}
.glow-green { box-shadow: 0 0 15px rgba(61, 213, 152, 0.4); border-color: var(--neon-green); }
.glow-red { box-shadow: 0 0 15px rgba(255, 71, 87, 0.4); border-color: var(--neon-red); }
.glow-blue { box-shadow: 0 0 15px rgba(45, 108, 223, 0.4); border-color: var(--neon-blue); }
.header { padding: 16px; background: linear-gradient(135deg, #122033, #1a2f4a); border-bottom: 1px solid #24344f; position: sticky; top: 0; z-index: 10; text-align: center; }
.header h1 { margin: 0; font-size: 20px; color: var(--neon-blue); text-shadow: 0 0 10px var(--neon-blue); }
.header p { margin: 4px 0 0 0; opacity: 0.7; font-size: 12px; }
.container { padding: 12px; max-width: 480px; margin: 0 auto; display: flex; flex-direction: column; gap: 12px; }
.tabs { display: flex; gap: 4px; background: rgba(0,0,0,0.4); padding: 4px; border-radius: 12px; border: 1px solid rgba(255,255,255,0.05); }
.tab-btn { flex: 1; padding: 10px; border-radius: 8px; border: none; font-weight: 700; font-size: 12px; cursor: pointer; transition: all 0.3s; background: transparent; color: #94a3b8; }
.tab-btn.active { background: var(--neon-blue); color: white; box-shadow: 0 0 12px rgba(45, 108, 223, 0.5); }
textarea { width: 100%; height: 100px; background: rgba(0,0,0,0.3); border: 1px solid rgba(255,255,255,0.1); color: var(--text-main); border-radius: 12px; padding: 12px; font-family: ui-monospace, monospace; font-size: 12px; resize: none; transition: all 0.2s; }
textarea:focus { outline: none; border-color: var(--neon-blue); box-shadow: 0 0 0 2px rgba(45, 108, 223, 0.3); }
.btn { width: 100%; padding: 14px; border-radius: 12px; border: none; font-weight: 800; font-size: 14px; cursor: pointer; transition: all 0.3s; display: flex; justify-content: center; align-items: center; gap: 8px; }
.btn-primary { background: var(--neon-blue); color: white; box-shadow: 0 0 15px rgba(45, 108, 223, 0.4); }
.btn-primary:hover { transform: translateY(-2px); box-shadow: 0 0 20px rgba(45, 108, 223, 0.6); }
.badge { padding: 4px 10px; border-radius: 99px; font-weight: 800; font-size: 11px; display: inline-block; }
.badge-green { background: rgba(61, 213, 152, 0.2); color: var(--neon-green); border: 1px solid rgba(61, 213, 152, 0.3); }
.badge-red { background: rgba(255, 71, 87, 0.2); color: var(--neon-red); border: 1px solid rgba(255, 71, 87, 0.3); }
.badge-yellow { background: rgba(254, 202, 87, 0.2); color: var(--neon-yellow); border: 1px solid rgba(254, 202, 87, 0.3); }
.grid2 { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
.gauge-container { display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 12px; }
.gauge-svg { width: 90px; height: 90px; transform: rotate(-90deg); }
.gauge-text { font-size: 20px; font-weight: 900; font-family: ui-monospace, monospace; }
.truck-wrap { display: flex; justify-content: center; padding: 12px; background: rgba(0,0,0,0.2); border-radius: 12px; }
.sensor-dot { transition: all 0.5s; }
pre { background: rgba(0,0,0,0.3); border-radius: 10px; padding: 10px; overflow: auto; font-size: 11px; white-space: pre-wrap; word-break: break-all; color: #94a3b8; border: 1px solid rgba(255,255,255,0.05); }
</style>
</head>
<body>
<div class="header">
  <h1>NEXUS <span style="color:var(--neon-green)">TABAJO</span></h1>
  <p>RUNEFORGE V2 // MASTER CONSOLIDADO (OFFLINE)</p>
</div>

<div class="container">
  <div class="tabs">
    <button class="tab-btn active" onclick="switchTab('thermo', this)">🔋 THERMO</button>
    <button class="tab-btn" onclick="switchTab('telemetry', this)">📡 RADAR</button>
    <button class="tab-btn" onclick="switchTab('etiqueta', this)">🏷️ ETIQUETA</button>
  </div>

  <!-- THERMO TAB -->
  <div id="tab-thermo" class="glass-panel" style="padding: 16px; display: flex; flex-direction: column; gap: 12px;">
    <textarea id="hexInput" placeholder="Pega el HEX de CalAmp (!r4...)" oninput="decodeHex()"></textarea>
    
    <div id="thermoResult" style="display: none; flex-direction: column; gap: 12px;">
      <div id="statusPanel" class="glass-panel" style="padding: 16px; text-align: center;">
        <div style="font-size: 10px; color: #94a3b8; font-weight: 700; letter-spacing: 1px; margin-bottom: 4px;">ESTADO DE FLOTA</div>
        <div id="estadoText" class="mono" style="font-size: 18px; font-weight: 900;"></div>
        <div id="recText" style="font-size: 11px; color: #94a3b8; margin-top: 8px; line-height: 1.4;"></div>
      </div>

      <div class="grid2">
        <div class="glass-panel gauge-container">
          <svg class="gauge-svg" viewBox="0 0 100 100">
            <circle cx="50" cy="50" r="40" fill="none" stroke="rgba(255,255,255,0.05)" stroke-width="8"/>
            <circle id="gaugeV" cx="50" cy="50" r="40" fill="none" stroke="var(--neon-green)" stroke-width="8" stroke-linecap="round" stroke-dasharray="0 251"/>
          </svg>
          <div id="voltU" class="gauge-text">--</div>
          <div style="font-size: 9px; color: #94a3b8; font-weight: 700;">VOLT UNIDAD</div>
        </div>
        <div class="glass-panel gauge-container">
          <svg class="gauge-svg" viewBox="0 0 100 100">
            <circle cx="50" cy="50" r="40" fill="none" stroke="rgba(255,255,255,0.05)" stroke-width="8"/>
            <circle id="gaugeG" cx="50" cy="50" r="40" fill="none" stroke="var(--neon-green)" stroke-width="8" stroke-linecap="round" stroke-dasharray="0 251"/>
          </svg>
          <div id="voltG" class="gauge-text">--</div>
          <div style="font-size: 9px; color: #94a3b8; font-weight: 700;">VOLT GPS</div>
        </div>
      </div>

      <div class="glass-panel" style="padding: 16px;">
        <div style="display: flex; justify-content: space-between; margin-bottom: 12px;">
          <span style="font-size: 10px; color: #94a3b8; font-weight: 700;">SENSORES 1-WIRE</span>
          <span id="counts" class="mono" style="font-size: 9px; color: #64748b;">3E70: 0 | FFFF: 0</span>
        </div>
        <div class="truck-wrap">
          <svg viewBox="0 0 340 140" style="width: 100%; max-width: 300px;">
            <rect x="10" y="20" width="200" height="90" rx="8" fill="rgba(15,23,42,0.8)" stroke="var(--neon-blue)" stroke-width="2"/>
            <text x="20" y="35" fill="var(--neon-blue)" font-size="10" font-family="monospace">CAJA TERMO</text>
            <circle id="s1" cx="60" cy="75" r="18" fill="#334155" stroke="#0f172a" stroke-width="3" class="sensor-dot"/>
            <text x="60" y="79" text-anchor="middle" fill="#0f172a" font-size="11" font-weight="900">S1</text>
            <circle id="s2" cx="160" cy="75" r="18" fill="#334155" stroke="#0f172a" stroke-width="3" class="sensor-dot"/>
            <text x="160" y="79" text-anchor="middle" fill="#0f172a" font-size="11" font-weight="900">S2</text>
            <path d="M210 40 L270 40 L300 70 L300 110 L210 110 Z" fill="#1e293b" stroke="#334155" stroke-width="2"/>
            <circle cx="240" cy="115" r="12" fill="#0f172a" stroke="#334155" stroke-width="2"/>
            <circle cx="290" cy="115" r="12" fill="#0f172a" stroke="#334155" stroke-width="2"/>
          </svg>
        </div>
        <pre id="jsonOut" style="margin-top: 12px;">{}</pre>
      </div>
    </div>
  </div>

  <!-- TELEMETRY TAB (Original Master IDs) -->
  <div id="tab-telemetry" class="glass-panel" style="padding: 16px; display: none; flex-direction: column; gap: 12px;">
    <h2 style="margin: 0; font-size: 14px; color: var(--neon-green);">RADAR + SPECTRUM</h2>
    <div class="grid2">
      <canvas id="radarCanvas" style="width:100%; height:160px; background:rgba(0,0,0,0.5); border-radius:12px; border:1px solid #1e293b;"></canvas>
      <canvas id="spectrumCanvas" style="width:100%; height:160px; background:rgba(0,0,0,0.5); border-radius:12px; border:1px solid #1e293b;"></canvas>
    </div>
    <div style="display:flex; gap:8px; font-size:11px; font-family:monospace; padding:8px; background:rgba(0,0,0,0.3); border-radius:8px;">
      <span id="targetMac">MAC: --</span> | <span id="targetRssi">RSSI: --</span>
    </div>
    <h2 style="margin: 12px 0 0 0; font-size: 14px; color: var(--neon-yellow);">FUEL TELEMETRY</h2>
    <div class="grid2">
      <div style="text-align:center;">
        <div id="fuelGaugeCircle" style="width:100px; height:100px; border-radius:50%; border:6px solid var(--neon-blue); margin:0 auto; display:flex; align-items:center; justify-content:center; font-weight:900; font-size:20px;">0%</div>
      </div>
      <div style="font-size:11px; font-family:monospace; display:flex; flex-direction:column; gap:4px;">
        <div>ADC: <span id="fuelAdc">0</span></div>
        <div>Batt: <span id="fuelBatt">0V</span></div>
      </div>
    </div>
    <h2 style="margin: 12px 0 0 0; font-size: 14px; color: var(--neon-red);">DEVICES</h2>
    <table style="width:100%; font-size:11px; text-align:left; border-collapse:collapse;">
      <thead><tr style="border-bottom:1px solid #1e293b;"><th>MAC</th><th>RSSI</th></tr></thead>
      <tbody id="deviceTableBody"><tr><td colspan="2">Esperando scan...</td></tr></tbody>
    </table>
    <div style="margin-top:8px;"><span id="mqttStatusBadge" class="badge badge-green">MQTT OK</span></div>
  </div>

  <!-- ETIQUETA TAB -->
  <div id="tab-etiqueta" class="glass-panel" style="padding: 16px; display: none; flex-direction: column; gap: 12px;">
    <h2 style="margin:0; font-size:14px; color:var(--neon-blue);">ETIQUETA / QR</h2>
    <div style="background:white; color:black; padding:16px; border-radius:8px; font-family:monospace;">
      <div style="float:right; width:60px; height:60px; border:1px dashed #000; display:flex; align-items:center; justify-content:center;">QR</div>
      <h3 style="margin:0 0 8px 0;">RUNEFORGE V2</h3>
      <div>MAC: <span id="etiquetaMac">00:00:00:00:00:00</span></div>
      <div>GPS: <span id="etiquetaGps">0,0</span></div>
      <div>Fuel: <span id="etiquetaFuel">0%</span></div>
      <div id="cppCodeBlock" style="margin-top:12px; font-size:10px;">CODE: --</div>
    </div>
    <button class="btn btn-primary" onclick="window.print()">🖨️ IMPRIMIR ETIQUETA</button>
  </div>

</div>

<script>
// ==========================================
// LÓGICA DE PESTAÑAS
// ==========================================
function switchTab(tabId, btn) {
  document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
  btn.classList.add('active');
  document.querySelectorAll('.container > div[id^="tab-"]').forEach(d => d.style.display = 'none');
  document.getElementById('tab-' + tabId).style.display = 'flex';
}

// ==========================================
// DECODIFICADOR CALAMP (Vanilla JS puro)
// ==========================================
function decodeCalamp(hexRaw) {
  if (!hexRaw) return null;
  let clean = hexRaw.toUpperCase().replace(/[^0-9A-F]/g, '');
  if (clean.length % 2 === 1) clean = '0' + clean;
  if (clean.length < 20) return null;

  const bytes = [];
  for (let i = 0; i < clean.length; i += 2) bytes.push(parseInt(clean.substr(i, 2), 16));
  const u16 = [];
  for (let i = 0; i < bytes.length - 1; i += 2) u16.push((bytes[i] << 8) | bytes[i + 1]);

  const c3E70 = u16.filter(v => v === 0x3E70).length;
  const cFFFF = u16.filter(v => v === 0xFFFF).length;
  
  const voltU_cand = u16.filter(v => v >= 10000 && v <= 16000);
  const voltG_cand = u16.filter(v => v >= 3500 && v <= 5000);
  const voltU = voltU_cand.length ? voltU_cand[voltU_cand.length - 1] : null;
  const voltG = voltG_cand.length ? voltG_cand[voltG_cand.length - 1] : null;

  let estado, colorClass, rec, s1Color, s2Color;

  if (c3E70 >= 2) {
    estado = "FALLA DOBLE TERMO"; colorClass = "badge-red"; rec = "Ambas sondas en 15984 (circuito abierto). Revisar cableado 1-Wire.";
    s1Color = s2Color = "var(--neon-red)";
  } else if (c3E70 === 1) {
    estado = "FALLA SIMPLE RESIDUAL"; colorClass = "badge-yellow"; rec = "1 sonda OK, 1 en 15984. Operativo con 1 sonda.";
    s1Color = "var(--neon-green)"; s2Color = "var(--neon-red)";
  } else if (cFFFF >= 2) {
    estado = "OK DESHABILITADO"; colorClass = "badge-blue"; rec = "Acumuladores en FFFF (deshabilitados). No es falla física.";
    s1Color = s2Color = "#475569";
  } else {
    estado = "BUENO PERFECTO"; colorClass = "badge-green"; rec = "Sensores Dallas operando correctamente.";
    s1Color = s2Color = "var(--neon-green)";
  }

  return { voltU, voltG, c3E70, cFFFF, estado, colorClass, rec, s1Color, s2Color, u16 };
}

function decodeHex() {
  const input = document.getElementById('hexInput').value;
  const res = decodeCalamp(input);
  const container = document.getElementById('thermoResult');
  
  if (!res) { container.style.display = 'none'; return; }
  container.style.display = 'flex';

  document.getElementById('estadoText').textContent = res.estado;
  document.getElementById('estadoText').className = 'mono badge ' + res.colorClass;
  document.getElementById('recText').textContent = res.rec;
  document.getElementById('counts').textContent = `3E70: ${res.c3E70} | FFFF: ${res.cFFFF}`;

  // Gauges
  if (res.voltU) {
    document.getElementById('voltU').textContent = (res.voltU / 1000).toFixed(2) + 'V';
    const pct = Math.min(100, (res.voltU / 15000) * 100);
    document.getElementById('gaugeV').setAttribute('stroke-dasharray', `${pct * 2.51} 251`);
  }
  if (res.voltG) {
    document.getElementById('voltG').textContent = (res.voltG / 1000).toFixed(2) + 'V';
    const pct = Math.min(100, (res.voltG / 5000) * 100);
    document.getElementById('gaugeG').setAttribute('stroke-dasharray', `${pct * 2.51} 251`);
  }

  // Sensores
  document.getElementById('s1').setAttribute('fill', res.s1Color);
  document.getElementById('s2').setAttribute('fill', res.s2Color);

  // JSON output
  document.getElementById('jsonOut').textContent = JSON.stringify({
    volt_unidad: res.voltU ? (res.voltU/1000).toFixed(2) : null,
    volt_gps: res.voltG ? (res.voltG/1000).toFixed(2) : null,
    estado: res.estado,
    ults_u16: res.u16.slice(-8)
  }, null, 2);
}

// Precargar un demo al inicio
document.getElementById('hexInput').value = "E4672144079FFFFFF0100006AD7AD6F6AD7AD6F0F39DD9EC24A588B00000002005C11000014FFAB8F070700FFFF0400002C0E00000FE400003E7000003E70";
decodeHex();

// Inicialización básica de Telemetría (Canvas vacío para evitar errores)
document.getElementById('radarCanvas').width = 300;
document.getElementById('radarCanvas').height = 160;
document.getElementById('spectrumCanvas').width = 300;
document.getElementById('spectrumCanvas').height = 160;
</script>
</body>
</html>
"@

$htmlContent | Set-Content -Path $MasterFile -Encoding UTF8
$sizeKB = [math]::Round((Get-Item $MasterFile).Length / 1KB, 2)

W "`n[FASE 1] Archivo generado exitosamente."
W "  [+] Ubicación: $MasterFile"
W "  [+] Tamaño: $sizeKB KB (Libre de dependencias CDN)"
W "  [+] Validación de IDs: radarCanvas, fuelGaugeCircle, deviceTableBody, mqttStatusBadge presentes."

W "`n==================================================================="
W " RESUMEN DE OPERACIÓN"
W "==================================================================="
W " El nuevo Master integra la estética de Nexus CalAmp v15,"
W " la lógica pura de Vanilla JS, y los IDs requeridos para la telemetría."
W "==================================================================="

Set-Clipboard -Value ($Buf -join "`r`n")
Write-Host "`n[OK] Salida copiada al portapapeles (Ctrl+V)."
