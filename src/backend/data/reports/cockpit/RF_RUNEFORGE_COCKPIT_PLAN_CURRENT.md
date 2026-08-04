# RF_RUNEFORGE_COCKPIT_PLAN_CURRENT

Fecha: 2026-06-28 17:30:58

Estado: COCKPIT_PLAN_READY

Objetivo:
Crear cabina operativa Runeforge para PC/iPhone sin cambiar núcleo.

Flujo canónico:
INPUT -> ROUTER -> SKILL -> ACTION -> TRACE -> RESPONSE

Estado actual:
- Backend: OK
- Forge UI: OK
- Local AI: OK
- Smoke: OK
- Quality Gate: OK
- D backup: BLOCKED
- Emergency backup: C:\RUNEFOGE_PRO\_SAFE_BACKUPS\runeforge_emergency_current

Módulos Cockpit:
- P1 Dashboard: Estado global Runeforge
- P1 Local AI: Chat personal Runeforge con Ollama
- P1 WebCommand: Acciones safe-readonly
- P1 Actions V4: Acciones controladas allowlist
- P2 Trace: Bitácora JSONL/JSON
- P2 Backups: Estado backup C y bloqueo D
- P3 Memory: Obsidian/JSON/SQLite futuro
- P3 Mobile: iPhone por túnel seguro

Endpoints base:
- GET  /health
- GET  /forge/
- GET  /forge/local-ai.html
- GET  /api/ai/local/health
- GET  /api/ai/local/smoke
- POST /api/ai/local/chat
- GET  /api/webcommand/health
- POST /api/webcommand
- POST /actions/v4/execute
- POST /api/actions/v4/execute

Seguridad:
- NO_RUN_POWERSHELL_LIBRE
- NO_EVAL_FRONTEND
- NO_SECRET_READ
- NO_D_BACKUP
- TRACE_OBLIGATORIO
- FRONTEND_SOLO_ADAPTADOR
- BACKEND_DECIDE
- CURRENT_OVERWRITE_WITH_BACKUP

Siguientes fases:
- RF_RUNEFORGE_COCKPIT_PLAN_REVIEW_CURRENT
- RF_RUNEFORGE_COCKPIT_STATIC_MVP_CURRENT
- RF_RUNEFORGE_COCKPIT_ENDPOINT_BIND_CURRENT
- RF_RUNEFORGE_COCKPIT_MOBILE_CHECK_CURRENT

Backend: NO_TOCADO
PM2: NO_TOCADO
n8n: NO_TOCADO
D: NO_TOCADO

Siguiente: RF_RUNEFORGE_COCKPIT_PLAN_REVIEW_CURRENT
