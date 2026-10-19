# bootstrap_etapa1.ps1 - RUNEFORGE V2.6.2 VERDE+LLM
# Uso: pwsh -ExecutionPolicy Bypass -File .\scripts\bootstrap_etapa1.ps1
# Este script NO debe pegarse linea por linea en consola, ejecutalo como archivo para evitar bug PSReadLine

$ErrorActionPreference="Stop"
Remove-Module PSReadLine -ErrorAction SilentlyContinue

$root = $PSScriptRoot
if(-not $root){ $root = (Get-Location).Path }
# Si esta en scripts/, subir un nivel
if($root -like "*\scripts"){ $root = Split-Path $root -Parent }
Set-Location $root
Write-Host "ROOT: $root" -ForegroundColor Cyan

function Write-Utf8NoBom {
  param([string]$Path, [string]$Content)
  $dir = Split-Path $Path -Parent
  if($dir -and !(Test-Path $dir)){ New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  $utf8NoBom = New-Object System.Text.UTF8Encoding $false
  [System.IO.File]::WriteAllText((Join-Path $root $Path), $Content, $utf8NoBom)
  Write-Host "  wrote $Path" -ForegroundColor Green
}

# --- Directorios Etapa 1 ---
$dirs = @(
  "config",
  "data\raw\bitacoras",
  "data\processed",
  "data\commander",
  "data\traces",
  "knowledge\00_INBOX\whatsapp_raw",
  "knowledge\03_AUDITS",
  "knowledge\graph",
  "knowledge\memoria-ia\00_raw_imports",
  "docs\jugo\inventario",
  "docs\prompts",
  "infra\headscale\config",
  "public\forge\swarm\pages",
  "src\backend\services\llm\adapters",
  "src\relay",
  "logs",
  "scripts"
)
foreach($d in $dirs){ New-Item -ItemType Directory -Force -Path $d | Out-Null }

# --- AGENTS.md ---
Write-Utf8NoBom "AGENTS.md" @'
# AGENTS.md - Contexto para Agentes IA - Runeforge v2.6.2 VERDE+LLM

## 0. Identidad
Runeforge es un ecosistema local-first, soberania digital, 100% offline-first, bajo consumo, modular y auto-reparable.
Centro de operaciones digital personal para telemetria (CINER), bitacoras, analisis de problemas y habitos personales.
Stack: Fastify + PWA Vanilla + Ollama + SQLite WAL + Tailscale/Headscale + n8n.

## 1. Stack Real Verificado (Ryzen 3 3200G / 16GB / GTX 1660 SUPER 6GB / Win10 19045)
- Backend: Fastify 5.x ~77k req/s, Node 20+, PM2 relay (46MB) + backend (52MB)
- Frontend: PWA Vanilla JS 10 pestanas (forge, mission-control, pwa, acceso, deepseek, infograma, roadmap, chat, docs), quota 76.8GB IndexedDB (60% disco PWA instalada)
- LLM: Ollama http://127.0.0.1:11434, modelos qwen2.5:1.5b 986MB, gemma2:2b 1.6GB, nomic-embed-text 274MB, deepseek-coder 776MB, total 3.6GB, keep_alive 10m, MAX=1
- DB: SQLite WAL (readers no bloquean writers, autocheckpoint 1000)
- Mesh: Tailscale 1.102.2 / 1.103.0-dev, tailnet tail12b297.ts.net, 2 nodos: desktop-ndfe0b0 100.83.105.117, runeforge 100.100.167.48, key_expiry 2027-02-11, DERP + STUN 3478/udp
- n8n: cloud forgerrune.app.n8n.cloud (vacio) -> objetivo local n8n+Ollama+Postgres+Qdrant en runeforge
- Endpoints: http://localhost:3100/dashboard, /forge, /api/ollama/status, /api/chat POST {message}, Ollama nativo :11434

## 2. Estructura de Carpetas (C:\RUNEFORGE_V2_CORE)
```
config/ -> llm-profiles.json, arquitectura/
data/commander, processed, raw/bitacoras, traces, raw/whatsapp
docs/jugo/inventario, prompts, ROADMAP.md
infra/headscale/config/data
knowledge/00_INBOX/whatsapp_raw/, 03_AUDITS/, graph/, memoria-ia/00_raw_imports/01_normalized/PROJECTS/02_rules/03_logs/
public/forge/swarm/pages
src/backend/services/llm/BaseProvider.js, adapters/ollama.js, factory.js
src/relay/
logs/
.env.template (plantilla)
```

## 3. Comandos de Agente (PowerShell 7.6.3)
```
# Validar nucleo
pm2 list
Invoke-RestMethod http://localhost:3100/api/ollama/status -TimeoutSec 5
ollama list; ollama ps
Get-ChildItem data\raw\bitacoras | Measure-Object

# Launcher
.\runeforge_launcher.ps1
.\scripts\bootstrap_etapa1.ps1
.\organize_downloads.ps1

# Benchmark honesto
ollama run qwen2.5:1.5b "test"
# esperado real ~26-30 tok/s en 3B Q4 en GTX 1660, no 110.80 tok/s sin verificar

# Tailscale
tailscale status; tailscale ip
tailscale set --ssh
tailscale serve --bg --https=443 http://localhost:3100

# n8n local (cuando exista)
docker compose -f infra\docker-compose.yml up -d
```

## 4. Reglas para Agentes IA
1. Local-First siempre: no subir telemetria Ciner a cloud sin consentimiento. Prototipar en nube permitido solo si es efimero y con backup local desde dia 1.
2. Backup desde Etapa 1: todo dato capturado tiene backup diario 02:00 a C:\RUNEFORGE_BACKUPS\bitacoras_YYYYMMDD.csv + SQLite WAL checkpoint. Nunca Etapa 4.
3. Doble via de captura: Telegram Bot (primaria, 30s setup) + Form n8n (backup). WhatsApp con Evolution API local solo en Etapa 3, nunca Business Cloud en Etapa 1 (trampa tiempo).
4. Parseo robusto: prefijos T_telemetria, P_problema, A_actividad, H_habito, R_tarea. Si confidence baja -> responder "No entendi, es T/P/H/A/R? Ej: 'P Ciner sensor km 42 fallo'". Guardar texto_original siempre, nunca perder entrada.
5. Higiene datos: tabla bitacoras_v2 con fecha, tipo, proyecto, texto_original, texto_limpio, estado[pendiente,en_progreso,resuelto,hecho,archivado], origen, parse_confidence[alta,media,baja], correccion_de. Deduplicar por hash texto+fecha.
6. Trabajo vs Personal: misma tabla, vistas distintas. Ciner requiere export mensual CSV/Excel y retencion 2 anos. Personal retencion 1 ano, sin export.
7. Numeros honestos: reportar benchmark medido en tu hardware, no 77k req/s de Fastify hello-world como si fuera tu backend con Ollama. Marcar aspiracional vs medido.
8. No sobre-ingenieria: CRDT Automerge/Yjs y Headscale auto-hospedado congelados hasta que Etapa 1 tenga 7 dias uso real sin fallar. Pregunta filtro: "que se rompe si lo quito hoy?"
9. .env nunca en repo. Usar .env.template. Expandir ${VAR:-default}.
10. Factory LLM: usar src/backend/services/llm/factory.js createProvider('ollama') -> lee config/llm-profiles.json y expande env. No hardcodear URLs.

## 5. Perfiles LLM (config/llm-profiles.json)
- ollama: local, baseUrl ${OLLAMA_BASE_URL}, modelos fast=qwen2.5:1.5b, chat=gemma2:2b, code=deepseek-coder, embed=nomic-embed-text, keep_alive 10m, MAX=1
- deepseek: cloud opcional, apiKey ${DEEPSEEK_API_KEY}
- gemini: cloud opcional, apiKey ${GEMINI_API_KEY}, modelo gemini-1.5-flash
- meta: whatsapp business opcional, token ${META_WA_TOKEN}
Default: ollama.

## 6. Objetivo Real del Usuario
"Runeforge me sirve para llevar orden en mi trabajo de telemetria (bitacoras, analisis de problemas, reforma de actividades) y en lo personal para seguir habitos, rutinas y planeacion de proyectos personales."
Motor: capturar -> guardar estructurado -> recuperar/resumir. Todo es fecha+tipo+proyecto+texto+estado.

## 7. Definicion de Terminado Etapa 1 v2
- 2 vias captura funcionando (Telegram + Form) sin punto unico fallo
- Data Table bitacoras_v2 con manejo "no entendi" y parse_confidence
- Backup diario desde dia 1
- Re-benchmark Ollama en GTX 1660 SUPER documentado
- Uso 3 dias seguidos sin fallar

## 8. Anti-patrones Prohibidos
- Un solo canal de captura (WhatsApp solo)
- Guardar basura silenciosa por parseo fallido
- Datos sin backup 3 etapas
- Usar Ollama en Etapa 2 sin validar en Etapa 1
- WhatsApp Business Cloud en Etapa 1
- node_modules en backups zips
- Duplicar knowledge/RUNEFORGE_KNOWLEDGE dentro de knowledge/

'@

# --- .env.template ---
Write-Utf8NoBom ".env.template" @'
# RUNEFORGE -.env.template - Copiar a .env y completar
# .env real

# === CORE ===
NODE_ENV=development
PORT=3100
HOST=0.0.0.0
FASTIFY_LOG_LEVEL=info
PM2_INSTANCES=1

# === LLM LOCAL - Ollama (prioridad 1) ===
OLLAMA_BASE_URL=http://127.0.0.1:11434
OLLAMA_KEEP_ALIVE=10m
OLLAMA_MAX_CONCURRENT=1
OLLAMA_MODEL_FAST=qwen2.5:1.5b
OLLAMA_MODEL_CHAT=gemma2:2b
OLLAMA_MODEL_CODE=deepseek-coder
OLLAMA_MODEL_EMBED=nomic-embed-text
OLLAMA_MODEL_VISION=llava:7b

# === LLM CLOUD OPCIONAL (Etapa 2+, deshabilitados por defecto) ===
DEEPSEEK_API_KEY=
DEEPSEEK_BASE_URL=https://api.deepseek.com
GEMINI_API_KEY=
GEMINI_BASE_URL=https://generativelanguage.googleapis.com

# === WHATSAPP / META (Solo Etapa 3 con Evolution API local) ===
META_WA_TOKEN=
META_WA_PHONE_NUMBER_ID=
META_WA_BUSINESS_ID=
META_WA_BASE_URL=https://graph.facebook.com/v20.0
EVOLUTION_API_URL=http://localhost:8081
EVOLUTION_API_KEY=

# === TELEGRAM (Etapa 1 - via primaria recomendada) ===
TELEGRAM_BOT_TOKEN=
TELEGRAM_CHAT_ID=
TELEGRAM_WEBHOOK_URL=https://forgerrune.app.n8n.cloud/webhook/telegram

# === N8N ===
N8N_BASE_URL=https://forgerrune.app.n8n.cloud
N8N_WEBHOOK_BASE=https://forgerrune.app.n8n.cloud/webhook
N8N_API_KEY=
N8N_LOCAL_URL=http://localhost:5678
N8N_ENCRYPTION_KEY=

# === TAILSCALE / HEADSCALE ===
TAILSCALE_TAILNET=tail12b297.ts.net
TAILSCALE_AUTHKEY=
HEADSCALE_URL=http://localhost:8080
HEADSCALE_API_KEY=
HEADSCALE_DOMAIN=runeforge.tail12b297.ts.net
DERP_ENABLED=true

# === DATABASE ===
SQLITE_PATH=./data/runeforge.db
SQLITE_WAL=true
SQLITE_AUTOCHECKPOINT=1000
POSTGRES_URL=postgresql://n8n:n8n@localhost:5432/n8n
QDRANT_URL=http://localhost:6333

# === BACKUP (Desde Etapa 1, no Etapa 4) ===
BACKUP_ENABLED=true
BACKUP_CRON=0 2 * * *
BACKUP_DIR=C:\RUNEFORGE_BACKUPS\bitacoras
BACKUP_RETENTION_DAYS=90
BACKUP_GDRIVE_ENABLED=false
BACKUP_GDRIVE_FOLDER_ID=

# === TELEMETRIA CINER (Trabajo) ===
CINER_PROJECT=Ciner
CINER_RETENTION_DAYS=730
PERSONAL_RETENTION_DAYS=365

# === PWA ===
PWA_QUOTA_TARGET=60
PWA_PERSIST=true
VITE_API_URL=http://localhost:3100

# === AWS (Opcional, solo si usas nodo runeforge) ===
AWS_REGION=us-east-2
AWS_AGENT_TOOLKIT_REGION=us-east-1
AWS_EC2_INSTANCE_ID=

'@

# --- config/llm-profiles.json ---
Write-Utf8NoBom "config\llm-profiles.json" @'
{
  "defaultProvider": "ollama",
  "version": "2.0",
  "profiles": {
    "ollama": {
      "type": "ollama",
      "enabled": true,
      "baseUrl": "${OLLAMA_BASE_URL:-http://127.0.0.1:11434}",
      "keepAlive": "${OLLAMA_KEEP_ALIVE:-10m}",
      "timeoutMs": 120000,
      "maxConcurrent": 1,
      "models": {
        "fast": "${OLLAMA_MODEL_FAST:-qwen2.5:1.5b}",
        "chat": "${OLLAMA_MODEL_CHAT:-gemma2:2b}",
        "code": "${OLLAMA_MODEL_CODE:-deepseek-coder}",
        "embed": "${OLLAMA_MODEL_EMBED:-nomic-embed-text}",
        "vision": "${OLLAMA_MODEL_VISION:-llava:7b}"
      },
      "options": {
        "temperature": 0.7,
        "top_p": 0.9,
        "num_ctx": 4096,
        "num_predict": 1024
      },
      "notes": "Local-first, MAX=1 para evitar OOM thrashing 15-22s en 6GB VRAM, VRAM ~2768/6144"
    },
    "deepseek": {
      "type": "openai-compatible",
      "enabled": false,
      "baseUrl": "${DEEPSEEK_BASE_URL:-https://api.deepseek.com}",
      "apiKey": "${DEEPSEEK_API_KEY}",
      "models": {
        "chat": "deepseek-chat",
        "code": "deepseek-coder",
        "reasoner": "deepseek-reasoner"
      },
      "options": {
        "temperature": 0.7
      }
    },
    "gemini": {
      "type": "gemini",
      "enabled": false,
      "baseUrl": "${GEMINI_BASE_URL:-https://generativelanguage.googleapis.com}",
      "apiKey": "${GEMINI_API_KEY}",
      "models": {
        "fast": "gemini-1.5-flash",
        "pro": "gemini-1.5-pro",
        "embed": "text-embedding-004"
      },
      "options": {
        "temperature": 0.7
      }
    },
    "meta": {
      "type": "meta-whatsapp",
      "enabled": false,
      "baseUrl": "${META_WA_BASE_URL:-https://graph.facebook.com/v20.0}",
      "phoneNumberId": "${META_WA_PHONE_NUMBER_ID}",
      "apiKey": "${META_WA_TOKEN}",
      "businessAccountId": "${META_WA_BUSINESS_ID}",
      "notes": "Solo Etapa 3 con Evolution API local. Etapa 1 usar Telegram/Form para evitar trampa tiempo Meta"
    }
  },
  "routing": {
    "telemetria": "ollama:fast",
    "bitacora": "ollama:chat",
    "problema": "ollama:chat",
    "habito": "ollama:fast",
    "codigo": "ollama:code",
    "embedding": "ollama:embed",
    "fallback": "ollama:fast"
  },
  "benchmarks": {
    "expected": {
      "gtx1660Super_6GB_q4": {
        "qwen2.5_1.5b": "28-32 tok/s",
        "qwen2.5_3b": "26.28 tok/s",
        "deepseek-r1_1.5b": "30.16 tok/s",
        "gemma2_2b": "26-28 tok/s"
      },
      "fastify_bare": "41,779 req/s",
      "fastify_optimized": "77,193 req/s"
    },
    "honestyRule": "Reportar medido en tu hardware, no oficial hello-world como propio"
  }
}
'@

# --- src/backend/services/llm/BaseProvider.js ---
Write-Utf8NoBom "src\backend\services\llm\BaseProvider.js" @'
class BaseProvider {
  constructor(profile = {}) {
    this.profile = profile;
    this.type = profile.type || 'unknown';
    this.enabled = profile.enabled !== false;
    this.baseUrl = this._expand(profile.baseUrl || '');
    this.timeoutMs = profile.timeoutMs || 120000;
    this.models = profile.models || {};
    this.options = profile.options || {};
  }

  _expand(value) {
    if (typeof value !== 'string') return value;
    return value.replace(/\$\{([^}:]+)(?::-([^}]*))?\}/g, (_, key, def) => {
      const env = process.env[key];
      if (env !== undefined && env !== '') return env;
      return def !== undefined ? def : '';
    });
  }

  _getModel(aliasOrName) {
    if (!aliasOrName) return this.models.fast || this.models.chat || Object.values(this.models)[0];
    if (this.models[aliasOrName]) return this.models[aliasOrName];
    return aliasOrName;
  }

  async chat({ messages, model, stream = false, options = {} } = {}) {
    throw new Error(`${this.type}.chat() not implemented`);
  }

  async embed({ input, model } = {}) {
    throw new Error(`${this.type}.embed() not implemented`);
  }

  async status() {
    return { ok: this.enabled, type: this.type, baseUrl: this.baseUrl, models: this.models };
  }

  async listModels() {
    const s = await this.status();
    return Object.values(s.models || this.models);
  }

  _buildHeaders(extra = {}) {
    return { 'Content-Type': 'application/json', ...extra };
  }

  async _fetchWithTimeout(url, opts = {}) {
    const controller = new AbortController();
    const t = setTimeout(() => controller.abort(), this.timeoutMs);
    try {
      const res = await fetch(url, { ...opts, signal: controller.signal });
      return res;
    } finally {
      clearTimeout(t);
    }
  }
}

module.exports = BaseProvider;

'@

# --- src/backend/services/llm/adapters/ollama.js ---
Write-Utf8NoBom "src\backend\services\llm\adapters\ollama.js" @'
const BaseProvider = require('../BaseProvider');

class OllamaProvider extends BaseProvider {
  constructor(profile = {}) {
    super(profile);
    this.type = 'ollama';
    this.baseUrl = this._expand(profile.baseUrl || process.env.OLLAMA_BASE_URL || 'http://127.0.0.1:11434');
    this.keepAlive = this._expand(profile.keepAlive || process.env.OLLAMA_KEEP_ALIVE || '10m');
  }

  async status() {
    try {
      const res = await this._fetchWithTimeout(`${this.baseUrl}/api/tags`, { method: 'GET' });
      if (!res.ok) return { ok: false, type: this.type, error: `HTTP ${res.status}`, baseUrl: this.baseUrl };
      const data = await res.json();
      const count = (data.models || []).length;
      return { ok: true, type: this.type, baseUrl: this.baseUrl, count, models: data.models, profileModels: this.models };
    } catch (e) {
      return { ok: false, type: this.type, baseUrl: this.baseUrl, error: e.message };
    }
  }

  async listModels() {
    const s = await this.status();
    return s.models || [];
  }

  async chat({ messages, model, stream = false, options = {} } = {}) {
    const modelName = this._getModel(model);
    const body = {
      model: modelName,
      messages: messages || [{ role: 'user', content: 'ping' }],
      stream: !!stream,
      keep_alive: this.keepAlive,
      options: { ...this.options, ...options }
    };
    const res = await this._fetchWithTimeout(`${this.baseUrl}/api/chat`, {
      method: 'POST',
      headers: this._buildHeaders(),
      body: JSON.stringify(body)
    });
    if (!res.ok) {
      const txt = await res.text().catch(() => '');
      throw new Error(`Ollama chat failed ${res.status}: ${txt}`);
    }
    if (stream) return res;
    const data = await res.json();
    return {
      role: data.message?.role || 'assistant',
      content: data.message?.content || '',
      model: data.model || modelName,
      raw: data,
      eval_count: data.eval_count,
      eval_duration: data.eval_duration
    };
  }

  async embed({ input, model } = {}) {
    const modelName = this._getModel(model || 'embed');
    const body = {
      model: modelName,
      input: Array.isArray(input) ? input.join('\n') : String(input || ''),
      keep_alive: this.keepAlive
    };
    const res = await this._fetchWithTimeout(`${this.baseUrl}/api/embed`, {
      method: 'POST',
      headers: this._buildHeaders(),
      body: JSON.stringify(body)
    });
    if (!res.ok) {
      const txt = await res.text().catch(() => '');
      throw new Error(`Ollama embed failed ${res.status}: ${txt}`);
    }
    const data = await res.json();
    return { embedding: data.embeddings?.[0] || data.embedding, model: modelName, raw: data };
  }

  async generate({ prompt, model, options = {} } = {}) {
    const modelName = this._getModel(model);
    const body = {
      model: modelName,
      prompt: String(prompt || ''),
      stream: false,
      keep_alive: this.keepAlive,
      options: { ...this.options, ...options }
    };
    const res = await this._fetchWithTimeout(`${this.baseUrl}/api/generate`, {
      method: 'POST',
      headers: this._buildHeaders(),
      body: JSON.stringify(body)
    });
    if (!res.ok) {
      const txt = await res.text().catch(() => '');
      throw new Error(`Ollama generate failed ${res.status}: ${txt}`);
    }
    const data = await res.json();
    return { content: data.response || '', model: data.model || modelName, raw: data };
  }
}

module.exports = OllamaProvider;

'@

# --- src/backend/services/llm/factory.js ---
Write-Utf8NoBom "src\backend\services\llm\factory.js" @'
const fs = require('fs');
const path = require('path');
const BaseProvider = require('./BaseProvider');
const OllamaProvider = require('./adapters/ollama');

function expandEnvVars(value) {
  if (typeof value === 'string') {
    return value.replace(/\$\{([^}:]+)(?::-([^}]*))?\}/g, (_, key, def) => {
      const env = process.env[key];
      if (env !== undefined && env !== '') return env;
      return def !== undefined ? def : '';
    });
  }
  if (Array.isArray(value)) return value.map(expandEnvVars);
  if (value && typeof value === 'object') {
    const out = {};
    for (const [k, v] of Object.entries(value)) out[k] = expandEnvVars(v);
    return out;
  }
  return value;
}

function loadEnvFile(envPath) {
  try {
    if (!fs.existsSync(envPath)) return;
    const content = fs.readFileSync(envPath, 'utf8');
    for (const line of content.split(/\r?\n/)) {
      const trimmed = line.trim();
      if (!trimmed || trimmed.startsWith('#')) continue;
      const eq = trimmed.indexOf('=');
      if (eq === -1) continue;
      const key = trimmed.slice(0, eq).trim();
      let val = trimmed.slice(eq + 1).trim();
      if ((val.startsWith('"') && val.endsWith('"')) || (val.startsWith("'") && val.endsWith("'"))) {
        val = val.slice(1, -1);
      }
      if (process.env[key] === undefined) process.env[key] = val;
    }
  } catch (_) {}
}

function loadProfiles(profilesPath) {
  const candidates = [
    profilesPath,
    path.join(process.cwd(), 'config', 'llm-profiles.json'),
    path.join(__dirname, '..', '..', '..', '..', 'config', 'llm-profiles.json'),
    path.join(__dirname, '..', '..', 'config', 'llm-profiles.json'),
    path.join(__dirname, '../../../config/llm-profiles.json')
  ].filter(Boolean);

  let raw = null;
  let usedPath = null;
  for (const p of candidates) {
    try {
      if (p && fs.existsSync(p)) {
        raw = fs.readFileSync(p, 'utf8');
        usedPath = p;
        break;
      }
    } catch (_) {}
  }
  if (!raw) {
    return {
      defaultProvider: 'ollama',
      profiles: {
        ollama: {
          type: 'ollama',
          enabled: true,
          baseUrl: '${OLLAMA_BASE_URL:-http://127.0.0.1:11434}',
          keepAlive: '10m',
          models: { fast: 'qwen2.5:1.5b', chat: 'gemma2:2b', code: 'deepseek-coder', embed: 'nomic-embed-text' }
        }
      }
    };
  }
  try {
    // strip BOM
    if (raw.charCodeAt(0) === 0xFEFF) raw = raw.slice(1);
    const parsed = JSON.parse(raw);
    return expandEnvVars(parsed);
  } catch (e) {
    throw new Error(`Failed to parse llm-profiles.json at ${usedPath}: ${e.message}`);
  }
}

function resolveProviderType(type) {
  const map = {
    'ollama': OllamaProvider,
    'openai-compatible': BaseProvider,
    'gemini': BaseProvider,
    'meta-whatsapp': BaseProvider
  };
  return map[type] || BaseProvider;
}

function createProvider(nameOrAlias, overrides = {}) {
  loadEnvFile(path.join(process.cwd(), '.env'));
  loadEnvFile(path.join(process.cwd(), 'config', '.env'));

  const all = loadProfiles(overrides.profilesPath);
  const profiles = all.profiles || {};
  const routing = all.routing || {};

  let providerKey = nameOrAlias;
  let modelAlias = null;

  if (nameOrAlias && nameOrAlias.includes(':')) {
    const parts = nameOrAlias.split(':');
    providerKey = parts[0];
    modelAlias = parts[1];
  }

  if (routing[providerKey]) {
    const routed = routing[providerKey];
    if (routed.includes(':')) {
      const [rk, rm] = routed.split(':');
      providerKey = rk;
      modelAlias = modelAlias || rm;
    } else {
      providerKey = routed;
    }
  }

  if (!providerKey) providerKey = all.defaultProvider || 'ollama';

  let profile = profiles[providerKey];
  if (!profile) {
    const fallbackKey = all.defaultProvider || 'ollama';
    profile = profiles[fallbackKey];
    providerKey = fallbackKey;
  }
  if (!profile) throw new Error(`Provider profile not found: ${nameOrAlias}`);

  const merged = expandEnvVars({ ...profile, ...overrides, models: { ...(profile.models || {}), ...(overrides.models || {}) } });

  if (modelAlias && merged.models && merged.models[modelAlias]) {
    merged._selectedModel = merged.models[modelAlias];
    merged._selectedModelAlias = modelAlias;
  } else if (modelAlias) {
    merged._selectedModel = modelAlias;
    merged._selectedModelAlias = modelAlias;
  }

  const ProviderClass = resolveProviderType(merged.type);
  const instance = new ProviderClass(merged);

  if (merged.type === 'ollama') {
    return instance;
  }

  if (merged.enabled === false) {
    const ollamaFallback = profiles['ollama'] || profiles[all.defaultProvider];
    if (ollamaFallback) {
      return new OllamaProvider(expandEnvVars(ollamaFallback));
    }
  }

  return instance;
}

function createProviderFromEnv() {
  return createProvider(process.env.LLM_PROVIDER || process.env.DEFAULT_LLM || 'ollama');
}

module.exports = { loadProfiles, createProvider, createProviderFromEnv, expandEnvVars };

'@

# --- Validaciones ---
Write-Host "`n=== Validando ===" -ForegroundColor Yellow
try {
  $json = Get-Content (Join-Path $root "config\llm-profiles.json") -Raw | ConvertFrom-Json
  Write-Host "JSON OK: defaultProvider=$($json.defaultProvider)" -ForegroundColor Green
} catch {
  Write-Host "JSON FAIL: $($_.Exception.Message)" -ForegroundColor Red
}

try {
  node -e "const f=require('./src/backend/services/llm/factory.js'); const p=f.createProvider('ollama'); console.log('factory cargado'); p.status().then(r=>{console.log('ollama status:', JSON.stringify(r).substring(0,200))}).catch(e=>console.log('ollama no corre:', e.message))"
} catch {
  Write-Host "Node check fallo (normal si ollama no esta corriendo): $_" -ForegroundColor DarkYellow
}

Write-Host "`nBootstrap Etapa 1 completado. Siguiente: .\runeforge_launcher.ps1" -ForegroundColor Cyan
