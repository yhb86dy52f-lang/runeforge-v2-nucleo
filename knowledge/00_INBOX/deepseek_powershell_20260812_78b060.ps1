# ================================================================
# fix_and_start.ps1  -  CORRECCIÓN RÁPIDA PARA RUNEFORGE V17
# ================================================================
# Este script:
#   1. Crea el archivo client/index.html con el frontend fusión.
#   2. Inicia el servidor Fastify en el puerto 3000.
#
# Ejecutar desde C:\RUNEFORGE_V2_CORE
# ================================================================

$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'

$base = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$clientDir = Join-Path $base 'client'
$daemonDir = Join-Path $base 'daemon'

# ================================================================
# 1. CREAR index.html (contenido fusión v17)
# ================================================================
Write-Host "[RUNEFORGE] Creando client/index.html..." -ForegroundColor Cyan

$htmlContent = @'
<!DOCTYPE html>
<html lang="es" data-theme="dark">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>RUNEFORGE v17.0 — Fusión Definitiva</title>
  
  <!-- Tailwind + Lucide + Vosk (cargado bajo demanda) -->
  <script src="https://cdn.tailwindcss.com"></script>
  <script src="https://unpkg.com/lucide@latest"></script>
  
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=JetBrains+Mono:wght@400;500;700&display=swap');

    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: 'Plus Jakarta Sans', system-ui, sans-serif;
      background: #050811;
      color: #e2e8f0;
      min-height: 100vh;
      padding-bottom: 100px;
      -webkit-tap-highlight-color: transparent;
    }
    .glass {
      background: rgba(10, 16, 31, 0.92);
      backdrop-filter: blur(16px);
      -webkit-backdrop-filter: blur(16px);
      border: 1px solid rgba(0, 242, 254, 0.12);
      border-radius: 16px;
      box-shadow: 0 8px 32px 0 rgba(0,0,0,0.5);
    }
    .glass-light {
      background: rgba(255,255,255,0.04);
      border: 1px solid rgba(255,255,255,0.06);
    }
    .mono { font-family: 'JetBrains Mono', monospace; font-size: 11px; }
    .btn {
      padding: 10px 14px;
      border-radius: 12px;
      font-weight: 800;
      font-size: 11px;
      border: 1px solid transparent;
      cursor: pointer;
      transition: all 0.15s ease;
      display: inline-flex;
      align-items: center;
      gap: 6px;
    }
    .btn:active { transform: scale(0.96); }
    .btn-cyan { background: #00f2fe; color: #050811; }
    .btn-cyan:hover { background: #00d4e6; box-shadow: 0 0 24px rgba(0,242,254,0.3); }
    .btn-green { background: #10b981; color: #050811; }
    .btn-green:hover { background: #059669; }
    .btn-red { background: #ef4444; color: #fff; }
    .btn-red:hover { background: #dc2626; }
    .btn-dark { background: #0f172a; border-color: #1e293b; color: #94a3b8; }
    .btn-dark:hover { background: #1e293b; border-color: #334155; }
    .btn-amber { background: #f59e0b; color: #050811; }
    .btn-amber:hover { background: #d97706; }

    input, select, textarea {
      width: 100%;
      background: #020617;
      border: 1px solid #1e293b;
      border-radius: 12px;
      padding: 10px 12px;
      color: #fff;
      font-size: 13px;
      font-family: 'Plus Jakarta Sans', sans-serif;
      transition: border-color 0.2s;
    }
    input:focus, select:focus, textarea:focus {
      outline: none;
      border-color: #00f2fe;
    }
    input::placeholder, textarea::placeholder { color: #475569; }

    .tab { display: none; flex-direction: column; gap: 16px; }
    .tab.active { display: flex; }

    .nav-bar {
      position: fixed;
      bottom: 0;
      left: 0;
      right: 0;
      background: rgba(2, 6, 23, 0.98);
      backdrop-filter: blur(12px);
      border-top: 1px solid #1e293b;
      display: grid;
      grid-template-columns: repeat(6, 1fr);
      z-index: 99;
      padding: 6px 0 10px 0;
    }
    .nav-bar button {
      background: none;
      border: none;
      color: #64748b;
      font-size: 8px;
      font-weight: 800;
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 2px;
      padding: 4px 0;
      transition: color 0.2s;
    }
    .nav-bar button i { width: 20px; height: 20px; }
    .nav-bar button.active { color: #00f2fe; }
    .nav-bar button.active i { filter: drop-shadow(0 0 6px rgba(0,242,254,0.4)); }

    .pulse-dot {
      display: inline-block;
      width: 8px;
      height: 8px;
      border-radius: 50%;
      background: #10b981;
      animation: pulse-green 2s infinite;
    }
    @keyframes pulse-green {
      0% { box-shadow: 0 0 0 0 rgba(16,185,129,0.6); }
      70% { box-shadow: 0 0 0 8px rgba(16,185,129,0); }
      100% { box-shadow: 0 0 0 0 rgba(16,185,129,0); }
    }

    /* Chat messages */
    .msg-user {
      background: rgba(0,242,254,0.12);
      border: 1px solid rgba(0,242,254,0.25);
      border-radius: 16px 16px 4px 16px;
      padding: 10px 14px;
      max-width: 85%;
      align-self: flex-end;
      font-size: 13px;
    }
    .msg-ai {
      background: rgba(255,255,255,0.05);
      border: 1px solid rgba(255,255,255,0.08);
      border-radius: 16px 16px 16px 4px;
      padding: 10px 14px;
      max-width: 85%;
      align-self: flex-start;
      font-size: 13px;
      white-space: pre-wrap;
    }

    .typing-dots span {
      display: inline-block;
      width: 6px;
      height: 6px;
      border-radius: 50%;
      background: #00f2fe;
      margin: 0 2px;
      animation: typing 1.4s infinite both;
    }
    .typing-dots span:nth-child(2) { animation-delay: 0.2s; }
    .typing-dots span:nth-child(3) { animation-delay: 0.4s; }
    @keyframes typing {
      0% { transform: scale(0.8); opacity: 0.4; }
      50% { transform: scale(1.2); opacity: 1; }
      100% { transform: scale(0.8); opacity: 0.4; }
    }

    .recording { border-color: #ef4444 !important; background: rgba(239,68,68,0.1); }

    ::-webkit-scrollbar { width: 4px; height: 4px; }
    ::-webkit-scrollbar-track { background: transparent; }
    ::-webkit-scrollbar-thumb { background: rgba(0,242,254,0.2); border-radius: 4px; }

    /* tarjetas de turnos */
    .card-turno {
      padding: 10px;
      border-bottom: 1px solid #1e293b;
      display: flex;
      justify-content: space-between;
      align-items: center;
      font-size: 12px;
    }
    .card-turno:last-child { border-bottom: none; }

    /* badge de estado */
    .badge {
      font-size: 9px;
      padding: 2px 8px;
      border-radius: 20px;
      border: 1px solid #1e293b;
      display: inline-block;
    }
  </style>
</head>
<body>

  <!-- ENCABEZADO FIJO -->
  <header class="sticky top-0 z-50 glass px-4 py-3 mb-3 flex items-center justify-between border-b border-cyan-500/20">
    <div class="flex items-center gap-3">
      <div class="w-10 h-10 rounded-xl bg-gradient-to-tr from-cyan-500 to-blue-600 flex items-center justify-center text-slate-950 font-extrabold shadow-lg shadow-cyan-500/30">
        <i data-lucide="zap" class="w-5 h-5 fill-slate-950"></i>
      </div>
      <div>
        <div class="flex items-center gap-2">
          <span class="font-extrabold text-sm tracking-tight text-white">RUNEFORGE <span class="text-cyan-400 font-mono text-xs">v17.0</span></span>
          <span class="px-2 py-0.5 text-[10px] font-mono font-semibold bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 rounded-full flex items-center gap-1">
            <span class="pulse-dot"></span> FASTIFY
          </span>
        </div>
        <div id="header-status" class="text-[11px] text-slate-400 font-medium">Motor RAG activo · Ollama listo</div>
      </div>
    </div>
    <div class="flex items-center gap-2">
      <button onclick="syncWithServer()" class="btn btn-dark text-[10px] px-3 py-1.5" title="Sincronizar con servidor">
        <i data-lucide="refresh-cw" class="w-3.5 h-3.5"></i> Sinc
      </button>
      <button onclick="exportFullBackup()" class="btn btn-dark text-[10px] px-3 py-1.5" title="Respaldo completo">
        <i data-lucide="download" class="w-3.5 h-3.5"></i> Backup
      </button>
    </div>
  </header>

  <!-- CONTENEDOR PRINCIPAL -->
  <div class="max-w-3xl mx-auto px-4">

    <!-- ===== TAB: INICIO ===== -->
    <section id="tab-dash" class="tab active">
      <div class="glass p-4 grid grid-cols-4 gap-2 text-center">
        <div><div class="text-[10px] text-slate-400">TOTAL</div><div id="stat-total" class="text-2xl font-black">0</div></div>
        <div><div class="text-[10px] text-slate-400">HOY</div><div id="stat-today" class="text-2xl font-black text-cyan-400">0</div></div>
        <div><div class="text-[10px] text-slate-400">EXTRA SEM</div><div id="stat-extra" class="text-2xl font-black text-amber-400">0h</div></div>
        <div><div class="text-[10px] text-slate-400">NIVEL</div><div id="stat-level" class="text-2xl font-black text-purple-400">1</div></div>
      </div>

      <div class="glass p-4">
        <div class="flex justify-between items-center border-b border-slate-800 pb-2 mb-2">
          <span class="font-bold text-sm">📊 Resumen Semanal (Mié–Mar)</span>
          <span class="text-[10px] text-cyan-400" id="week-label">Cargando...</span>
        </div>
        <div id="week-summary" class="space-y-2"></div>
        <div class="mt-3 flex justify-between text-sm">
          <span>Base local: <span id="local-count" class="font-mono text-cyan-300">0</span> trabajos</span>
          <span>Servidor: <span id="server-count" class="font-mono text-emerald-300">0</span></span>
        </div>
      </div>

      <div class="grid grid-cols-3 gap-3">
        <button onclick="switchTab('chat')" class="glass p-3 flex flex-col items-center hover:border-cyan-500/40 transition-all">
          <i data-lucide="message-circle" class="w-6 h-6 text-cyan-400"></i>
          <span class="text-[10px] font-bold mt-1">Chat IA</span>
        </button>
        <button onclick="switchTab('new')" class="glass p-3 flex flex-col items-center hover:border-emerald-500/40 transition-all">
          <i data-lucide="file-plus" class="w-6 h-6 text-emerald-400"></i>
          <span class="text-[10px] font-bold mt-1">Nueva Orden</span>
        </button>
        <button onclick="switchTab('turno')" class="glass p-3 flex flex-col items-center hover:border-amber-500/40 transition-all">
          <i data-lucide="clock" class="w-6 h-6 text-amber-400"></i>
          <span class="text-[10px] font-bold mt-1">Turnos</span>
        </button>
      </div>
    </section>

    <!-- ===== TAB: CHAT ===== -->
    <section id="tab-chat" class="tab">
      <div class="glass p-4 space-y-3">
        <div class="flex items-center justify-between border-b border-slate-800 pb-2">
          <span class="font-bold text-cyan-300 flex items-center gap-2"><i data-lucide="bot" class="w-4 h-4"></i> Conversación</span>
          <span class="text-[10px] bg-cyan-500/10 px-2 py-0.5 rounded-full border border-cyan-500/20" id="chat-model-badge">qwen2.5:1.5b</span>
        </div>
        <div id="chat-container" class="flex flex-col gap-3 max-h-[60vh] overflow-y-auto p-1">
          <div class="msg-ai">👋 Hola, soy Runeforge. Pregúntame sobre el motor, sus tecnologías o ejecuta scripts. Usa el menú inferior para cambiar de modelo o limpiar la conversación.</div>
        </div>
        <div class="flex gap-2">
          <input type="text" id="chat-input" placeholder="Pregunta algo..." class="flex-1 bg-slate-950 border border-slate-800 rounded-xl px-3 py-2 text-sm text-white placeholder-slate-500 focus:outline-none focus:border-cyan-500/50">
          <button onclick="sendChat()" class="btn btn-cyan px-4">Enviar</button>
        </div>
        <div class="flex flex-wrap gap-1.5 pt-1">
          <button onclick="clearChat()" class="btn btn-dark text-[10px] px-2 py-1">Limpiar</button>
          <button onclick="changeModel('qwen2.5:1.5b')" class="btn btn-dark text-[10px] px-2 py-1">1.5b</button>
          <button onclick="changeModel('llama3.2:3b')" class="btn btn-dark text-[10px] px-2 py-1">3b</button>
          <button onclick="changeModel('mistral:7b')" class="btn btn-dark text-[10px] px-2 py-1">7b</button>
          <button onclick="toggleVoskChat()" class="btn btn-amber text-[10px] px-2 py-1 flex items-center gap-1"><i data-lucide="mic" class="w-3 h-3"></i> Voz</button>
        </div>
      </div>
    </section>

    <!-- ===== TAB: NUEVA ORDEN ===== -->
    <section id="tab-new" class="tab">
      <div class="glass p-4 space-y-3">
        <div class="flex items-center justify-between border-b border-slate-800 pb-2">
          <span class="font-bold text-emerald-300 flex items-center gap-2"><i data-lucide="plus-circle" class="w-4 h-4"></i> Nueva Orden de Servicio</span>
          <span class="badge text-cyan-300 border-cyan-500/30">Voz offline disponible</span>
        </div>

        <div class="grid grid-cols-3 gap-2">
          <select id="fUnitType" class="text-sm"><option>KW</option><option>CT</option><option>CCTV</option><option>RAM</option></select>
          <input id="fAsset" placeholder="Unidad (ej: 547_R)" class="uppercase text-sm">
          <input id="fDate" type="date" class="text-sm">
        </div>
        <div class="grid grid-cols-3 gap-2">
          <input id="fTime" type="time" class="text-sm">
          <input id="fStart" type="time" class="text-sm">
          <input id="fEnd" type="time" class="text-sm">
        </div>
        <div class="relative">
          <input id="fReason" placeholder="Motivo / falla" class="text-sm pr-10">
          <button onclick="toggleMic('fReason')" class="absolute right-2 top-1/2 -translate-y-1/2 p-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300"><i data-lucide="mic" class="w-4 h-4"></i></button>
        </div>
        <div class="relative">
          <textarea id="fProcedure" rows="4" placeholder="Procedimiento realizado..." class="text-sm pr-10"></textarea>
          <button onclick="toggleMic('fProcedure')" class="absolute right-2 bottom-2 p-1.5 rounded-lg bg-amber-500/20 hover:bg-amber-500/30 text-amber-400 border border-amber-500/30"><i data-lucide="mic" class="w-4 h-4"></i></button>
        </div>
        <div class="flex gap-2">
          <button onclick="guardarOrden()" class="btn btn-cyan flex-1">💾 Guardar Orden</button>
          <button onclick="switchTab('log')" class="btn btn-dark">Ver bitácora</button>
        </div>
        <p class="text-[10px] text-slate-500">✓ Los datos se guardan localmente y se sincronizan con el servidor.</p>
      </div>
    </section>

    <!-- ===== TAB: TURNOS ===== -->
    <section id="tab-turno" class="tab">
      <div class="glass p-4 space-y-3">
        <div class="flex justify-between items-center border-b border-slate-800 pb-2">
          <span class="font-bold text-amber-300 flex items-center gap-2"><i data-lucide="clock" class="w-4 h-4"></i> Control de Turnos</span>
          <span class="badge text-amber-300 border-amber-500/30">Ciclo Mié–Mar</span>
        </div>
        <div class="grid grid-cols-2 gap-2">
          <input id="t-date" type="date" class="text-sm">
          <select id="t-type" class="text-sm"><option value="entrada">ENTRADA</option><option value="salida">SALIDA</option></select>
        </div>
        <div class="grid grid-cols-2 gap-2">
          <input id="t-time" type="time" class="text-sm">
          <button onclick="registrarTurno()" class="btn btn-green">Registrar</button>
        </div>
        <div id="today-turno-status" class="text-center text-sm text-slate-400 bg-slate-950/50 p-2 rounded-xl">Sin registro hoy</div>
      </div>
      <div class="glass p-4">
        <div class="font-bold text-sm mb-2">Historial de turnos</div>
        <div id="turnos-container" class="max-h-60 overflow-y-auto"></div>
      </div>
    </section>

    <!-- ===== TAB: BITÁCORA ===== -->
    <section id="tab-log" class="tab">
      <div class="glass p-4 space-y-3">
        <div class="flex justify-between items-center">
          <span class="font-bold text-cyan-300">📚 Bitácora de Órdenes</span>
          <span class="text-[10px] text-slate-400" id="order-count">0 registros</span>
        </div>
        <input id="search-input" oninput="filterOrders()" placeholder="Buscar por unidad o motivo..." class="text-sm">
        <div id="timeline-container" class="flex flex-col gap-3 max-h-[60vh] overflow-y-auto"></div>
      </div>
    </section>

    <!-- ===== TAB: IMPORTAR ===== -->
    <section id="tab-import" class="tab">
      <div class="glass p-4 space-y-3">
        <span class="font-bold text-purple-300 flex items-center gap-2"><i data-lucide="file-text" class="w-4 h-4"></i> Parser de WhatsApp / Texto</span>
        <textarea id="whatsapp-raw" rows="8" class="mono text-sm" placeholder="Pega aquí los mensajes...
Unidad: KW 594
Hora: 11:00
Inicio: 17:30
Fin: 21:40
Motivo: Cambio de sensor
Procedimiento: Se instala nuevo sensor..."></textarea>
        <button onclick="procesarLote()" class="btn btn-cyan w-full">📥 Procesar e importar lote</button>
        <p class="text-[10px] text-slate-500">Reconocerá campos: Unidad, Hora, Inicio, Fin, Motivo, Procedimiento.</p>
      </div>
    </section>

    <!-- ===== TAB: HERRAMIENTAS ===== -->
    <section id="tab-tools" class="tab">
      <div class="glass p-4 space-y-3">
        <span class="font-bold text-indigo-300 flex items-center gap-2"><i data-lucide="settings" class="w-4 h-4"></i> Herramientas & Configuración</span>
        <div class="flex flex-wrap gap-2">
          <button onclick="syncWithServer()" class="btn btn-dark"><i data-lucide="refresh-cw" class="w-3.5 h-3.5"></i> Sincronizar</button>
          <button onclick="exportFullBackup()" class="btn btn-dark"><i data-lucide="download" class="w-3.5 h-3.5"></i> Backup JSON</button>
          <button onclick="document.getElementById('import-file').click()" class="btn btn-dark"><i data-lucide="upload" class="w-3.5 h-3.5"></i> Restaurar</button>
          <input id="import-file" type="file" accept=".json" style="display:none" onchange="restoreBackup(event)">
          <button onclick="clearAllLocal()" class="btn btn-red"><i data-lucide="trash-2" class="w-3.5 h-3.5"></i> Limpiar Local</button>
        </div>
        <div id="storage-detail" class="bg-slate-950 p-3 rounded-xl text-xs font-mono text-slate-400"></div>
        <div class="text-xs text-slate-500">
          <p>✅ Datos almacenados en localStorage con llave <span class="text-cyan-300">rune_v17</span></p>
          <p>🔁 Sincronización automática con servidor Fastify</p>
          <p>🧠 Vosk offline: <span id="vosk-status" class="text-amber-400">No cargado</span></p>
          <button onclick="cargarVosk()" class="btn btn-amber text-[10px] mt-2">🧠 Cargar VOSK (offline)</button>
        </div>
      </div>
    </section>

  </div>

  <!-- NAVEGACIÓN INFERIOR -->
  <nav class="nav-bar">
    <button id="b-dash" class="active" onclick="switchTab('dash')"><i data-lucide="layout-dashboard"></i> Inicio</button>
    <button id="b-chat" onclick="switchTab('chat')"><i data-lucide="message-circle"></i> Chat</button>
    <button id="b-new" onclick="switchTab('new')"><i data-lucide="plus-circle"></i> Nueva</button>
    <button id="b-turno" onclick="switchTab('turno')"><i data-lucide="clock"></i> Turnos</button>
    <button id="b-log" onclick="switchTab('log')"><i data-lucide="list-checks"></i> Bitácora</button>
    <button id="b-import" onclick="switchTab('import')"><i data-lucide="file-text"></i> Importar</button>
    <!-- tools está oculto en nav, pero accesible desde inicio o mediante doble tap (lo dejamos fuera para no saturar) -->
  </nav>

  <!-- TOAST -->
  <div id="toastContainer" class="fixed bottom-24 left-1/2 -translate-x-1/2 z-50 w-11/12 max-w-xs space-y-2 pointer-events-none"></div>

  <script>
    // ======================================================
    // 1. ESTADO Y PERSISTENCIA LOCAL (clave única v17)
    // ======================================================
    const STORAGE_KEY = 'rune_v17';
    let orders = JSON.parse(localStorage.getItem(STORAGE_KEY + '_orders') || '[]');
    let turnos = JSON.parse(localStorage.getItem(STORAGE_KEY + '_turnos') || '[]');
    let xp = parseInt(localStorage.getItem(STORAGE_KEY + '_xp') || '0');

    // Estado del chat
    let currentModel = 'qwen2.5:1.5b';
    let isStreaming = false;
    let recognition = null;         // para voz Chrome
    let recordingField = null;
    let voskReady = false;

    // ======================================================
    // 2. FUNCIONES UTILITARIAS
    // ======================================================
    function hoyISO() {
      return new Date().toISOString().split('T')[0];
    }

    function horaActual() {
      return new Date().toTimeString().slice(0,5);
    }

    function saveLocal() {
      localStorage.setItem(STORAGE_KEY + '_orders', JSON.stringify(orders));
      localStorage.setItem(STORAGE_KEY + '_turnos', JSON.stringify(turnos));
      localStorage.setItem(STORAGE_KEY + '_xp', String(xp));
    }

    function showToast(msg, type = 'info') {
      const container = document.getElementById('toastContainer');
      const toast = document.createElement('div');
      toast.className = 'glass p-3 rounded-xl border border-cyan-500/30 text-xs font-mono text-slate-100 shadow-xl opacity-0 transform translate-y-2 transition-all duration-200';
      toast.textContent = msg;
      if (type === 'error') toast.style.borderColor = '#ef4444';
      if (type === 'success') toast.style.borderColor = '#10b981';
      container.appendChild(toast);
      requestAnimationFrame(() => {
        toast.classList.remove('opacity-0', 'translate-y-2');
      });
      setTimeout(() => {
        toast.classList.add('opacity-0', 'translate-y-2');
        setTimeout(() => toast.remove(), 200);
      }, 2800);
    }

    // ======================================================
    // 3. SISTEMA DE TABS
    // ======================================================
    function switchTab(id) {
      document.querySelectorAll('.tab').forEach(el => el.classList.remove('active'));
      document.getElementById('tab-' + id).classList.add('active');
      document.querySelectorAll('.nav-bar button').forEach(btn => btn.classList.remove('active'));
      const btn = document.getElementById('b-' + id);
      if (btn) btn.classList.add('active');
      if (id === 'log') renderTimeline(orders);
      if (id === 'turno') renderTurnos();
      if (id === 'dash') renderDashboard();
    }

    // ======================================================
    // 4. RENDERIZADO DE DASHBOARD
    // ======================================================
    function renderDashboard() {
      document.getElementById('stat-total').textContent = orders.length;
      const today = hoyISO();
      document.getElementById('stat-today').textContent = orders.filter(o => o.request_date === today).length;
      document.getElementById('stat-level').textContent = Math.floor(xp / 100) + 1;
      document.getElementById('local-count').textContent = orders.length;
      // Semana
      const week = getWeekRange();
      document.getElementById('week-label').textContent = `${week.startStr} - ${week.endStr}`;
      const weekOrders = orders.filter(o => o.request_date >= week.startStr && o.request_date <= week.endStr);
      // Calcular extras desde turnos
      const weekTurnos = turnos.filter(t => t.date >= week.startStr && t.date <= week.endStr);
      const grouped = {};
      weekTurnos.forEach(t => {
        if (!grouped[t.date]) grouped[t.date] = [];
        grouped[t.date].push(t);
      });
      let totalExtra = 0;
      let html = '';
      Object.keys(grouped).sort().forEach(date => {
        const entries = grouped[date].sort((a,b) => a.time.localeCompare(b.time));
        const ent = entries.find(e => e.type === 'entrada');
        const sal = [...entries].reverse().find(e => e.type === 'salida');
        let horas = 0, extra = 0;
        if (ent && sal) {
          const e = new Date(date + 'T' + ent.time);
          const s = new Date(date + 'T' + sal.time);
          horas = (s - e) / 1000 / 3600;
          if (horas < 0) horas += 24;
          const day = new Date(date + 'T00:00:00').getDay(); // 0 domingo
          extra = (day === 0) ? horas : Math.max(0, horas - 8);
          totalExtra += extra;
        }
        html += `<div class="flex justify-between text-sm border-b border-slate-800 py-1.5">
          <span>${date}</span>
          <span>${ent ? ent.time : '--'} → ${sal ? sal.time : '--'} <span class="text-cyan-300">${horas.toFixed(1)}h</span></span>
          <span class="${extra > 0 ? 'text-amber-400 font-bold' : 'text-slate-500'}">${extra > 0 ? extra.toFixed(1)+'h extra' : ''}</span>
        </div>`;
      });
      if (!html) html = '<div class="text-slate-500 text-sm">Sin registros esta semana.</div>';
      document.getElementById('week-summary').innerHTML = html;
      document.getElementById('stat-extra').textContent = totalExtra.toFixed(1) + 'h';
      // Estado del servidor (se actualiza con sync)
    }

    function getWeekRange() {
      const now = new Date();
      const day = now.getDay();
      const diff = (day + 4) % 7; // miércoles = 3
      const wed = new Date(now);
      wed.setDate(now.getDate() - diff);
      wed.setHours(0,0,0,0);
      const tue = new Date(wed);
      tue.setDate(wed.getDate() + 6);
      tue.setHours(23,59,59,999);
      return {
        startStr: wed.toISOString().split('T')[0],
        endStr: tue.toISOString().split('T')[0],
        start: wed,
        end: tue
      };
    }

    // ======================================================
    // 5. ÓRDENES: CRUD + BITÁCORA
    // ======================================================
    function guardarOrden() {
      const unitType = document.getElementById('fUnitType').value;
      const asset = document.getElementById('fAsset').value.trim().toUpperCase();
      const date = document.getElementById('fDate').value || hoyISO();
      const reqTime = document.getElementById('fTime').value;
      const start = document.getElementById('fStart').value;
      const end = document.getElementById('fEnd').value;
      const reason = document.getElementById('fReason').value.trim();
      const procedure = document.getElementById('fProcedure').value.trim();

      if (!asset || !reason) {
        showToast('⚠️ Unidad y motivo son obligatorios', 'error');
        return;
      }

      const newOrder = {
        id: Date.now(),
        unit_type: unitType,
        asset_id: asset,
        request_date: date,
        request_time: reqTime,
        start_time: start,
        end_time: end,
        reason,
        procedure_log: procedure,
        status: 'CLOSED',
        technician: 'Néstor Corchado Valenzuela'
      };

      orders.push(newOrder);
      xp += 50;
      saveLocal();
      // Enviar al servidor
      fetch('/api/orders', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(newOrder)
      }).then(res => {
        if (res.ok) showToast('✅ Orden guardada en servidor', 'success');
        else showToast('⚠️ Guardada local, falló sincronización', 'error');
      }).catch(() => showToast('⚠️ Sin conexión, guardada local', 'error'));

      // Limpiar campos
      document.getElementById('fAsset').value = '';
      document.getElementById('fReason').value = '';
      document.getElementById('fProcedure').value = '';
      renderDashboard();
      showToast('✅ Orden registrada (+50 XP)', 'success');
    }

    function renderTimeline(list) {
      const container = document.getElementById('timeline-container');
      if (!list || list.length === 0) {
        container.innerHTML = '<div class="text-center text-slate-500 py-6">No hay órdenes registradas.</div>';
        document.getElementById('order-count').textContent = '0 registros';
        return;
      }
      document.getElementById('order-count').textContent = list.length + ' registros';
      container.innerHTML = list.slice().reverse().map(o => `
        <div class="glass p-3 space-y-1.5">
          <div class="flex justify-between items-start">
            <div>
              <span class="font-bold text-cyan-300 text-sm">${o.asset_id}</span>
              <span class="badge text-[10px] ml-2 ${o.status === 'PENDING' ? 'border-amber-500/40 text-amber-400' : 'border-emerald-500/40 text-emerald-400'}">${o.status || 'CERRADA'}</span>
            </div>
            <span class="text-[10px] text-slate-400">${o.request_date}</span>
          </div>
          <div class="font-semibold text-sm">${o.reason}</div>
          <div class="text-sm text-slate-300 whitespace-pre-wrap">${(o.procedure_log || '').slice(0, 200)}${(o.procedure_log || '').length > 200 ? '...' : ''}</div>
          <div class="flex gap-2 pt-1">
            <button onclick="copiarWSP(${o.id})" class="btn btn-dark text-[10px] px-2 py-1">📋 Copiar WSP</button>
            <button onclick="borrarOrden(${o.id})" class="btn btn-red text-[10px] px-2 py-1">🗑️</button>
          </div>
        </div>
      `).join('');
    }

    function filterOrders() {
      const q = document.getElementById('search-input').value.toLowerCase();
      const filtered = orders.filter(o =>
        (o.asset_id || '').toLowerCase().includes(q) ||
        (o.reason || '').toLowerCase().includes(q) ||
        (o.procedure_log || '').toLowerCase().includes(q)
      );
      renderTimeline(filtered);
    }

    function copiarWSP(id) {
      const o = orders.find(x => x.id === id);
      if (!o) return;
      const txt = `Unidad: ${o.asset_id}\nHora: ${o.request_time || ''}\nInicio: ${o.start_time || ''}\nFin: ${o.end_time || ''}\nMotivo: ${o.reason}\nProcedimiento: ${o.procedure_log || ''}\nAtendió: ${o.technician || 'Néstor Corchado Valenzuela'}`;
      navigator.clipboard.writeText(txt).then(() => showToast('📋 Copiado', 'success')).catch(() => showToast('Error al copiar', 'error'));
    }

    function borrarOrden(id) {
      if (!confirm('¿Eliminar esta orden?')) return;
      orders = orders.filter(o => o.id !== id);
      saveLocal();
      renderTimeline(orders);
      renderDashboard();
      showToast('🗑️ Orden eliminada', 'info');
    }

    // ======================================================
    // 6. TURNOS
    // ======================================================
    function registrarTurno() {
      const date = document.getElementById('t-date').value || hoyISO();
      const type = document.getElementById('t-type').value;
      const time = document.getElementById('t-time').value || horaActual();

      turnos.push({ id: Date.now(), date, time, type });
      xp += 5;
      saveLocal();
      // Enviar al servidor
      fetch('/api/fichajes', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ entry_date: date, check_in: type === 'entrada' ? time : '', check_out: type === 'salida' ? time : '' })
      }).catch(() => {});
      renderTurnos();
      renderDashboard();
      showToast(`⏱️ ${type.toUpperCase()} registrada a las ${time}`, 'success');
    }

    function renderTurnos() {
      const container = document.getElementById('turnos-container');
      if (!turnos.length) {
        container.innerHTML = '<div class="text-slate-500 text-center py-3">Sin turnos registrados.</div>';
        return;
      }
      const sorted = [...turnos].reverse().slice(0, 30);
      container.innerHTML = sorted.map(t => `
        <div class="card-turno">
          <span>${t.date} ${t.time} <span class="badge ${t.type === 'entrada' ? 'border-emerald-500/40 text-emerald-400' : 'border-amber-500/40 text-amber-400'}">${t.type.toUpperCase()}</span></span>
          <button onclick="borrarTurno(${t.id})" class="text-red-400 text-xs">✕</button>
        </div>
      `).join('');

      // estado de hoy
      const today = hoyISO();
      const hoyTurnos = turnos.filter(t => t.date === today);
      document.getElementById('today-turno-status').textContent = hoyTurnos.length ? hoyTurnos.map(t => t.type + ' ' + t.time).join(' | ') : 'Sin registro hoy';
    }

    function borrarTurno(id) {
      turnos = turnos.filter(t => t.id !== id);
      saveLocal();
      renderTurnos();
      renderDashboard();
    }

    // ======================================================
    // 7. IMPORTAR LOTE DESDE WHATSAPP
    // ======================================================
    function procesarLote() {
      const raw = document.getElementById('whatsapp-raw').value;
      if (!raw.trim()) { showToast('⚠️ Pega el texto primero', 'error'); return; }

      const blocks = raw.split(/(?=Unidad\s*:)/gi);
      let imported = 0;
      blocks.forEach(block => {
        if (!block.trim()) return;
        const get = (key) => {
          const match = block.match(new RegExp(key + '\\s*:\\s*([^\\n]+)', 'i'));
          return match ? match[1].trim() : '';
        };
        const unit = get('Unidad');
        if (!unit) return;
        const motivo = get('Motivo') || 'Mantenimiento preventivo';
        const procMatch = block.match(/Procedimiento:\s*([\s\S]+?)(?:Atendió|$)/i);
        const procedimiento = procMatch ? procMatch[1].trim() : get('Procedimiento');
        const newOrder = {
          id: Date.now() + Math.random() * 1000,
          unit_type: unit.startsWith('CT') ? 'CT' : unit.startsWith('CCTV') ? 'CCTV' : 'KW',
          asset_id: unit.toUpperCase(),
          request_date: hoyISO(),
          request_time: get('Hora'),
          start_time: get('Inicio'),
          end_time: get('Fin'),
          reason: motivo,
          procedure_log: procedimiento || block.trim(),
          technician: 'Néstor Corchado Valenzuela',
          status: 'CLOSED'
        };
        orders.push(newOrder);
        imported++;
      });

      xp += imported * 10;
      saveLocal();
      // Enviar lote al servidor
      fetch('/api/orders/bulk', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(orders.slice(-imported))
      }).catch(() => {});

      renderTimeline(orders);
      renderDashboard();
      showToast(`📥 ${imported} órdenes importadas`, 'success');
      document.getElementById('whatsapp-raw').value = '';
    }

    // ======================================================
    // 8. CHAT CON IA (streaming)
    // ======================================================
    function addMessage(role, content, isPartial = false) {
      const container = document.getElementById('chat-container');
      const div = document.createElement('div');
      div.className = role === 'user' ? 'msg-user' : 'msg-ai';
      if (role === 'ai' && isPartial) {
        div.innerHTML = `<span class="typing-dots"><span></span><span></span><span></span></span>`;
        div.id = 'streaming-msg';
      } else {
        div.textContent = content;
      }
      container.appendChild(div);
      container.scrollTop = container.scrollHeight;
      return div;
    }

    async function sendChat() {
      const input = document.getElementById('chat-input');
      const prompt = input.value.trim();
      if (!prompt || isStreaming) return;
      input.value = '';

      addMessage('user', prompt);
      isStreaming = true;

      try {
        const response = await fetch('/api/chat', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ prompt, model: currentModel })
        });

        if (!response.ok) throw new Error('Error en servidor');

        const reader = response.body.getReader();
        const decoder = new TextDecoder('utf-8');
        let fullText = '';

        // eliminar el mensaje de "escritura" previo
        const container = document.getElementById('chat-container');
        const oldTyping = document.getElementById('streaming-msg');
        if (oldTyping) oldTyping.remove();

        const finalMsg = document.createElement('div');
        finalMsg.className = 'msg-ai';
        container.appendChild(finalMsg);

        while (true) {
          const { done, value } = await reader.read();
          if (done) break;
          const chunk = decoder.decode(value, { stream: true });
          const lines = chunk.split('\n');
          for (const line of lines) {
            if (line.startsWith('data: ')) {
              const data = line.slice(6);
              if (data === '[DONE]') continue;
              try {
                const parsed = JSON.parse(data);
                if (parsed.response) {
                  fullText += parsed.response;
                  finalMsg.textContent = fullText;
                  container.scrollTop = container.scrollHeight;
                }
              } catch (e) {
                if (line.trim()) {
                  fullText += line;
                  finalMsg.textContent = fullText;
                  container.scrollTop = container.scrollHeight;
                }
              }
            }
          }
        }
        xp += 10;
        saveLocal();
      } catch (err) {
        const container = document.getElementById('chat-container');
        const errMsg = document.createElement('div');
        errMsg.className = 'msg-ai text-red-400';
        errMsg.textContent = '❌ Error al conectar con el servidor.';
        container.appendChild(errMsg);
        console.error(err);
      } finally {
        isStreaming = false;
        const container = document.getElementById('chat-container');
        const dots = container.querySelector('.typing-dots');
        if (dots) dots.parentElement?.remove();
      }
    }

    function clearChat() {
      const container = document.getElementById('chat-container');
      container.innerHTML = `<div class="msg-ai">👋 Conversación reiniciada. Pregunta lo que quieras.</div>`;
    }

    function changeModel(model) {
      currentModel = model;
      document.getElementById('chat-model-badge').textContent = model;
      showToast(`🔁 Modelo cambiado a ${model}`, 'info');
    }

    // ======================================================
    // 9. RECONOCIMIENTO DE VOZ (Chrome nativo + Vosk offline)
    // ======================================================
    function toggleMic(fieldId) {
      // Si Vosk está cargado, usarlo; si no, fallback a Chrome
      if (voskReady) {
        iniciarVoskMic(fieldId);
        return;
      }
      // Fallback Chrome
      const SR = window.SpeechRecognition || window.webkitSpeechRecognition;
      if (!SR) {
        showToast('⚠️ Activa VOSK o usa Chrome', 'error');
        return;
      }
      if (recognition && recordingField === fieldId) {
        recognition.stop();
        return;
      }
      const r = new SR();
      r.lang = 'es-MX';
      r.continuous = false;
      recordingField = fieldId;
      const btn = document.querySelector(`#${fieldId}`)?.closest('.relative')?.querySelector('button');
      if (btn) btn.classList.add('recording');

      r.onresult = (e) => {
        const text = e.results[0][0].transcript;
        const input = document.getElementById(fieldId);
        input.value += (input.value ? ' ' : '') + text;
      };
      r.onend = () => {
        if (btn) btn.classList.remove('recording');
        recordingField = null;
      };
      r.start();
      recognition = r;
    }

    async function cargarVosk() {
      try {
        if (window.Vosk) {
          await initVosk();
          return;
        }
        // Cargar script de Vosk desde CDN
        const script = document.createElement('script');
        script.src = 'https://cdn.jsdelivr.net/npm/vosk-browser@0.0.8/dist/vosk.js';
        document.head.appendChild(script);
        await new Promise((resolve, reject) => {
          script.onload = resolve;
          script.onerror = reject;
        });
        await initVosk();
      } catch (e) {
        document.getElementById('vosk-status').textContent = '❌ Error cargando Vosk';
        showToast('Error al cargar Vosk: ' + e.message, 'error');
      }
    }

    async function initVosk() {
      try {
        const model = await Vosk.createModel('https://ccoreilly.github.io/vosk-browser/models/vosk-model-small-es-0.42.tar.gz');
        voskReady = true;
        document.getElementById('vosk-status').textContent = '✅ VOSK offline listo';
        showToast('🧠 Vosk cargado correctamente', 'success');
      } catch (e) {
        document.getElementById('vosk-status').textContent = '❌ Error: ' + e.message;
        showToast('Error al iniciar Vosk', 'error');
      }
    }

    function iniciarVoskMic(fieldId) {
      // Implementación simple: usa el reconocimiento de Chrome, pero podríamos extender con Vosk real
      // Por ahora usamos Chrome con un mensaje de que Vosk está listo.
      showToast('🧠 Vosk offline listo, pero usa Chrome para dictado ahora', 'info');
      toggleMic(fieldId); // fallback
    }

    // ======================================================
    // 10. SINCRONIZACIÓN CON SERVIDOR
    // ======================================================
    async function syncWithServer() {
      try {
        // Obtener órdenes del servidor
        const resOrders = await fetch('/api/orders');
        if (resOrders.ok) {
          const serverOrders = await resOrders.json();
          // Fusionar: los del servidor tienen prioridad, pero preservamos los locales con IDs únicos
          const localIds = new Set(orders.map(o => o.id));
          const merged = [...serverOrders, ...orders.filter(o => !serverOrders.some(s => s.id === o.id))];
          // Ordenar por ID
          merged.sort((a,b) => a.id - b.id);
          orders = merged;
          saveLocal();
          renderDashboard();
          renderTimeline(orders);
          document.getElementById('server-count').textContent = serverOrders.length;
          showToast('🔄 Sincronizado con servidor', 'success');
        } else {
          showToast('⚠️ Error al obtener datos del servidor', 'error');
        }
      } catch (e) {
        showToast('⚠️ Servidor no disponible', 'error');
      }
    }

    // ======================================================
    // 11. BACKUP Y RESTAURACIÓN
    // ======================================================
    function exportFullBackup() {
      const data = { orders, turnos, xp };
      const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `backup_rune_${hoyISO()}.json`;
      a.click();
      URL.revokeObjectURL(url);
      showToast('📦 Backup descargado', 'success');
    }

    function restoreBackup(event) {
      const file = event.target.files[0];
      if (!file) return;
      const reader = new FileReader();
      reader.onload = (e) => {
        try {
          const data = JSON.parse(e.target.result);
          if (data.orders && data.turnos !== undefined) {
            orders = data.orders || [];
            turnos = data.turnos || [];
            xp = data.xp || 0;
            saveLocal();
            renderAll();
            showToast('✅ Restauración exitosa', 'success');
          } else {
            showToast('⚠️ Formato de backup inválido', 'error');
          }
        } catch (err) {
          showToast('❌ Error al leer archivo', 'error');
        }
      };
      reader.readAsText(file);
      event.target.value = '';
    }

    function clearAllLocal() {
      if (!confirm('¿Eliminar todos los datos locales? (No afecta al servidor)')) return;
      localStorage.removeItem(STORAGE_KEY + '_orders');
      localStorage.removeItem(STORAGE_KEY + '_turnos');
      localStorage.removeItem(STORAGE_KEY + '_xp');
      orders = [];
      turnos = [];
      xp = 0;
      renderAll();
      showToast('🧹 Datos locales limpiados', 'info');
    }

    // ======================================================
    // 12. RENDERIZADO GENERAL
    // ======================================================
    function renderAll() {
      renderDashboard();
      renderTimeline(orders);
      renderTurnos();
      document.getElementById('storage-detail').innerHTML = `
        <div>Órdenes: ${orders.length}</div>
        <div>Turnos: ${turnos.length}</div>
        <div>XP: ${xp}</div>
        <div>Espacio usado: ${(JSON.stringify({orders,turnos,xp}).length / 1024).toFixed(1)} KB</div>
      `;
      document.getElementById('header-status').textContent = `Motor RAG activo · ${orders.length} órdenes locales`;
    }

    // ======================================================
    // 13. INICIALIZACIÓN
    // ======================================================
    document.addEventListener('DOMContentLoaded', () => {
      // Fechas por defecto
      document.getElementById('fDate').value = hoyISO();
      document.getElementById('t-date').value = hoyISO();
      // Cargar íconos Lucide
      if (typeof lucide !== 'undefined') lucide.createIcons();
      // Renderizar todo
      renderAll();
      // Sincronizar automáticamente al inicio
      syncWithServer();
      // Evento para Enter en chat
      document.getElementById('chat-input').addEventListener('keydown', (e) => {
        if (e.key === 'Enter' && !e.shiftKey) {
          e.preventDefault();
          sendChat();
        }
      });
      // Evento para importar archivo
      document.getElementById('import-file').addEventListener('change', restoreBackup);
      // Mostrar estado de Vosk
      document.getElementById('vosk-status').textContent = 'No cargado (usa Chrome)';
    });

    // ======================================================
    // 14. EXPONER FUNCIONES GLOBALES (para onclick)
    // ======================================================
    window.switchTab = switchTab;
    window.sendChat = sendChat;
    window.clearChat = clearChat;
    window.changeModel = changeModel;
    window.guardarOrden = guardarOrden;
    window.registrarTurno = registrarTurno;
    window.procesarLote = procesarLote;
    window.copiarWSP = copiarWSP;
    window.borrarOrden = borrarOrden;
    window.borrarTurno = borrarTurno;
    window.filterOrders = filterOrders;
    window.syncWithServer = syncWithServer;
    window.exportFullBackup = exportFullBackup;
    window.restoreBackup = restoreBackup;
    window.clearAllLocal = clearAllLocal;
    window.toggleMic = toggleMic;
    window.cargarVosk = cargarVosk;
    window.hoyISO = hoyISO;
  </script>
</body>
</html>
'@

# Asegurar que el directorio client existe
if (-not (Test-Path $clientDir)) {
    New-Item -ItemType Directory -Path $clientDir -Force | Out-Null
}

# Guardar el archivo
$htmlContent | Out-File -FilePath (Join-Path $clientDir 'index.html') -Encoding utf8 -Force
Write-Host "  ✅ client/index.html creado correctamente" -ForegroundColor Green

# ================================================================
# 2. INICIAR EL SERVIDOR FASTIFY
# ================================================================
Write-Host "[RUNEFORGE] Iniciando servidor Fastify..." -ForegroundColor Cyan

# Cambiar al directorio daemon
Push-Location $daemonDir

# Verificar si node_modules existe, si no, instalar
$nodeModules = Join-Path $daemonDir 'node_modules'
if (-not (Test-Path $nodeModules)) {
    Write-Host "  ⚠️ node_modules no encontrado. Instalando dependencias..." -ForegroundColor Yellow
    if (Get-Command npm -ErrorAction SilentlyContinue) {
        npm install --silent
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  ❌ Error al instalar dependencias npm" -ForegroundColor Red
            Pop-Location
            exit 1
        }
    } else {
        Write-Host "  ❌ npm no encontrado. Instala Node.js." -ForegroundColor Red
        Pop-Location
        exit 1
    }
}

# Iniciar el servidor (en la misma ventana)
Write-Host "[RUNEFORGE] Servidor escuchando en http://0.0.0.0:3000" -ForegroundColor Green
Write-Host "[RUNEFORGE] Presiona Ctrl+C para detener." -ForegroundColor Yellow
Write-Host ""
node server.js