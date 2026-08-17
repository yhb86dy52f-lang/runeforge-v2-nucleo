# Runeforge v2.6.2 VERDE+LLM - Ecosistema Local-First IA Autonoma

Centro de operaciones digital personal 100% local sin nube. Gestion conocimiento, automatizacion, IA ligera y telemetria con dashboard unificado y soberania digital.

**1 frase:** Fastify + SQLite WAL + Ollama local 110.80 tok/s en GTX 1660 SUPER 6GB + PWA 76.8GB quota + Tailscale/Headscale 100% offline.

**Publico:** CINER, makers, devs local-first, homelab Ryzen 3 3200G 16GB GTX 1660 SUPER que quieren IA autonoma sin API keys cloud.

**Stack verificado 2026-08-15 02:28:58:**
- Backend: Fastify 77,193 req/s vs Express 14,200 autocannon -c 100 -d 40 -p 10 | PM2 relay 46.3mb backend 52.2mb online
- Frontend: PWA Vanilla JS 10 pestanas forge mission control pwa acceso deepseek infograma roadmap chat docs
- LLM: Ollama :11434 qwen2.5:1.5b 986MB gemma2:2b 1.6GB nomic-embed-text 274MB deepseek-coder 776MB total 3.6GB | keep_alive 10m fix load 5.93s | MAX=1 evita OOM thrashing 15-22s
- DB: SQLite WAL readers do not block writers autocheckpoint 1000
- Mesh: Tailscale 1.98.10 NoState bug 169.254.x.x fix winsock reset + Headscale self-hosted soberania 100%

## Como Empezar (3 comandos)

```powershell
git clone https://github.com/yhb86dy52f-lang/runeforge-v2-nucleo.git
Set-Location runeforge-v2-nucleo
.\runeforge_launcher.ps1 # levanta Ollama 11434 + PM2 + warmup 10m + Tailscale fix
pm2 list # relay 46mb backend 52mb online
Invoke-RestMethod http://localhost:3100/api/ollama/status # ok:true count:4
Invoke-RestMethod -Uri http://localhost:3100/api/chat -Method POST -Body (@{message="Hola"}|ConvertTo-Json) -ContentType "application/json"
Para Agentes IA
Leer AGENTS.md (150 lineas fuente) -> config/llm-profiles.json -> src/backend/services/llm/factory.js -> createProvider('ollama').chat()

JavaScript
const {createProvider}=require('C:/RUNEFORGE_V2_CORE/src/backend/services/llm/factory.js')
const ollama=createProvider('ollama')
await ollama.health() // ok:true count:4 endpoint http://127.0.0.1:11434 vram 2768/6144
await ollama.chat('Hola Runeforge v2.6.2')
Versionado Unificado
v2.6.2 = v2.6.1 VERDE TOTAL 101MB 611k borradas + v2.4 LLM factory fix 0.0.0.0->11434 + AGENTS 150 lineas + WebKit 60% 76.8GB + NoState 100.74.51.118 + 110.80 tok/s. No mas v2.3.0 vs v2.4 conflicto.

Filosofia
Local-First / Soberania Digital / Bajo Consumo / Modular / Auto-reparable / 100% offline

Repo: https://github.com/yhb86dy52f-lang/runeforge-v2-nucleo | Dashboard: http://localhost:3100 | Forge: http://localhost:3100/forge | Status: http://localhost:3100/api/ollama/status
