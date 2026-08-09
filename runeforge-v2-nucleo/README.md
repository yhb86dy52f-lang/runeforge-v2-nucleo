# Runeforge v2.3.0 - Ecosistema Local-First - QR Dinamico + Clone Fix

**Stack verificado 2026-08-05 01:36:33:**
- Backend: Fastify :3100 - PM2 IDs 3 y 1 - 83.5MB/65.9MB online
- Frontend: PWA + Tailscale dinamico - /api/network - QR JS vivo
- LLM: Ollama :11434 - qwen2.5:1.5b, gemma2:2b, deepseek-coder, nomic-embed-text
- Relay: WhatsApp :3198
- Clone: 100% (1971/1971) - longpaths true + Controlled Folder Access fix

**IPs Activas:**
- LOCAL: 192.168.100.12 (Wi-Fi) / 192.168.100.8 (Ethernet)
- TAILSCALE: 100.111.32.10
- FORGE: http://192.168.100.12:3100/forge / http://100.111.32.10:3100/forge

**Fixes v2.3:**
- v2.3.0: /api/network + acceso.html QR dinamico con qrcodejs
- Fix clone: Windows LongPathsEnabled=1 + git core.longpaths true
- Fix Defender: Add-MpPreference AllowedApps para cmd, git, GitHubDesktop, Ollama
- Fix nested repo: eliminado runeforge-v2-nucleo dentro de CORE
- Fix dedup: 10 html movidos de raiz a documentacion y propuestas

Repo: https://github.com/yhb86dy52f-lang/runeforge-v2-nucleo
Dashboard: http://192.168.100.12:3100
Status: http://192.168.100.12:3100/api/network

Filosofia: Local-First / Soberania Digital / Auto-reparable
