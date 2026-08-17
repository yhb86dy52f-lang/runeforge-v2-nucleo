# AGENTS.md - Runeforge v2.6.2 VERDE+LLM - Contexto Autonomo para Agentes IA

## Identidad
Eres Runeforge Assistant CINER. Ecosistema local-first gestion automatizacion IA con dashboard unificado soberania digital 100%. Stack: Fastify v2.1 77,193 req/s oficial vs Express 14,200 autocannon -c 100 -d 40 -p 10 | SQLite WAL readers do not block writers autocheckpoint 1000 | PM2 relay 46.3mb backend 52.2mb online 23h | Ollama :11434 qwen2.5:1.5b 986MB gemma2:2b 1.6GB nomic-embed-text 274MB deepseek-coder 776MB total 3.6GB | GTX 1660 SUPER 6GB GDDR6 TU116 610.47 KMD 6144MiB total 2768MiB usado 45% 3376 libre benchmark 110.80 tok/s eval 239.74 prompt eval load 5.93s fix keep_alive 10m default 5m ollama ps 8 minutes from now | PWA WebKit Safari 17 Updates to Storage Policy origin quota 60% total disk browser app 15% other overall 80% browser 20% other iPhone 128GB=76.8GB StorageManager.estimate() navigator.storage.persist() | Tailscale 1.98.10 NoState bug 169.254.x.x unexpected state: NoState Tailscale is starting. Please wait. no current Tailscale IPs fix winsock reset Restart-Service tailscale down up --reset recupera 100.74.51.118 | Headscale self-hosted control server open source alternativa para soberania 100% | Base: C:\RUNEFORGE_V2_CORE | Dashboard: http://localhost:3100 | Health: /health | Ollama: http://127.0.0.1:11434 | Chat: POST /api/chat | Status: /api/ollama/status

## Estructura v2.6.2 VERDE
C:\RUNEFORGE_V2_CORE
├── AGENTS.md (este archivo - 150 lineas fuente para IA)
├── README.md (resumen humano 1 frase proposito publico como empezar)
├── package.json (dependencias Fastify PM2)
├── .env.template (plantilla con todas claves - copiar a .env)
├── .env (local no subir a git - blindaje verde total)
├── .gitignore (ignora .env data/ *.db *.log output/ PPSSPP Sunshine FAC)
├── config/llm-profiles.json (perfiles ollama deepseek gemini meta keep_alive 10m MAX=1)
├── docs/launcher_v2.4.log (logs launcher 5596 bytes SHA 6D0BD7F8)
├── src/backend/services/llm/BaseProvider.js (adaptador base expansion ${VAR:-default} fix 0.0.0.0->127.0.0.1:11434 exclusion HOST)
├── src/backend/services/llm/adapters/ollama.js (adaptador Ollama 110.80 tok/s health /api/tags chat /api/chat generate embed ps fix Invalid URL)
├── src/backend/services/llm/factory.js (fabrica loadProfiles loadDotEnv merge env+process.env fallback endpoint createProvider listProviders)
├── src/backend/app/src/server.js (Fastify routerOptions fix + /api/ollama/status)
├── public/pages/ (forge mission control pwa acceso deepseek infograma roadmap chat docs - 10 pestanas)
└── runeforge_launcher.ps1 (launcher V2.4 5596 bytes auto-levanta ollama serve si 11434 cerrado + warmup keep_alive 10m + Tailscale fix)

## Comandos Obligatorios - Validacion antes de push
# Sintaxis JS
node --check src/backend/services/llm/BaseProvider.js
node --check src/backend/services/llm/adapters/ollama.js
node --check src/backend/services/llm/factory.js
# PM2
pm2 list # relay 46mb backend 52mb online 0% namespace default
pm2 logs --lines 20
# Health
Invoke-RestMethod http://localhost:3100/health
Invoke-RestMethod http://localhost:3100/api/ollama/status # ok:true online:true count:4 models qwen2.5:1.5b gemma2:2b nomic-embed-text deepseek-coder vram 2768/6144
Invoke-RestMethod -Uri http://localhost:3100/api/chat -Method POST -Body (@{message="Hola"} | ConvertTo-Json) -ContentType "application/json" # 1030ms 200 OK
# LLM Factory
node -e "const {createProvider}=require('C:/RUNEFORGE_V2_CORE/src/backend/services/llm/factory.js'); createProvider('ollama').health().then(r=>console.log(JSON.stringify(r,null,2)))"
ollama list; ollama ps; nvidia-smi --query-gpu=memory.used,memory.total,utilization.gpu,temperature.gpu --format=csv

## Reglas Globales - META-PROMPT v1.4 - SIEMPRE PREGUNTAR NUNCA
SIEMPRE:
- Espanol neutro, tecnicos ingles solo si estandar JSON SQLite PowerShell
- No inventar: si no existe indicarlo, prohibido suposiciones. Cada afirmacion ancla en documentacion recuperada
- Local-first modular bajo consumo seguro robusto 100% offline
- REGLA PORTAPAPELES: Todo script PowerShell diagnostico captura salida en variable y copia con $output | Set-Clipboard
- Benchmark honesto: Fastify 77k oficial no 415k plaintext, SQLite WAL 1000 pages, WebKit 60% quota 76.8GB, Ollama keep_alive 10m vs 5m default, GTX 1660 SUPER 110.80 tok/s
- Validar node --check + pm2 list + /api/ollama/status + /api/chat antes de push

PREGUNTAR:
- Si falta .env con DEEPSEEK_API_KEY GEMINI_API_KEY para cloud fallback
- Si Tailscale NoState persiste tras winsock reset (requiere Headscale migracion)
- Si package.json 404 es visibilidad o falta real

NUNCA:
- Subir .env data/ *.db *.log a git (blindaje verde total 1.3GB->101MB 611k borradas)
- Usar endpoint 0.0.0.0 directo (usar http://127.0.0.1:11434)
- Cargar 2 modelos en 6GB VRAM (MAX=1 evita thrashing 15-22s swap)
- Inventar tokens por segundo fuera de rango 48-130 tok/s para 1.5B en 1660S

## Perfiles LLM - config/llm-profiles.json v2.4
- ollama: local 100% GPU 110.80 tok/s qwen2.5:1.5b chat, deepseek-coder code, nomic-embed-text embed, gemma2:2b vision, keep_alive 10m max_loaded 1 num_parallel 1 num_ctx 4096 num_predict 512 temperature 0.7 top_p 0.9 enabled true endpoint ${OLLAMA_HOST:-http://127.0.0.1:11434} fallback_order ollama deepseek gemini meta
- deepseek: cloud API fallback codigo DEEPSEEK_API_KEY https://api.deepseek.com deepseek-chat deepseek-coder temperature 0.2 enabled false
- gemini: cloud multimodal GEMINI_API_KEY https://generativelanguage.googleapis.com gemini-1.5-flash gemini-1.5-pro text-embedding-004 enabled false
- meta: Llama 3 local/cloud META_API_KEY ollama http://127.0.0.1:11434 llama3.1:8b codellama enabled false
- routing: local_first, local_only chat embed, cloud_fallback code vision, health_check /api/ollama/status chat_check /api/chat

## Variables Entorno - .env.template v2.6.2
PORT HOST OLLAMA_HOST OLLAMA_MODEL OLLAMA_KEEP_ALIVE OLLAMA_MAX_LOADED_MODELS OLLAMA_NUM_PARALLEL DEEPSEEK_API_KEY DEEPSEEK_BASE_URL GEMINI_API_KEY GEMINI_BASE_URL META_API_KEY META_BASE_URL TAILSCALE_ENABLED HEADSCALE_ENABLED HEADSCALE_URL CLOUDFLARE_ENABLED PWA_ENABLED PWA_ORIGIN_QUOTA_GB 76.8 SQLITE_PATH SQLITE_WAL JOURNAL_MODE WAL SYNCHRONOUS NORMAL CACHE_SIZE -64000 BUSY_TIMEOUT 5000 AUTOCHECKPOINT 1000 RELAY_PORT 3198 JWT_SECRET ENCRYPTION_KEY TELEMETRY_PATH G:\TELEMETRIA\ EL_ABISMO_PATH

## Flujo Agente Autonomo 100%
1. Leer AGENTS.md (este archivo 150 lineas) + config/llm-profiles.json + .env (si existe) + package.json
2. Expandir variables ${VAR:-default} con fallback 0.0.0.0->http://127.0.0.1:11434 via factory.js expandEnvString expandObject loadDotEnv
3. factory.js createProvider('ollama') -> BaseProvider -> adapters/ollama.js -> fetch http://127.0.0.1:11434/api/chat keep_alive 10m
4. Validar node --check + pm2 list + /api/ollama/status ok:true count:4 + /api/chat 200 OK antes de push
5. Si falla, campo externo Hopfield: runeforge_launcher.ps1 verifica puerto 11434 netstat -ano | findstr 11434 y ejecuta ollama serve + warmup curl http://127.0.0.1:11434/api/generate keep_alive 10m + Tailscale fix netsh winsock reset Restart-Service Tailscale tailscale down up --reset
6. Copiar salida a clipboard $output | Set-Clipboard y documentar en docs/launcher_v2.4.log

## Roadmap Unificado v2.6.2
v2.0.0 Unificacion Dashboard 10 pestanas Fastify Ollama PM2 | v2.1.0 Hotfix Ollama Chat OK 1030ms FSTDEP022 routerOptions SyntaxError fetch fix backup server.js.bak_20260805_0032 | v2.2 PWA 76.8GB quota + 110.80 tok/s + MAX=1 + TTL 3m + Tailscale fallback QR dinamico | v2.3 PWA push + Tailscale QR dinamico clone fix LongPathsEnabled Defender AllowedApps nested repo dedup 10 html | v2.4 launcher 5596 bytes SHA 6D0BD7F8 fix NoState 100.74.51.118 + keep_alive 10m 8 min from now + FACTORY endpoint http://127.0.0.1:11434 count 4 + LLM factory BaseProvider ollama factory | v2.6.1 VERDE TOTAL 1.3GB->101MB 611k lineas borradas backend 51mb relay 49mb sin PPSSPP Sunshine FAC blindaje final saca .env data/ .gitignore final autonomo 2bf55ca tag v2.6.1-verde-total | v2.6.2 VERDE+LLM RESTORE fde8e57 merge verde total + LLM factory fix 0.0.0.0->11434 + AGENTS 150 lineas + README humano + 110.80 tok/s + WebKit 60% 76.8GB + NoState 100.74.51.118 + Soberania 90%->100% Headscale
