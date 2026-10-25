# =====================================================================
# RUNEFORGE_MASTER_TACTICAL.ps1
# Genera el Master definitivo con React + Tailwind (CDN), integrando
# Radar animado, Gauges, Tanques de combustible y Lógica Triple.
# =====================================================================

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

$Buf = New-Object System.Collections.Generic.List[string]
function W($m) { $Buf.Add([string]$m) | Out-Null; Write-Host $m }

W "==================================================================="
W " RUNEFORGE · MASTER TACTICAL (WOW FACTOR EXTREMO) · $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
W "==================================================================="

$MasterFile = "C:\RUNEFORGE_V2_CORE\public\index_master_FINAL.html"

$htmlContent = @"
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
<title>SEPCOLGPS NEXUS - TACTICAL DASHBOARD</title>
<script src="https://cdn.tailwindcss.com"></script>
<script src="https://unpkg.com/react@18/umd/react.production.min.js"></script>
<script src="https://unpkg.com/react-dom@18/umd/react-dom.production.min.js"></script>
<script src="https://unpkg.com/@babel/standalone/babel.min.js"></script>
<style>
  @import url('https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;700&family=Space+Grotesk:wght@500;700&display=swap');
  
  :root {
    --bg-base: #05070a;
    --neon-green: #3dd598;
    --neon-red: #ff4757;
    --neon-blue: #2d6cdf;
    --neon-yellow: #feca57;
    --neon-cyan: #5eead4;
  }

  body {
    margin: 0;
    background-color: var(--bg-base);
    background-image: 
      radial-gradient(circle at 15% 50%, rgba(45, 108, 223, 0.15), transparent 30%),
      radial-gradient(circle at 85% 30%, rgba(61, 213, 152, 0.1), transparent 30%),
      radial-gradient(circle at 50% 100%, rgba(255, 71, 87, 0.05), transparent 40%);
    color: #e2e8f0;
    font-family: 'JetBrains Mono', monospace;
    -webkit-font-smoothing: antialiased;
    overflow-x: hidden;
  }

  h1, h2, h3 { font-family: 'Space Grotesk', sans-serif; }

  .glass-panel {
    background: rgba(15, 23, 42, 0.6);
    backdrop-filter: blur(16px);
    -webkit-backdrop-filter: blur(16px);
    border: 1px solid rgba(56, 189, 248, 0.15);
    box-shadow: 0 8px 32px 0 rgba(0, 0, 0, 0.5);
    border-radius: 24px;
  }

  .glow-green { box-shadow: 0 0 20px rgba(61, 213, 152, 0.3); border-color: rgba(61, 213, 152, 0.4); }
  .glow-red { box-shadow: 0 0 20px rgba(255, 71, 87, 0.3); border-color: rgba(255, 71, 87, 0.4); }
  .glow-blue { box-shadow: 0 0 20px rgba(45, 108, 223, 0.3); border-color: rgba(45, 108, 223, 0.4); }

  .scanline {
    position: absolute;
    top: 0; left: 0; width: 100%; height: 100%;
    background: linear-gradient(to bottom, transparent 50%, rgba(0, 0, 0, 0.5) 51%);
    background-size: 100% 4px;
    z-index: 10;
    pointer-events: none;
    opacity: 0.3;
  }

  @keyframes radar-sweep {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
  }
  .radar-sweep-line {
    position: absolute;
    top: 50%; left: 50%;
    width: 50%; height: 2px;
    background: linear-gradient(90deg, var(--neon-green), transparent);
    transform-origin: left center;
    animation: radar-sweep 3s linear infinite;
  }

  ::-webkit-scrollbar { width: 6px; height: 6px; }
  ::-webkit-scrollbar-track { background: var(--bg-base); }
  ::-webkit-scrollbar-thumb { background: rgba(56, 189, 248, 0.3); border-radius: 10px; }
  ::-webkit-scrollbar-thumb:hover { background: var(--neon-green); }
</style>
</head>
<body>
<div id="root"></div>

<script type="text/babel" data-presets="react">
const { useState, useEffect, useRef, useMemo } = React;

// ==========================================
// LÓGICA DE DECODIFICACIÓN (TRI-PROTOCOLO)
// ==========================================
const decodeCT = (hex) => {
  let clean = hex.toUpperCase().replace(/[^0-9A-F]/g, '');
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

  let estado, badge, rec, s1Color, s2Color;

  if (c3E70 >= 2) {
    estado = "FALLA DOBLE TERMO"; badge = "bg-red-500/20 text-red-400 border-red-500/30"; rec = "Ambas sondas en 15984 (circuito abierto). Revisar cableado 1-Wire.";
    s1Color = s2Color = "#ff4757";
  } else if (c3E70 === 1) {
    estado = "FALLA SIMPLE RESIDUAL"; badge = "bg-yellow-500/20 text-yellow-400 border-yellow-500/30"; rec = "1 sonda OK, 1 en 15984. Operativo con 1 sonda.";
    s1Color = "#3dd598"; s2Color = "#ff4757";
  } else if (cFFFF >= 2) {
    estado = "OK DESHABILITADO"; badge = "bg-blue-500/20 text-blue-400 border-blue-500/30"; rec = "Acumuladores en FFFF (deshabilitados). No es falla física.";
    s1Color = s2Color = "#475569";
  } else {
    estado = "BUENO PERFECTO"; badge = "bg-emerald-500/20 text-emerald-400 border-emerald-500/30"; rec = "Sensores Dallas operando correctamente.";
    s1Color = s2Color = "#3dd598";
  }

  return { type:'CT', voltU, voltG, c3E70, cFFFF, estado, badge, rec, s1Color, s2Color };
};

const decodeKW = (text) => {
  const accum = {}, esc = {};
  let rssi = null, hdop = null;
  let m;
  if ((m = text.match(/rssi\s*=\s*(-?\d+)/i))) rssi = parseInt(m[1]);
  if ((m = text.match(/hdop\s*=\s*([0-9.]+)/i))) hdop = parseFloat(m[1]);
  
  const rAccum = /accum_(\d+)\s*=\s*(-?\d+)/gi;
  while ((m = rAccum.exec(text)) !== null) accum['accum_'+m[1]] = parseInt(m[2]);
  
  const rEsc = /esc_(temp|lev)_(\d+)\s*=\s*(-?\d+)/gi;
  while ((m = rEsc.exec(text)) !== null) esc['esc_'+m[1]+'_'+m[2]] = parseInt(m[3]);

  const lev1 = esc.esc_lev_0 || 0;
  const lev2 = esc.esc_lev_1 || 0;
  const pct1 = Math.min(100, Math.max(0, lev1/4095*100));
  const pct2 = Math.min(100, Math.max(0, lev2/4095*100));
  
  let odo = null;
  if (accum.accum_5 && accum.accum_5 >= 29000000 && accum.accum_5 <= 29200000) odo = accum.accum_5;

  let estado = "COMBUSTIBLE OK", badge = "bg-emerald-500/20 text-emerald-400 border-emerald-500/30";
  if (rssi < -85) { estado = "SEÑAL MALA"; badge = "bg-yellow-500/20 text-yellow-400 border-yellow-500/30"; }

  return { type:'KW', rssi, hdop, lev1, lev2, pct1, pct2, odo, estado, badge };
};

const decodeR0 = (text) => {
  let app = null, apn = null, mid = null, inp = null;
  let m;
  if ((m = text.match(/APP:(\d+)\s+([^\s]+)/i))) app = m[1] + ' ' + m[2];
  if ((m = text.match(/DA\.\s*([^\s]+)/i))) apn = m[1];
  if ((m = text.match(/MID:(\d+)/i))) mid = m[1];
  if ((m = text.match(/INP:([01]+)/i))) inp = m[1];

  return { type:'R0', app, apn, mid, inp, estado: "STATUS OK", badge: "bg-cyan-500/20 text-cyan-400 border-cyan-500/30" };
};

// ==========================================
// COMPONENTES UI
// ==========================================

const RadarCanvas = () => {
  const canvasRef = useRef(null);
  
  useEffect(() => {
    const canvas = canvasRef.current;
    const ctx = canvas.getContext('2d');
    let animationFrameId;
    let angle = 0;

    const draw = () => {
      const w = canvas.width;
      const h = canvas.height;
      const cx = w / 2;
      const cy = h / 2;
      const radius = Math.min(w, h) / 2 - 10;

      ctx.clearRect(0, 0, w, h);

      // Círculos concéntricos
      ctx.strokeStyle = 'rgba(61, 213, 152, 0.2)';
      ctx.lineWidth = 1;
      for (let i = 1; i <= 4; i++) {
        ctx.beginPath();
        ctx.arc(cx, cy, (radius / 4) * i, 0, Math.PI * 2);
        ctx.stroke();
      }

      // Cruz
      ctx.beginPath();
      ctx.moveTo(cx, cy - radius); ctx.lineTo(cx, cy + radius);
      ctx.moveTo(cx - radius, cy); ctx.lineTo(cx + radius, cy);
      ctx.stroke();

      // Barrido
      ctx.save();
      ctx.translate(cx, cy);
      ctx.rotate(angle);
      
      const gradient = ctx.createLinearGradient(0, 0, radius, 0);
      gradient.addColorStop(0, 'rgba(61, 213, 152, 0.8)');
      gradient.addColorStop(1, 'rgba(61, 213, 152, 0)');
      
      ctx.fillStyle = gradient;
      ctx.beginPath();
      ctx.moveTo(0, 0);
      ctx.arc(0, 0, radius, 0, Math.PI / 4);
      ctx.lineTo(0, 0);
      ctx.fill();
      ctx.restore();

      angle += 0.05;
      animationFrameId = requestAnimationFrame(draw);
    };

    draw();
    return () => cancelAnimationFrame(animationFrameId);
  }, []);

  return <canvas ref={canvasRef} width={300} height={300} className="w-full max-w-[280px] h-auto mx-auto opacity-80 mix-blend-screen" />;
};

const Gauge = ({ value, max, label, unit, color }) => {
  const pct = value ? Math.min(100, Math.max(0, (value / max) * 100)) : 0;
  const activeColor = value ? color : '#334155';
  
  return (
    <div className="flex flex-col items-center justify-center p-3 glass-panel rounded-2xl relative overflow-hidden">
      <div className="absolute inset-0 opacity-10" style={{background: `radial-gradient(circle at top, ${activeColor} 0%, transparent 70%)`}}></div>
      <div className="relative w-24 h-24">
        <svg width="100" height="100" viewBox="0 0 100 100" className="rotate-[-90deg]">
          <circle cx="50" cy="50" r="40" fill="none" stroke="rgba(255,255,255,0.05)" strokeWidth="8"/>
          <circle cx="50" cy="50" r="40" fill="none" stroke={activeColor} strokeWidth="8" 
                  strokeLinecap="round" strokeDasharray={`${pct/100*251} 251`} 
                  style={{transition: 'stroke-dasharray 0.8s ease', filter: `drop-shadow(0 0 6px ${activeColor})`}}/>
        </svg>
        <div className="absolute inset-0 flex flex-col items-center justify-center">
          <span className="text-xl font-bold font-mono" style={{color: activeColor}}>
            {value !== null ? value.toFixed(2) : "--"}
          </span>
          <span className="text-[9px] text-gray-400 font-bold uppercase">{unit}</span>
        </div>
      </div>
      <div className="mt-2 text-[10px] text-gray-300 font-bold tracking-widest uppercase">{label}</div>
    </div>
  );
};

const App = () => {
  const [input, setInput] = useState("E4672144079FFFFFF0100006AD7AD6F6AD7AD6F0F39DD9EC24A588B00000002005C11000014FFAB8F070700FFFF0400002C0E00000FE400003E7000003E70");
  const [data, setData] = useState(null);
  const [logs, setLogs] = useState([]);

  useEffect(() => {
    let d = null;
    if (input.includes('accum_') || input.includes('esc_')) d = decodeKW(input);
    else if (input.includes('APP:') || input.includes('MID:')) d = decodeR0(input);
    else d = decodeCT(input);

    setData(d);

    if (d) {
      const time = new Date().toLocaleTimeString();
      setLogs(prev => [{ time, type: d.type, status: d.estado }, ...prev].slice(0, 5));
    }
  }, [input]);

  return (
    <div className="min-h-screen p-4 flex justify-center relative">
      <div className="scanline"></div>
      
      <div className="w-full max-w-[480px] flex flex-col gap-4 relative z-20">
        
        {/* HEADER */}
        <div className="glass-panel p-5 text-center glow-blue relative overflow-hidden">
          <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-transparent via-[#3dd598] to-transparent"></div>
          <h1 className="text-2xl font-black tracking-widest text-white">NEXUS <span className="text-[#3dd598]">TACTICAL</span></h1>
          <p className="text-[10px] text-gray-400 tracking-[0.3em] mt-1">MULTI-PROTOCOL OFFLINE DASHBOARD</p>
        </div>

        {/* INPUT PANEL */}
        <div className="glass-panel p-4 flex flex-col gap-3">
          <div className="flex justify-between items-center">
            <span className="text-[10px] font-bold text-gray-400 tracking-widest">INPUT STREAM</span>
            {data && <span className={`px-3 py-1 rounded-full text-[10px] font-black border ${data.badge}`}>{data.type}</span>}
          </div>
          <textarea 
            value={input} 
            onChange={(e) => setInput(e.target.value)}
            className="w-full h-28 bg-black/50 border border-white/10 rounded-xl p-3 text-[11px] text-[#3dd598] font-mono resize-none focus:outline-none focus:border-[#3dd598] transition-colors"
            placeholder="Pega trama CT, KW o R0..."
          />
        </div>

        {/* RADAR Y GAUGES */}
        <div className="grid grid-cols-2 gap-3">
          <div className="glass-panel p-2 flex flex-col items-center justify-center col-span-2 relative">
            <span className="absolute top-2 left-3 text-[9px] text-gray-500 tracking-widest">LIVE SCAN</span>
            <RadarCanvas />
          </div>
          
          {data && data.type === 'CT' && (
            <>
              <Gauge value={data.voltU ? data.voltU/1000 : null} max={15} label="VOLT UNIDAD" unit="V" color="#3dd598" />
              <Gauge value={data.voltG ? data.voltG/1000 : null} max={5} label="VOLT GPS" unit="V" color="#2d6cdf" />
            </>
          )}
        </div>

        {/* DYNAMIC VIEWS */}
        {data && (
          <div className="glass-panel p-5 flex flex-col gap-4">
            <div className="text-center">
              <div className="text-[10px] text-gray-400 font-bold tracking-widest mb-1">ESTADO DEL SISTEMA</div>
              <div className={`text-xl font-black ${data.badge.split(' ')[1]}`}>{data.estado}</div>
              {data.rec && <div className="text-[11px] text-gray-400 mt-2">{data.rec}</div>}
            </div>

            {/* CT VIEW */}
            {data.type === 'CT' && (
              <div className="flex flex-col gap-4">
                <div className="flex justify-between text-[11px] font-mono text-gray-400">
                  <span>3E70: {data.c3E70}</span>
                  <span>FFFF: {data.cFFFF}</span>
                </div>
                <svg viewBox="0 0 340 140" className="w-full drop-shadow-2xl">
                  <rect x="10" y="20" width="200" height="90" rx="8" fill="rgba(15,23,42,0.8)" stroke="#2d6cdf" strokeWidth="2"/>
                  <text x="20" y="35" fill="#2d6cdf" fontSize="10" fontFamily="monospace">TERMO KING</text>
                  <circle cx="60" cy="75" r="18" fill={data.s1Color} stroke="#0f172a" strokeWidth="3" style={{transition:'fill 0.5s', filter:`drop-shadow(0 0 10px ${data.s1Color})`}}/>
                  <text x="60" y="79" textAnchor="middle" fill="#0f172a" fontSize="11" fontWeight="900">S1</text>
                  <circle cx="160" cy="75" r="18" fill={data.s2Color} stroke="#0f172a" strokeWidth="3" style={{transition:'fill 0.5s', filter:`drop-shadow(0 0 10px ${data.s2Color})`}}/>
                  <text x="160" y="79" textAnchor="middle" fill="#0f172a" fontSize="11" fontWeight="900">S2</text>
                  <path d="M210 40 L270 40 L300 70 L300 110 L210 110 Z" fill="#1e293b" stroke="#334155" strokeWidth="2"/>
                  <circle cx="240" cy="115" r="12" fill="#0f172a" stroke="#334155" strokeWidth="2"/>
                  <circle cx="290" cy="115" r="12" fill="#0f172a" stroke="#334155" strokeWidth="2"/>
                </svg>
              </div>
            )}

            {/* KW VIEW */}
            {data.type === 'KW' && (
              <div className="grid grid-cols-2 gap-4">
                <div className="flex flex-col items-center">
                  <div className="w-full h-32 bg-black/50 border border-white/10 rounded-xl relative overflow-hidden">
                    <div className="absolute bottom-0 w-full bg-gradient-to-t from-[#2d6cdf] to-[#3dd598] transition-all duration-1000" style={{height: `${data.pct1}%`}}></div>
                  </div>
                  <div className="mt-2 text-center font-mono font-black text-lg">{Math.round(data.pct1)}%</div>
                  <div className="text-[9px] text-gray-400">TANQUE 1</div>
                </div>
                <div className="flex flex-col items-center">
                  <div className="w-full h-32 bg-black/50 border border-white/10 rounded-xl relative overflow-hidden">
                    <div className="absolute bottom-0 w-full bg-gradient-to-t from-[#2d6cdf] to-[#3dd598] transition-all duration-1000" style={{height: `${data.pct2}%`}}></div>
                  </div>
                  <div className="mt-2 text-center font-mono font-black text-lg">{Math.round(data.pct2)}%</div>
                  <div className="text-[9px] text-gray-400">TANQUE 2</div>
                </div>
              </div>
            )}

            {/* R0 VIEW */}
            {data.type === 'R0' && (
              <div className="grid grid-cols-2 gap-4 text-[11px] font-mono">
                <div><span className="text-gray-500 block text-[9px]">APP</span>{data.app || '--'}</div>
                <div><span className="text-gray-500 block text-[9px]">APN</span>{data.apn || '--'}</div>
                <div><span className="text-gray-500 block text-[9px]">MID</span>{data.mid || '--'}</div>
                <div><span className="text-gray-500 block text-[9px]">INP</span>{data.inp || '--'}</div>
              </div>
            )}
          </div>
        )}

        {/* CONSOLE LOG */}
        <div className="glass-panel p-4 bg-black/40">
          <div className="text-[10px] text-gray-500 tracking-widest mb-2 border-b border-white/10 pb-2">SYSTEM LOG</div>
          <div className="flex flex-col gap-1 font-mono text-[10px]">
            {logs.map((l, i) => (
              <div key={i} className="flex justify-between text-gray-400">
                <span>[{l.time}]</span>
                <span className="text-[#3dd598]">{l.type}</span>
                <span className="truncate max-w-[120px]">{l.status}</span>
              </div>
            ))}
          </div>
        </div>

      </div>
    </div>
  );
};

ReactDOM.createRoot(document.getElementById('root')).render(<App />);
</script>
</body>
</html>
"@

$htmlContent | Set-Content -Path $MasterFile -Encoding UTF8
$sizeKB = [math]::Round((Get-Item $MasterFile).Length / 1KB, 2)

W "`n[FASE 1] Archivo generado exitosamente."
W "  [+] Ubicación: $MasterFile"
W "  [+] Tamaño: $sizeKB KB (React + Tailwind + Canvas animado)"
W "  [+] Funcionalidades: Radar Sweep, Gauges SVG, Fuel Tanks, System Log."

W "`n==================================================================="
W " RESUMEN DE OPERACIÓN"
W "==================================================================="
W " Se ha reinstaurado el modo 'Pesado y Complejo'. El nuevo Master"
W " integra React 18 y Tailwind CSS vía CDN, con un Radar Canvas"
W " animado en tiempo real, paneles de Glassmorphism profundos,"
W " y lógica para los 3 protocolos (CT, KW, R0)."
W "==================================================================="

Set-Clipboard -Value ($Buf -join "`r`n")
Write-Host "`n[OK] Salida copiada al portapapeles (Ctrl+V)."
