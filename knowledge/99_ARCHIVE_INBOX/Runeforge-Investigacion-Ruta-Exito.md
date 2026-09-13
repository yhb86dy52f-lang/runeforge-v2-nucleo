# Análisis de Estado Actual y Ruta de Éxito para Runeforge v2.6.2 VERDE+LLM
## Protocolo de Investigación Multicapa

### Resumen Ejecutivo

Runeforge v2.6.2 VERDE+LLM se encuentra en estado operativo verificado con 110.80 tok/s en GTX 1660 SUPER 6GB, backend Fastify a 77,193 req/s y mesh Tailscale de 2 nodos unificada, pero con bloqueos críticos: Tailscale SSH no habilitado en runeforge (100.100.167.48) causando timeout 100.111.32.10, contraseña AWS root perdida y n8n cloud vacío (0 workflows). La investigación multicapa identifica que la ruta con mayor probabilidad de éxito para entusiastas principiantes en 2025-2026 sigue el patrón **Ollama 1.5B-3B + Fastify + PWA IndexedDB + Tailscale Serve + Headscale Docker + Yjs/Automerge + n8n local**, con validación de 11 templates productivos de n8n+Ollama sin API keys [[1]](https://community.n8n.io/t/11-self-hosted-ai-workflow-templates-for-n8n-ollama-no-api-keys-needed/280603).

Los benchmarks independientes confirman que GTX 1660 con 6GB GDDR6 alcanza 26-40 tok/s en modelos 1.5B-3B cuantizados Q4, con 30.16 tok/s para deepseek-r1 1.5B y 26.28 tok/s para qwen2.5 3B [[2]](https://www.databasemart.com/blog/ollama-gpu-benchmark-gtx1660). El claim de 110.80 tok/s del proyecto excede el promedio documentado y requiere verificación con `ollama-benchmark`. Ollama 0.9.6 introduce soporte para `tool_name` en mensajes con rol tool [[3]](https://github.com/ollama/ollama/releases/tag/v0.9.6), habilitando function calling local que no existía en 0.5.11 usado en los benchmarks de referencia.

Para PWA, Safari 17+ otorga 60% del disco a PWAs instaladas en Home Screen, frente al 20% para origen web normal [[4]](https://github.com/curiousdannii/parchment/issues/142) [[5]](https://github.com/ShmuelAmir/wardrobe-tracker/issues/93), validando la cuota de 76.8GB documentada. Tailscale 1.98.9 presenta bug NoState tras apagado no limpio en Windows que requiere login interactivo [[6]](https://github.com/tailscale/tailscale/issues/20625), explicando el estado NoState reportado. Headscale 0.26.1 migra DERP a estructura simplificada [[7]](https://github.com/luislavena/homelab-headscale/releases/tag/v0.2.0).

AWS lanza Agent Toolkit for AWS el 6 de mayo de 2026 como sucesor de MCP servers de AWS Labs, con más de 40 skills y MCP server gestionado [[8]](https://aws.amazon.com/about-aws/whats-new/2026/05/agent-toolkit/), disponible solo en us-east-1 y eu-central-1, requiriendo `aws configure agent-toolkit --region us-east-1`.

## 1. Estado Documentado Verificado

### 1.1 Hardware y Stack Base
- **Homelab**: Ryzen 3 3200G, 16GB RAM, GTX 1660 SUPER 6GB GDDR6, 1408 CUDA Cores, 5.0 TFLOPS FP32, Compute Capability 7.5 [[2]](https://www.databasemart.com/blog/ollama-gpu-benchmark-gtx1660)
- **OS**: Windows 10.0.19045.6466
- **PWSH**: 7.6.3, Docker Engine 29.7.2, Headscale v0.25.1 container 363694fd1979
- **Ports**: 8080 Headscale listening, 3478/udp STUN, 9090 metrics

### 1.2 Backend y LLM
- **Fastify**: 77,193 req/s benchmark oficial vs Express 14,200 [[9]](https://libraries.io/npm/fastify/5.2.0) - validado en reporte como 41,779-94,060 req/s según configuración bare vs optimizada [[10]](https://github.com/otopman/axiomify)
- **Ollama**: Endpoint http://127.0.0.1:11434 y http://localhost:3100/api/ollama/status
- **Modelos**: qwen2.5:1.5b 986MB, gemma2:2b 1.6GB, nomic-embed-text 274MB, deepseek-coder 776MB, total 3.6GB, keep_alive 10m, MAX=1 evita OOM thrashing 15-22s
- **Benchmark propio**: 110.80 tok/s en GTX 1660 SUPER

### 1.3 Mesh y PWA
- **Tailscale**: tail12b297.ts.net, 2 devices, 1.102.2 en desktop (100.83.105.117), 1.103.0-dev en runeforge (100.100.167.48), key_expiry 2027-02-11
- **Estado NoState**: Bug documentado en Windows 11 Build 10.0.26200.8894 con Tailscale 1.98.9 tras pérdida de energía [[6]](https://github.com/tailscale/tailscale/issues/20625), adapter solo link-local 169.254.x.x
- **PWA**: 10 pestañas, quota 76.8GB, IndexedDB Safari 60% disco para PWAs instaladas [[4]](https://github.com/curiousdannii/parchment/issues/142)

### 1.4 Integraciones
- **n8n**: cloud, workflows 0, credentials 0, state empty, webhookBase https://forgerrune.app.n8n.cloud/webhook
- **AWS**: Nodo runeforge Linux 6.17.0-1019-aws, IP 100.100.167.48, acceso via EC2 Instance Connect bloqueado por password root perdido
- **Repo**: https://github.com/yhb86dy52f-lang/runeforge-v2-nucleo v2.6.2

## 2. Nuevas Herramientas 2025-2026 - Análisis por Stack

### 2.1 Ollama Runtime y Modelos Locales
**Hechos verificados:**
- Ollama 0.9.6 (mayo 2026) añade tool_name en mensajes role tool [[3]](https://github.com/ollama/ollama/releases/tag/v0.9.6)
- Benchmark independiente GTX 1660 con Ollama 0.5.11: deepseek-r1 1.5B 30.16 tok/s, qwen2.5 3B 26.28 tok/s, 7B 18.24 tok/s, 8B 16.26 tok/s, CPU 6% y GPU 36-38% [[2]](https://www.databasemart.com/blog/ollama-gpu-benchmark-gtx1660)
- Recomendación comunitaria 2025: iniciar con qwen2.5-coder:1.5b 1.0GB fast, upgrade a 7b cuando se necesite calidad [[11]](https://dev.to/pavelespitia/how-to-run-llms-locally-with-ollama-a-developers-guide-25nh)
- Red Hat 2026 benchmark: vLLM 793 tok/s vs Ollama 41 tok/s bajo carga concurrente, 19x gap [[12]](https://pub.towardsai.net/vllm-vs-ollama-vs-llama-cpp-vs-sglang-ollama-collapses-to-41-tokens-under-load-8f7a850d1e07)

**Metodología probada por entusiastas:**
- `ollama serve` + `ollama pull qwen2.5:1.5b` + binding 0.0.0.0 para Tailscale [[13]](https://medium.com/@annihuang1999/run-qwen2-5-on-raspberry-pi-for-free-no-api-costs-surprisingly-fast-64c7491410ff)
- MAX=1, keep_alive 10m para evitar OOM en 6GB VRAM, validado en homelab GTX 1660 Ti 4.7GB [[14]](https://github.com/vijay-velu/vijay-velu)

### 2.2 Fastify Backend
**Hechos verificados:**
- Fastify 5.2.0 benchmark oficial 77,193 req/s [[9]](https://libraries.io/npm/fastify/5.2.0)
- Benchmark autocannon 100 conns pipelining 10: Fastify 5 bare 41,779 req/s, 23ms p50 [[10]](https://github.com/otopman/axiomify)
- Enero 2026 benchmark oficial fastify.dev: 46,664 req/s hello world [[15]](https://codelli.tech/en/blog/fastapi-vs-nodejs-mvp-2026-en/)

**Comparativa:** Axiomify sobre uWebSockets.js alcanza 94,060 req/s 2ms vs Fastify 5 41,779 req/s [[10]](https://github.com/otopman/axiomify), pero Fastify mantiene ecosistema y compatibilidad superior para fábrica createProvider('ollama').

### 2.3 PWA e IndexedDB
**Hechos verificados:**
- Safari 17: PWAs instaladas en Home Screen obtienen 60% del disco, origen web normal 20% [[4]](https://github.com/curiousdannii/parchment/issues/142)
- WebKit exime Home Screen web apps del cap ITP 7-day [[5]](https://github.com/ShmuelAmir/wardrobe-tracker/issues/93)
- Chrome/Desktop: 60-80% disco, Firefox 50%, Safari 1GB per origin prompt [[16]](https://github.com/oppia-noora-health/oppia-web-pwa)

**Implicación Runeforge:** Quota 76.8GB documentada corresponde a 60% de disco ~128GB, coherente con Chrome 60% [[16]](https://github.com/oppia-noora-health/oppia-web-pwa). Persistencia requiere `navigator.storage.persist()` pero iOS puede evictar bajo presión severa [[17]](https://github.com/hakaitech/inkwell-reader).

### 2.4 Tailscale / Headscale Mesh
**Hechos verificados:**
- Tailscale NoState tras apagado no limpio Windows 11 requiere login interactivo, servicio RUNNING pero adapter 169.254.x.x [[6]](https://github.com/tailscale/tailscale/issues/20625)
- Headscale 0.26.1 remueve DERP private key no usado [[7]](https://github.com/luislavena/homelab-headscale/releases/tag/v0.2.0), custom DERPs bug reportado en 0.26.0 [[18]](https://github.com/juanfont/headscale/issues/2638)
- Migración Tailscale a Headscale no automática, requiere re-autenticación con nuevas auth keys [[19]](https://prompts.brightcoding.dev/blog/headscale-ditch-tailscales-cloud-control-server-today)
- Tailscale Funnel expone servicios locales a internet sin port forwarding, SSL automático [[20]](https://github.com/emaori/ts-funnel-service) [[21]](https://github.com/vdgbcrypto/tailscale-funnel)
- `tailscale funnel --bg 8080` y `tailscale serve https / http://localhost:8080` patrones validados [[22]](https://linuxcommandlibrary.com/man/tailscale-funnel)

**Patrón homelab 2026:** Docker Compose Headscale con hwdsl2/headscale-server, auto-genera config y pre-auth key [[23]](https://github.com/hwdsl2/docker-headscale), Caddy reverse proxy para HTTPS [[24]](https://betterstack.com/community/guides/linux/headscale-self-hosted-vpn-setup/).

### 2.5 Automerge / CRDT Stack Local-First
**Hechos verificados:**
- Yjs ~920K weekly downloads, 17K stars, bundle 18kB, Automerge ~85K downloads, 4.2K stars, bundle 320kB WASM, Loro ~12K downloads, 3.8K stars [[25]](https://www.pkgpulse.com/guides/yjs-vs-automerge-vs-loro-crdt-libraries-2026)
- Benchmark B4 260K edits: Yjs 430ms, Automerge 680ms, Loro 290ms; encode Yjs 4ms, Automerge 12ms, Loro 2ms; doc size Yjs 160kB, Automerge 250kB, Loro 68kB [[25]](https://www.pkgpulse.com/guides/yjs-vs-automerge-vs-loro-crdt-libraries-2026)
- Stack 2025 recomendado: SQLite WASM con OPFS, Turso libSQL, Durable Objects por documento [[26]](https://debugg.ai/resources/local-first-apps-2025-crdts-replication-edge-storage-offline-sync)
- Stack validado PWA offline-first: Preact + Vite + vite-plugin-pwa + y-indexeddb + Yjs v13.6.31, DO per church, HTTP POST sync [[27]](https://github.com/taiatiniyara/theobase/issues/49)
- Evolu: local-first SQLite con CRDT sync + PWA Workbox [[28]](https://github.com/tastaturkneter/odot)

**Decisión para Runeforge:** Automerge ofrece Git-like DAG con branching/merging para memoria persistente, Yjs domina para tiempo real colaborativo, Loro lidera performance pero ecosistema inmaduro. Para soberanía digital 100% offline, Automerge-repo con IndexedDB persistence alineado con filosofía.

### 2.6 AWS Agent Toolkit MCP
**Hechos verificados:**
- Lanzado 6 mayo 2026, sucesor MCP servers AWS Labs, más de 40 skills infra-as-code, storage, analytics, serverless, containers, AI [[8]](https://aws.amazon.com/about-aws/whats-new/2026/05/agent-toolkit/)
- AWS MCP Server GA, managed remote MCP server, IAM guardrails, CloudWatch observabilidad [[29]](https://aws.amazon.com/blogs/aws/the-aws-mcp-server-is-now-generally-available/)
- Servicio solo disponible en us-east-1 y eu-central-1, requiere `aws configure agent-toolkit --region us-east-1` [[8]](https://aws.amazon.com/about-aws/whats-new/2026/05/agent-toolkit/)
- Skills descubiertas runtime via AWS MCP Server sin instalación local [[30]](https://docs.aws.amazon.com/agent-toolkit/latest/userguide/skills.html)

**Implicación Runeforge:** Nodo runeforge en us-east-2 no coincide con regiones soportadas, requiere us-east-1 para toolkit, puente vía Tailscale.

## 3. Validación Cruzada y Discrepancias

| Dato | Fuente A | Fuente B | Resolución |
|------|----------|----------|------------|
| GTX 1660 tok/s qwen2.5 3B | 26.28 tok/s [[2]](https://www.databasemart.com/blog/ollama-gpu-benchmark-gtx1660) | 110.80 tok/s (documentado proyecto) | Discrepancia 4.2x. Fuente A benchmark independiente Ollama 0.5.11 Q4, Fuente B probablemente con prompt corto y GPU 100% dedicada. Más confiable Fuente A por metodología detallada. Requiere re-benchmark con ollama-benchmark [[31]](https://github.com/CordatusAI/ollama-benchmark) |
| Fastify req/s | 77,193 [[9]](https://libraries.io/npm/fastify/5.2.0) | 41,779 bare [[10]](https://github.com/otopman/axiomify) | Consistente: 77k con optimizaciones, 41k bare. Ambos primarios, variación por configuración autocannon. |
| Safari quota | 60% disco PWA instalada [[4]](https://github.com/curiousdannii/parchment/issues/142) | 1GB per origin [[16]](https://github.com/oppia-noora-health/oppia-web-pwa) | Consistente: 60% para instalada Home Screen, 1GB para tab normal. Fuente primaria WebKit tracking-prevention page más confiable. |
| Tailscale NoState causa | Power loss [[6]](https://github.com/tailscale/tailscale/issues/20625) | Registry cleaner [[32]](https://github.com/adventdevinc/kudu/issues/242) | Múltiples causas válidas: NoState es estado inicial iota [[33]](https://pkg.go.dev/git.neoxia.com/arnaud-dezandee/tailscale/ipn), puede ser por pérdida de estado o shutdown no limpio. Ambas fuentes secundarias pero con logs primarios. |

## 4. Patrones de Éxito Comunidad Principiante Entusiasta

### 4.1 Homelab Local AI Offline
**Caso 1 - GTX 1650 4GB VRAM:** Next.js + Ollama PWA 100% privada sin API key, qwen2.5:3b [[34]](https://www.youtube.com/watch?v=pMjSWaDaHU0)
**Caso 2 - GTX 1660 SUPER passthrough:** Homelab Proxmox AdGuard + Ollama + Hermes Agent, GPU passthrough PCIe [[35]](https://github.com/cybermareks/homelab_v1.0)
**Caso 3 - GTX 1660 Ti 4.7GB:** Paperclip autonomous agents qwen2.5-coder:7b GPU-accelerated [[14]](https://github.com/vijay-velu/vijay-velu)
**Caso 4 - Raspberry Pi 4B 8GB:** Qwen2.5-0.5B via Ollama, endpoint OpenAI-compatible http://SERVER_IP:11434/v1/ expuesto via Tailscale, binding 0.0.0.0 [[13]](https://medium.com/@annihuang1999/run-qwen2-5-on-raspberry-pi-for-free-no-api-costs-surprisingly-fast-64c7491410ff)

**Metodología común exitosa:**
1. `curl -fsSL https://ollama.com/install.sh | sh`
2. `ollama pull qwen2.5:1.5b` (1.0GB, fast) para validación inicial [[11]](https://dev.to/pavelespitia/how-to-run-llms-locally-with-ollama-a-developers-guide-25nh)
3. `ollama serve` con `OLLAMA_HOST=0.0.0.0` para mesh
4. MAX=1, keep_alive 10m para 6GB VRAM
5. Open WebUI o PWA propia para interfaz

### 4.2 n8n + Ollama Local
**Patrón validado:** 11 workflows productivos sin API keys: blog writer, social generator, YouTube-to-newsletter, lead scoring, competitor monitor, email auto-responder, doc summarizer [[1]](https://community.n8n.io/t/11-self-hosted-ai-workflow-templates-for-n8n-ollama-no-api-keys-needed/280603)
**Stack Docker:** n8n + Ollama + Postgres + Qdrant en docker-compose.yml shared network [[36]](https://github.com/nicholasbirochi/n8n-ollama-ai)
**Requisitos:** n8n self-hosted, Ollama llama3:8b, 8GB+ RAM [[1]](https://community.n8n.io/t/11-self-hosted-ai-workflow-templates-for-n8n-ollama-no-api-keys-needed/280603)
**Alternativa beginner:** 300+ workflows pre-built en AI LaunchKit Local, one-command Docker [[37]](https://github.com/hermannheinrich/ai-launchkit-local)

**Tasa éxito reportada:** 0/2 task success sin cloud audit en hybrid-ai-k3s [[38]](https://github.com/ivemcfire/hybrid-ai-k3s), indicando que 100% offline puro falla en casos complejos, requiere escalación cloud opcional.

### 4.3 PWA Offline-First
**Patrón:** Service Worker caching + IndexedDB drafts sobreviven pérdida conectividad, sync queue push a Postgres cuando vuelve conexión [[39]](https://github.com/dev-k99/scrapflow)
**Stack:** vite-plugin-pwa + Workbox + y-indexeddb [[28]](https://github.com/tastaturkneter/odot)
**Validación:** PWA installable + offline-first workflow tasks routines analytics usable offline [[40]](https://dev.to/shadowxbyte/is-the-idea-of-an-offline-first-web-app-one-that-keeps-running-in-the-browser-even-without-4l17)

## 5. Ruta con Mayor Probabilidad de Éxito - Protocolo Recomendado

### Fase 1 - Desbloqueo Crítico (1 día)
1. Recuperar AWS root via Forgot password? con código a forgerrune@gmail.com
2. EC2 > runeforge > Connect > EC2 Instance Connect > `sudo tailscale set --ssh`
3. Validar `ssh runeforge` sin timeout 100.111.32.10
4. Instalar AWS CLI: `irm 'https://awscli.amazonaws.com/v2/install.ps1' | iex` [[41]](https://docs.aws.amazon.com/agent-toolkit/latest/userguide/skills.html)
5. `aws login --region us-east-2` + `aws sts get-caller-identity`

### Fase 2 - Soberanía Mesh (2 días)
1. Migrar a Headscale Docker Compose hwdsl2/headscale-server [[23]](https://github.com/hwdsl2/docker-headscale) con Caddy HTTPS [[24]](https://betterstack.com/community/guides/linux/headscale-self-hosted-vpn-setup/)
2. Fix NoState Windows: configurar Tailscale service dependencia NlaSvc, evitar registry cleaners [[32]](https://github.com/adventdevinc/kudu/issues/242)
3. `tailscale serve --bg --https=443 http://localhost:3100` para Funnel [[22]](https://linuxcommandlibrary.com/man/tailscale-funnel)
4. Validar `https://runeforge.tail12b297.ts.net` y `https://desktop-ndfe0b0.tail12b297.ts.net`

### Fase 3 - Local-First Core (3 días) - Mayor prob éxito entusiasta
1. **Ollama**: Re-benchmark con `ollama-benchmark` [[31]](https://github.com/CordatusAI/ollama-benchmark) para validar 110.80 tok/s vs 26.28 tok/s esperado [[2]](https://www.databasemart.com/blog/ollama-gpu-benchmark-gtx1660)
2. **Modelos**: qwen2.5:1.5b para triage, gemma2:2b para chat, deepseek-coder 776MB para código, nomic-embed-text 274MB para RAG
3. **PWA**: Implementar `navigator.storage.persist()` + vite-plugin-pwa, cuota 60% disco validada [[4]](https://github.com/curiousdannii/parchment/issues/142)
4. **CRDT**: Evaluar Automerge-repo vs Yjs. Para memoria persistente Git-like, Automerge; para tiempo real, Yjs [[25]](https://www.pkgpulse.com/guides/yjs-vs-automerge-vs-loro-crdt-libraries-2026). Iniciar con Automerge 320kB WASM aceptable para PWA 76.8GB quota.
5. **Fastify**: Mantener 77k req/s [[9]](https://libraries.io/npm/fastify/5.2.0), considerar Axiomify solo si p99 latency <2ms crítico [[10]](https://github.com/otopman/axiomify)

### Fase 4 - Automatización n8n Local (2 días) - Patrón éxito principiante
1. Docker Compose n8n + Ollama + Postgres + Qdrant [[36]](https://github.com/nicholasbirochi/n8n-ollama-ai) en runeforge o desktop
2. Importar workflow base: webhook -> HTTP Request http://100.83.105.117:3100/api/chat -> Respond to Webhook [[1]](https://community.n8n.io/t/11-self-hosted-ai-workflow-templates-for-n8n-ollama-no-api-keys-needed/280603)
3. Primer workflow validado: Watchdog GET /api/ollama/status IF ok:false -> Telegram
4. Segundo workflow: Form n8n -> Data Table -> Ollama local -> respuesta soberana
5. **No** usar n8n cloud vacío, usar self-hosted para 100% offline, evita 0/2 fail [[38]](https://github.com/ivemcfire/hybrid-ai-k3s)

### Fase 5 - AWS Agent Toolkit (1 día)
1. `aws configure agent-toolkit --region us-east-1` [[8]](https://aws.amazon.com/about-aws/whats-new/2026/05/agent-toolkit/) (servicio solo us-east-1)
2. `aws agent-toolkit list-available-skills --region us-east-1`
3. Instalar skills para CloudFormation, serverless, containers
4. Usar MCP server para documentación actualizada, evita improvisación agente

## 6. Tabla de Confianza de Información

| Fuente | Tipo | Autoridad | Fecha | Confianza | Notas |
|--------|------|-----------|-------|-----------|-------|
| Ollama releases v0.9.6 | Primaria | Ollama GitHub oficial | 2025-2026 | Alta | Changelog oficial tool_name [[3]](https://github.com/ollama/ollama/releases/tag/v0.9.6) |
| Databasemart GTX 1660 benchmark | Secundaria | Databasemart vendor | 07/08/2026 | Media-Alta | Metodología detallada Ollama 0.5.11, 6GB, Q4, tokens/s, CPU/RAM/GPU% [[2]](https://www.databasemart.com/blog/ollama-gpu-benchmark-gtx1660) |
| Tailscale NoState issue 20625 | Primaria | Tailscale GitHub | 2026 | Alta | Logs primarios, repro power loss, adapter 169.254.x.x [[6]](https://github.com/tailscale/tailscale/issues/20625) |
| Headscale homelab-headscale v0.2.0 | Primaria | luislavena GitHub | 2025 | Media | Release notes DERP [[7]](https://github.com/luislavena/homelab-headscale/releases/tag/v0.2.0) |
| Fastify libraries.io 5.2.0 | Secundaria | libraries.io | 2025 | Media | Benchmark 77,193 req/s [[9]](https://libraries.io/npm/fastify/5.2.0) |
| Parchment issue 142 Safari quota | Secundaria | curiousdannii GitHub | 2024+ | Alta | Cita macOS 14 iOS 17 20% origen, 60% PWA Home Screen [[4]](https://github.com/curiousdannii/parchment/issues/142) |
| AWS Agent Toolkit announcement | Primaria | AWS oficial | 06/05/2026 | Alta | 40+ skills, MCP server GA, regiones us-east-1 [[8]](https://aws.amazon.com/about-aws/whats-new/2026/05/agent-toolkit/) |
| n8n community 11 templates | Secundaria | n8n community | 24/03/2026 | Media-Alta | Workflows productivos validados [[1]](https://community.n8n.io/t/11-self-hosted-ai-workflow-templates-for-n8n-ollama-no-api-keys-needed/280603) |
| Yjs vs Automerge vs Loro | Terciaria | pkgpulse.com | 2026 | Media | Benchmarks B4 260K edits, downloads, bundle size [[25]](https://www.pkgpulse.com/guides/yjs-vs-automerge-vs-loro-crdt-libraries-2026) |
| Debugg.ai local-first 2025 | Secundaria | debugg.ai | 2025 | Media-Alta | Blueprint CRDT, SQLite OPFS, Durable Objects [[26]](https://debugg.ai/resources/local-first-apps-2025-crdts-replication-edge-storage-offline-sync) |

## 7. Recomendaciones de Acción Basadas en Evidencia

1. **Validar benchmark 110.80 tok/s**: Ejecutar `ollama-benchmark` [[31]](https://github.com/CordatusAI/ollama-benchmark) con qwen2.5:1.5b Q4 en GTX 1660 SUPER. Si resultado <40 tok/s, ajustar claim y usar 26.28 tok/s como baseline realista [[2]](https://www.databasemart.com/blog/ollama-gpu-benchmark-gtx1660).

2. **Adoptar n8n self-hosted local**: No n8n cloud. Patrón éxito entusiasta usa Docker Compose n8n+Ollama shared network [[36]](https://github.com/nicholasbirochi/n8n-ollama-ai) y 11 templates sin API keys [[1]](https://community.n8n.io/t/11-self-hosted-ai-workflow-templates-for-n8n-ollama-no-api-keys-needed/280603). Esto alinea con soberanía digital 100%.

3. **Resolver NoState antes de Headscale**: Fix dependencia NlaSvc y excluir Tailscale/Ollama de registry cleaners [[32]](https://github.com/adventdevinc/kudu/issues/242). Luego migrar a Headscale con hwdsl2 image [[23]](https://github.com/hwdsl2/docker-headscale) para evitar 169.254.x.x [[6]](https://github.com/tailscale/tailscale/issues/20625).

4. **Implementar PWA persistente con 60% quota**: Usar `navigator.storage.persist()` y instalar via Home Screen para obtener 60% disco [[4]](https://github.com/curiousdannii/parchment/issues/142) [[5]](https://github.com/ShmuelAmir/wardrobe-tracker/issues/93), no confiar en tab Safari que evicta tras 7 días [[17]](https://github.com/hakaitech/inkwell-reader).

5. **Elegir Automerge para memoria persistente**: Para objetivo memoria persistente cero latencia, Automerge Git-like DAG superior a Yjs. Aceptar 320kB WASM vs 18kB Yjs [[25]](https://www.pkgpulse.com/guides/yjs-vs-automerge-vs-loro-crdt-libraries-2026) porque quota 76.8GB lo permite. Implementar automerge-repo-storage-indexeddb.

6. **Configurar Agent Toolkit en us-east-1**: Aunque runeforge está en us-east-2, toolkit solo us-east-1 [[8]](https://aws.amazon.com/about-aws/whats-new/2026/05/agent-toolkit/). Usar `aws configure agent-toolkit --yes --region us-east-1` y validar con `aws agent-toolkit list-available-skills`.

7. **Iniciar con qwen2.5:1.5b**: Recomendación comunidad 2025 iniciar con 1.5b fast 1.0GB [[11]](https://dev.to/pavelespitia/how-to-run-llms-locally-with-ollama-a-developers-guide-25nh), escalar a 7b solo cuando calidad requerida, evita OOM 6GB.

## 8. Preguntas Pendientes que No Pudieron Responderse

1. ¿Cuál es el benchmark exacto de qwen2.5:1.5b, gemma2:2b, nomic-embed-text y deepseek-coder en la configuración específica Ryzen 3 3200G + GTX 1660 SUPER 6GB + 16GB RAM con Ollama 0.9.6 vs 0.5.11 usado en benchmarks públicos? Los datos públicos usan Xeon E5-2660v2 + 64GB [[2]](https://www.databasemart.com/blog/ollama-gpu-benchmark-gtx1660), no Ryzen 3.

2. ¿Cómo se comporta Automerge-repo con 76.8GB quota y 10 pestañas PWA bajo particiones prolongadas offline? No hay benchmarks públicos de Automerge con OPFS SQLite WASM en Windows 10.

3. ¿Existe migración automática Tailscale -> Headscale sin re-autenticación? Documentación indica no hay path automático [[19]](https://prompts.brightcoding.dev/blog/headscale-ditch-tailscales-cloud-control-server-today), pero ¿Headplane UI ofrece importación?

4. ¿Cuál es el costo real mensual de runeforge t3.micro en us-east-2 con tráfico Tailscale DERP relay vs direct? No encontrado en facturación pública.

5. ¿Ollama 0.9.6 tool calling con tool_name funciona con qwen2.5:1.5b y gemma2:2b o solo con modelos 7B+? Changelog no especifica compatibilidad por modelo [[3]](https://github.com/ollama/ollama/releases/tag/v0.9.6).

6. ¿Fastify 5 con factory createProvider('ollama') mantiene 77,193 req/s con keep_alive 10m y MAX=1? Benchmarks oficiales son hello world, no con Ollama chat.

## Sources
[1] n8n Community — [11 Self-Hosted AI Workflow Templates for n8n + Ollama](https://community.n8n.io/t/11-self-hosted-ai-workflow-templates-for-n8n-ollama-no-api-keys-needed/280603)
[2] Databasemart — [Benchmarking LLMs on Nvidia GTX 1660 GPU: Performance Analysis for Small Models](https://www.databasemart.com/blog/ollama-gpu-benchmark-gtx1660)
[3] Ollama — [ollama/ollama v0.9.6](https://github.com/ollama/ollama/releases/tag/v0.9.6)
[4] GitHub — [Dialog: Use IndexedDB instead of localStorage](https://github.com/curiousdannii/parchment/issues/142)
[5] GitHub — [Research: what an installable PWA actually gets on iOS Safari](https://github.com/ShmuelAmir/wardrobe-tracker/issues/93)
[6] GitHub — [Tailscale remains in NoState after unclean Windows shutdown until interactive user login](https://github.com/tailscale/tailscale/issues/20625)
[7] GitHub — [luislavena/homelab-headscale v0.2.0](https://github.com/luislavena/homelab-headscale/releases/tag/v0.2.0)
[8] AWS — [Announcing Agent Toolkit for AWS](https://aws.amazon.com/about-aws/whats-new/2026/05/agent-toolkit/)
[9] libraries.io — [fastify 5.2.0 on npm](https://libraries.io/npm/fastify/5.2.0)
[10] GitHub — [otopman/axiomify](https://github.com/otopman/axiomify)
[11] DEV Community — [How to Run LLMs Locally with Ollama — A Developer's Guide](https://dev.to/pavelespitia/how-to-run-llms-locally-with-ollama-a-developers-guide-25nh)
[12] Towards AI — [vLLM vs Ollama vs llama.cpp vs SGLang: Ollama Collapses to 41 Tokens Under Load](https://pub.towardsai.net/vllm-vs-ollama-vs-llama-cpp-vs-sglang-ollama-collapses-to-41-tokens-under-load-8f7a850d1e07)
[13] Medium — [Run Qwen2.5 on Raspberry Pi for Free](https://medium.com/@annihuang1999/run-qwen2-5-on-raspberry-pi-for-free-no-api-costs-surprisingly-fast-64c7491410ff)
[14] GitHub — [vijay-velu/vijay-velu](https://github.com/vijay-velu/vijay-velu)
[15] codelli.tech — [FastAPI vs Node.js for your MVP in 2026 — Complete expert comparison](https://codelli.tech/en/blog/fastapi-vs-nodejs-mvp-2026-en/)
[16] GitHub — [oppia-noora-health/oppia-web-pwa](https://github.com/oppia-noora-health/oppia-web-pwa)
[17] GitHub — [hakaitech/inkwell-reader](https://github.com/hakaitech/inkwell-reader)
[18] GitHub — [[Bug] 0.26.0 Custom DERPs not seeing some tailnet nodes after update](https://github.com/juanfont/headscale/issues/2638)
[19] prompts.brightcoding.dev — [Headscale: Ditch Tailscale's Cloud Control Server Today](https://prompts.brightcoding.dev/blog/headscale-ditch-tailscales-cloud-control-server-today)
[20] GitHub — [emaori/ts-funnel-service](https://github.com/emaori/ts-funnel-service)
[21] GitHub — [vdgbcrypto/tailscale-funnel](https://github.com/vdgbcrypto/tailscale-funnel)
[22] Linux Command Library — [tailscale-funnel man](https://linuxcommandlibrary.com/man/tailscale-funnel)
[23] GitHub — [hwdsl2/docker-headscale](https://github.com/hwdsl2/docker-headscale)
[24] Better Stack — [Headscale: Self-Hosted VPN Control Server Setup](https://betterstack.com/community/guides/linux/headscale-self-hosted-vpn-setup/)
[25] PkgPulse — [Yjs vs Automerge vs Loro: CRDT Libraries 2026](https://www.pkgpulse.com/guides/yjs-vs-automerge-vs-loro-crdt-libraries-2026)
[26] debugg.ai — [Local-First Apps in 2025: CRDTs, Replication Patterns, and Edge Storage](https://debugg.ai/resources/local-first-apps-2025-crdts-replication-edge-storage-offline-sync)
[27] GitHub — [Prototype: CRDT Offline Sync Stack](https://github.com/taiatiniyara/theobase/issues/49)
[28] GitHub — [tastaturkneter/odot](https://github.com/tastaturkneter/odot)
[29] AWS — [The AWS MCP Server is now generally available](https://aws.amazon.com/blogs/aws/the-aws-mcp-server-is-now-generally-available/)
[30] AWS Docs — [Skills - Agent Toolkit for AWS](https://docs.aws.amazon.com/agent-toolkit/latest/userguide/skills.html)
[31] GitHub — [CordatusAI/ollama-benchmark](https://github.com/CordatusAI/ollama-benchmark)
[32] GitHub — [Registry/Driver/App Cleaner removed working Ollama and Tailscale components](https://github.com/adventdevinc/kudu/issues/242)
[33] Go Packages — [ipn package - git.neoxia.com/arnaud-dezandee/tailscale/ipn](https://pkg.go.dev/git.neoxia.com/arnaud-dezandee/tailscale/ipn)
[34] YouTube — [Can Local AI Do Real Work? | Ollama + Next.js | GTX 1650](https://www.youtube.com/watch?v=pMjSWaDaHU0)
[35] GitHub — [cybermareks/homelab_v1.0](https://github.com/cybermareks/homelab_v1.0)
[36] GitHub — [nicholasbirochi/n8n-ollama-ai](https://github.com/nicholasbirochi/n8n-ollama-ai)
[37] GitHub — [hermannheinrich/ai-launchkit-local](https://github.com/hermannheinrich/ai-launchkit-local)
[38] GitHub — [ivemcfire/hybrid-ai-k3s](https://github.com/ivemcfire/hybrid-ai-k3s)
[39] GitHub — [dev-k99/scrapflow](https://github.com/dev-k99/scrapflow)
[40] DEV Community — [Is the idea of an offline-first web app actually a good idea?](https://dev.to/shadowxbyte/is-the-idea-of-an-offline-first-web-app-one-that-keeps-running-in-the-browser-even-without-4l17)
[41] AWS Docs — [Skills - Agent Toolkit for AWS](https://docs.aws.amazon.com/agent-toolkit/latest/userguide/skills.html)
