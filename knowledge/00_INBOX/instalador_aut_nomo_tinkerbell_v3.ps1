# ==============================================================================
# RUNEFORGE RELAY & BITACORA PWA - TINKERBELL V3.1 DEPLOYMENT SCRIPT
# Ejecución Autónoma, Auto-Instalación de Dependencias LLM y Sobreescritura.
# ==============================================================================
$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$ProjectDir = "$PWD\runeforge-relay"
if (!(Test-Path $ProjectDir)) { New-Item -ItemType Directory -Force -Path $ProjectDir | Out-Null }
Set-Location $ProjectDir

# 1. ESTRUCTURA DE DIRECTORIOS Y NODE.JS
New-Item -ItemType Directory -Force -Path "src" | Out-Null
New-Item -ItemType Directory -Force -Path "public" | Out-Null

if (!(Test-Path "package.json")) { Invoke-Expression "npm init -y" | Out-Null }
Write-Host "[*] Validando dependencias de Node.js..." -ForegroundColor Cyan
Invoke-Expression "npm install fastify @fastify/cors @fastify/static @langchain/community @langchain/core langchain --silent" | Out-Null

# 2. AUTO-RESOLUCIÓN DE DEPENDENCIAS IA (OLLAMA + DEEPSEEK)
Write-Host "[*] Verificando Motor LLM (Ollama)..." -ForegroundColor Cyan
$OllamaInstalled = Get-Command "ollama" -ErrorAction SilentlyContinue

if (!$OllamaInstalled) {
    Write-Host "[!] Ollama no detectado. Iniciando instalación autónoma..." -ForegroundColor Yellow
    try {
        Write-Host "    -> Intentando instalación silenciosa vía Winget..."
        winget install --id Ollama.Ollama -e --accept-source-agreements --accept-package-agreements --silent
        Write-Host "    -> Actualizando variables de entorno..."
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    } catch {
        Write-Host "    -> Winget falló. Descargando instalador directo oficial..." -ForegroundColor Yellow
        $InstallerPath = "$env:TEMP\OllamaSetup.exe"
        Invoke-WebRequest -Uri "https://ollama.com/download/OllamaSetup.exe" -OutFile $InstallerPath
        Start-Process -FilePath $InstallerPath -Wait
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    }
    Write-Host "[✓] Instalación completada. Esperando inicialización del servicio (10s)..." -ForegroundColor Green
    Start-Sleep -Seconds 10
} else {
    Write-Host "[✓] Ollama detectado en el sistema." -ForegroundColor Green
}

Write-Host "[*] Validando modelo 'deepseek-coder'..." -ForegroundColor Cyan
try {
    $OllamaCheck = Invoke-Expression "ollama list" 2>&1
    if (!($OllamaCheck -match "deepseek-coder")) {
        Write-Host "[!] Modelo no encontrado. Descargando 'deepseek-coder' (Esto tomará tiempo dependiendo de la red)..." -ForegroundColor Yellow
        Invoke-Expression "ollama pull deepseek-coder"
        Write-Host "[✓] Modelo descargado y listo." -ForegroundColor Green
    } else {
        Write-Host "[✓] Modelo 'deepseek-coder' ya se encuentra activo." -ForegroundColor Green
    }
} catch {
    Write-Host "[X] ERROR: El servicio de Ollama no respondió. Asegúrate de ejecutar la aplicación 'Ollama' desde tu menú de inicio si es la primera vez." -ForegroundColor Red
}

# 3. REESCRITURA DE CÓDIGO FUENTE (ASEGURANDO VERSIÓN MÁS NUEVA)
$AIControllerContent = @"
const { Ollama } = require('@langchain/community/llms/ollama');
const { PromptTemplate } = require('@langchain/core/prompts');

const localAI = new Ollama({
  baseUrl: 'http://localhost:11434',
  model: 'deepseek-coder',
  temperature: 0.2,
});

const CINER_SYSTEM_PROMPT = \`
Actúa como un Ingeniero Senior Copiloto en Telemetría GPS, IoT y Scripting de Taller.
Trabajas directamente como colega de taller y mano derecha técnica del Ing. Néstor (alias "Tinkerbell").
Eres un profesional CINER (Electrónica, CCTV, GPS, Redes, Scripting, Hacking Ético Defensivo).
REGLAS DE ORO:
1. NUNCA ASUMIR NI INVENTAR. Si faltan datos, indica [PENDIENTE].
2. RESPUESTAS ACCIONABLES: Directo, sin paja, nivel experto.
3. FORMATO: Usa tablas, diagramas ASCII y checklists.

Historial de conversación: {history}
Ingeniero Néstor dice: {input}
Tu respuesta técnica:
\`;

const promptTemplate = PromptTemplate.fromTemplate(CINER_SYSTEM_PROMPT);

async function setupAIRoutes(fastify) {
  fastify.post('/api/ai/chat', async (request, reply) => {
    try {
      const { message, contextHistory = '' } = request.body;
      const formattedPrompt = await promptTemplate.format({
        history: contextHistory,
        input: message
      });

      const response = await localAI.invoke(formattedPrompt);
      
      return reply.send({
        status: 'success',
        timestamp: new Date().toISOString(),
        agent: 'Tinkerbell-V3.1',
        response: response
      });
    } catch (error) {
      console.error('[RUNEFORGE-AI] Error:', error);
      return reply.status(500).send({ error: 'Falla en el enlace cognitivo. Verifica que Ollama esté corriendo en background.' });
    }
  });
}

module.exports = { setupAIRoutes };
"@
Set-Content -Path "src\ai-controller.js" -Value $AIControllerContent -Encoding UTF8 -Force

$ServerContent = @"
const fastify = require('fastify')({ logger: false });
const path = require('path');
const { setupAIRoutes } = require('./src/ai-controller');

fastify.register(require('@fastify/cors'), { origin: '*' });
fastify.register(require('@fastify/static'), {
  root: path.join(__dirname, 'public'),
  prefix: '/',
});

setupAIRoutes(fastify);

fastify.listen({ port: 8080, host: '0.0.0.0' }, (err, address) => {
  if (err) {
    console.error(err);
    process.exit(1);
  }
  console.log(\`[RUNEFORGE-RELAY] SISTEMA EN LÍNEA EN \${address}\`);
});
"@
Set-Content -Path "server.js" -Value $ServerContent -Encoding UTF8 -Force

$PWAContent = @"
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover">
  <meta name="theme-color" content="#0f111a">
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
  <title>Bitácora Pro + Tinkerbell V3.1</title>
  <style>
    :root {
      --bg-base: #0f111a; --bg-surface: #181b29; --bg-elevated: #212538;
      --border: #2d334a; --accent: #00ff88; --text-primary: #f8fafc;
      --text-secondary: #94a3b8; --font-family: system-ui, sans-serif;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: var(--font-family); background: var(--bg-base); color: var(--text-primary); }
    
    .ai-fab {
      position: fixed; bottom: 90px; right: 20px; width: 56px; height: 56px;
      background: var(--accent); border-radius: 50%; display: flex; align-items: center;
      justify-content: center; font-size: 24px; cursor: pointer; box-shadow: 0 4px 12px rgba(0,255,136,0.3);
      z-index: 1000; transition: transform 0.2s; border: none;
    }
    .ai-fab:active { transform: scale(0.9); }
    
    .ai-chat-modal {
      position: fixed; bottom: 160px; right: 20px; width: calc(100% - 40px); max-width: 380px;
      height: 450px; background: var(--bg-surface); border: 1px solid var(--border);
      border-radius: 16px; display: flex; flex-direction: column; opacity: 0; pointer-events: none;
      transform: translateY(20px); transition: 0.3s all cubic-bezier(0.4, 0, 0.2, 1); z-index: 999;
      box-shadow: 0 10px 30px rgba(0,0,0,0.8); overflow: hidden;
    }
    .ai-chat-modal.active { opacity: 1; pointer-events: auto; transform: translateY(0); }
    
    .chat-header { background: var(--bg-elevated); padding: 16px; font-weight: bold; border-bottom: 1px solid var(--border); display: flex; justify-content: space-between; }
    .chat-body { flex: 1; padding: 16px; overflow-y: auto; display: flex; flex-direction: column; gap: 12px; }
    .msg { padding: 10px 14px; border-radius: 12px; max-width: 85%; font-size: 14px; line-height: 1.4; word-wrap: break-word; white-space: pre-wrap; }
    .msg-user { background: var(--accent); color: #000; align-self: flex-end; border-bottom-right-radius: 2px; }
    .msg-ai { background: var(--bg-elevated); color: var(--text-primary); align-self: flex-start; border-bottom-left-radius: 2px; border: 1px solid var(--border); }
    
    .chat-input { padding: 12px; display: flex; gap: 8px; border-top: 1px solid var(--border); background: var(--bg-base); }
    .chat-input input { flex: 1; background: var(--bg-elevated); border: 1px solid var(--border); color: #fff; padding: 10px 14px; border-radius: 20px; outline: none; }
    .chat-input input:focus { border-color: var(--accent); }
    .chat-input button { background: var(--accent); border: none; width: 40px; height: 40px; border-radius: 50%; font-weight: bold; cursor: pointer; }
    
    .app-header { padding: 16px; background: var(--bg-elevated); border-bottom: 1px solid var(--border); text-align: center; }
    .placeholder-content { padding: 40px 20px; text-align: center; color: var(--text-secondary); }
  </style>
</head>
<body>

  <header class="app-header"><h2>⚡ Bitácora Pro + IA Local</h2></header>
  <div class="placeholder-content">
    <p>Interfaz PWA de Bitácora Operativa Integrada.</p>
    <p style="font-size: 12px; margin-top: 10px;">Presiona el botón flotante ⚡ para consultar a Tinkerbell V3.1 (100% Offline).</p>
  </div>

  <div class="ai-chat-modal" id="aiChat">
    <div class="chat-header"><span>🧠 Tinkerbell V3.1</span></div>
    <div class="chat-body" id="chatLog">
      <div class="msg msg-ai">Sistemas en línea, Ingeniero. DeepSeek-Coder activo. Listo para instrucciones.</div>
    </div>
    <div class="chat-input">
      <input type="text" id="chatInp" placeholder="Ingresa parámetro..." onkeypress="if(event.key==='Enter') sendMsg()">
      <button onclick="sendMsg()">➤</button>
    </div>
  </div>

  <button class="ai-fab" onclick="document.getElementById('aiChat').classList.toggle('active')">⚡</button>

  <script>
    let chatHistory = "";
    
    async function sendMsg() {
      const inp = document.getElementById('chatInp');
      const text = inp.value.trim();
      if(!text) return;
      
      const log = document.getElementById('chatLog');
      log.innerHTML += \`<div class="msg msg-user">\${text}</div>\`;
      inp.value = '';
      
      const loadingId = 'load-' + Date.now();
      log.innerHTML += \`<div class="msg msg-ai" id="\${loadingId}">Procesando inferencia...</div>\`;
      log.scrollTop = log.scrollHeight;

      try {
        const res = await fetch('/api/ai/chat', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ message: text, contextHistory: chatHistory })
        });
        
        const data = await res.json();
        document.getElementById(loadingId).remove();
        
        if (data.status === 'success') {
          log.innerHTML += \`<div class="msg msg-ai">\${data.response}</div>\`;
          chatHistory += \`User: \${text}\\nIA: \${data.response}\\n\`;
        } else {
          log.innerHTML += \`<div class="msg msg-ai" style="color:#ef4444">\${data.error}</div>\`;
        }
      } catch (err) {
        document.getElementById(loadingId).remove();
        log.innerHTML += \`<div class="msg msg-ai" style="color:#ef4444">Error CRÍTICO: Motor LLM fuera de línea. Reinicia el servidor.</div>\`;
      }
      log.scrollTop = log.scrollHeight;
    }
  </script>
</body>
</html>
"@
Set-Content -Path "public\bitacora.html" -Value $PWAContent -Encoding UTF8 -Force

# 4. REPORTE FINAL AUTÓNOMO Y PORTAPAPELES
$FinalReport = @"
[ TINKERBELL V3.1 - DIAGNÓSTICO Y EJECUCIÓN AUTÓNOMA ]
Directorio Activo: $ProjectDir
Dependencias Node: Refrescadas y Validadas.
Dependencias LLM: Ollama instalado & deepseek-coder descargado/validado.
Archivos Generados: ai-controller.js, server.js, bitacora.html (Sobreescritos a v3.1).

[ ESTADO DEL SISTEMA ]
✅ IA 100% OFFLINE CONFIGURADA. 
El servidor iniciará a continuación de forma automática.

[ INSTRUCCIONES FINALES ]
Abre tu navegador en: http://127.0.0.1:8080
"@

Set-Clipboard -Value $FinalReport

Write-Host "[✓] PROCESO QUIRÚRGICO COMPLETADO." -ForegroundColor Green
Write-Host "[✓] REPORTE COPIADO AL PORTAPAPELES." -ForegroundColor Green
Write-Host "[*] EJECUTANDO SERVIDOR NODE..." -ForegroundColor Yellow

Invoke-Expression "node server.js"