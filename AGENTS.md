# AGENTS.md — Contexto para Agentes IA — Runeforge v2.6.2 VERDE+LLM + Obsidian
## 0. Identidad
Runeforge es un ecosistema local-first, soberanía digital, 100% offline-first, bajo consumo, modular y auto-reparable.
Centro de operaciones digital personal para telemetría (CINER), bitácoras, análisis de problemas y hábitos personales.
Stack: Fastify + PWA Vanilla + Ollama + SQLite WAL + Tailscale/Headscale + n8n + Obsidian (gestión de conocimiento).
## 1. Stack Real Verificado (Ryzen 3 3200G / 16GB / GTX 1660 SUPER 6GB / Win10 19045)
- Backend: Fastify 5.x ~77k req/s, Node 20+, PM2 relay (46MB) + backend (52MB)
- Frontend: PWA Vanilla JS 10 pestañas (forge, mission-control, pwa, acceso, deepseek, infograma, roadmap, chat, docs), quota 76.8GB IndexedDB (60% disco PWA instalada)
- LLM: Ollama http://127.0.0.1:11434, modelos qwen2.5:1.5b 986MB, gemma2:2b 1.6GB, nomic-embed-text 274MB, deepseek-coder 776MB, total 3.6GB, keep_alive 10m, MAX=1
- DB: SQLite WAL (readers no bloquean writers, autocheckpoint 1000)
- Mesh: Tailscale 1.102.2 / 1.103.0-dev, tailnet tail12b297.ts.net, 2 nodos: desktop-ndfe0b0 100.83.105.117, runeforge 100.100.167.48, key_expiry 2027-02-11, DERP + STUN 3478/udp
- n8n: cloud forgerrune.app.n8n.cloud (vacío) -> objetivo local n8n+Ollama+Postgres+Qdrant en runeforge
- Obsidian: Vault local en `C:\RUNEFORGE_OBSIDIAN` (o ruta configurable), con plugin Web Clipper para ingesta de conocimiento técnico.
- Endpoints: http://localhost:3100/dashboard, /forge, /api/ollama/status, /api/chat POST {message}, Ollama nativo :11434
## 2. Estructura de Carpetas (C:\RUNEFORGE_V2_CORE)
```
config/
  llm-profiles.json
  obsidian/
    obsidian-web-clipper-settings.json   # Configuración mejorada para Web Clipper
data/commander, processed, raw/bitacoras, traces, raw/whatsapp
docs/jugo/inventario, prompts, ROADMAP.md
infra/headscale/config/data
knowledge/00_INBOX/whatsapp_raw/, 03_AUDITS/, graph/, memoria-ia/00_raw_imports/01_normalized/PROJECTS/02_rules/03_logs/
public/forge/swarm/pages
src/backend/services/llm/BaseProvider.js, adapters/ollama.js, factory.js
src/relay/
logs/
.env.template (plantilla)
scripts/bootstrap_etapa1.ps1
runeforge_launcher.ps1
```
## 3. Comandos de Agente (PowerShell 7.6.3)
```
# Validar núcleo
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
# Sincronizar clippings de Obsidian con Runeforge
# (los archivos se guardan en el vault de Obsidian, se pueden procesar con scripts)
```
## 4. Reglas para Agentes IA
1. Local-First siempre: no subir telemetría Ciner a cloud sin consentimiento. Prototipar en nube permitido solo si es efímero y con backup local desde día 1.
2. Backup desde Etapa 1: todo dato capturado tiene backup diario 02:00 a C:\RUNEFORGE_BACKUPS\bitacoras_YYYYMMDD.csv + SQLite WAL checkpoint. Nunca Etapa 4.
3. Doble vía de captura: Telegram Bot (primaria, 30s setup) + Form n8n (backup). WhatsApp con Evolution API local solo en Etapa 3, nunca Business Cloud en Etapa 1 (trampa tiempo).
4. Parseo robusto: prefijos T_telemetria, P_problema, A_actividad, H_habito, R_tarea. Si confidence baja -> responder "No entendí, ¿es T/P/H/A/R? Ej: 'P Ciner sensor km 42 falló'". Guardar texto_original siempre, nunca perder entrada.
5. Higiene datos: tabla bitacoras_v2 con fecha, tipo, proyecto, texto_original, texto_limpio, estado[pendiente,en_progreso,resuelto,hecho,archivado], origen, parse_confidence[alta,media,baja], correccion_de. Deduplicar por hash texto+fecha.
6. Trabajo vs Personal: misma tabla, vistas distintas. Ciner requiere export mensual CSV/Excel y retención 2 años. Personal retención 1 año, sin export.
7. Números honestos: reportar benchmark medido en tu hardware, no 77k req/s de Fastify hello-world como si fuera tu backend con Ollama. Marcar aspiracional vs medido.
8. No sobre-ingeniería: CRDT Automerge/Yjs y Headscale auto-hospedado congelados hasta que Etapa 1 tenga 7 días uso real sin fallar. Pregunta filtro: "¿qué se rompe si lo quito hoy?"
9. .env nunca en repo. Usar .env.template. Expandir ${VAR:-default}.
10. Factory LLM: usar src/backend/services/llm/factory.js createProvider('ollama') -> lee config/llm-profiles.json y expande env. No hardcodear URLs.
11. Integración con Obsidian: Los clippings generados por Web Clipper se almacenan en el vault de Obsidian con frontmatter YAML. Runeforge puede leer esos archivos para alimentar su base de conocimiento. La configuración de Web Clipper se encuentra en `config/obsidian/obsidian-web-clipper-settings.json` y debe importarse en el plugin.
## 5. Perfiles LLM (config/llm-profiles.json)
- ollama: local, baseUrl ${OLLAMA_BASE_URL}, modelos fast=qwen2.5:1.5b, chat=gemma2:2b, code=deepseek-coder, embed=nomic-embed-text, keep_alive 10m, MAX=1
- deepseek: cloud opcional, apiKey ${DEEPSEEK_API_KEY}
- gemini: cloud opcional, apiKey ${GEMINI_API_KEY}, modelo gemini-1.5-flash
- meta: whatsapp business opcional, token ${META_WA_TOKEN}
Default: ollama.
## 6. Objetivo Real del Usuario
"Runeforge me sirve para llevar orden en mi trabajo de telemetría (bitácoras, análisis de problemas, reforma de actividades) y en lo personal para seguir hábitos, rutinas y planeación de proyectos personales."
Motor: capturar -> guardar estructurado -> recuperar/resumir. Todo es fecha+tipo+proyecto+texto+estado.
## 7. Definición de Terminado Etapa 1 v2
- 2 vías captura funcionando (Telegram + Form) sin punto único fallo
- Data Table bitacoras_v2 con manejo "no entendí" y parse_confidence
- Backup diario desde día 1
- Re-benchmark Ollama en GTX 1660 SUPER documentado
- Uso 3 días seguidos sin fallar
- Integración básica con Obsidian (lectura de clippings)
## 8. Anti-patrones Prohibidos
- Un solo canal de captura (WhatsApp solo)
- Guardar basura silenciosa por parseo fallido
- Datos sin backup 3 etapas
- Usar Ollama en Etapa 2 sin validar en Etapa 1
- WhatsApp Business Cloud en Etapa 1
- node_modules en backups zips
- Duplicar knowledge/RUNEFORGE_KNOWLEDGE dentro de knowledge/
## 9. Plantilla de variables de entorno (.env.template)
```
# RUNEFORGE -.env.template - Copiar a .env y completar
# Filosofía: Local-First, nunca commitear .env real
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
# === LLM CLOUD OPCIONAL ===
DEEPSEEK_API_KEY=
DEEPSEEK_BASE_URL=https://api.deepseek.com
GEMINI_API_KEY=
GEMINI_BASE_URL=https://generativelanguage.googleapis.com
# === WHATSAPP / META ===
META_WA_TOKEN=
META_WA_PHONE_NUMBER_ID=
META_WA_BUSINESS_ID=
META_WA_BASE_URL=https://graph.facebook.com/v20.0
EVOLUTION_API_URL=http://localhost:8081
EVOLUTION_API_KEY=
# === TELEGRAM ===
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
# === BACKUP ===
BACKUP_ENABLED=true
BACKUP_CRON=0 2 * * *
BACKUP_DIR=C:\RUNEFORGE_BACKUPS\bitacoras
BACKUP_RETENTION_DAYS=90
BACKUP_GDRIVE_ENABLED=false
BACKUP_GDRIVE_FOLDER_ID=
# === TELEMETRIA CINER ===
CINER_PROJECT=Ciner
CINER_RETENTION_DAYS=730
CINER_EXPORT_FORMAT=csv
PERSONAL_RETENTION_DAYS=365
# === PWA ===
PWA_QUOTA_TARGET=60
PWA_PERSIST=true
VITE_API_URL=http://localhost:3100
# === AWS ===
AWS_REGION=us-east-2
AWS_AGENT_TOOLKIT_REGION=us-east-1
AWS_EC2_INSTANCE_ID=
# === OBSIDIAN ===
OBSIDIAN_VAULT_PATH=C:\RUNEFORGE_OBSIDIAN
OBSIDIAN_CLIPPINGS_DIR=Clippings
```
