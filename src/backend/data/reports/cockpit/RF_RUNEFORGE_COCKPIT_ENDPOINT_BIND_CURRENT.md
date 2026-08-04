# RF_RUNEFORGE_COCKPIT_ENDPOINT_BIND_CURRENT

Fecha: 2026-06-28 18:19:10

Estado: COCKPIT_ENDPOINT_BIND_REVIEW_REQUIRED
Base URL: http://127.0.0.1:3100
Failed count: 2

Tests:
- health: True — GET /health
- cockpit_html: False — GET /forge/cockpit.html
- local_ai_health: True — GET /api/ai/local/health
- local_ai_smoke: True — GET /api/ai/local/smoke
- local_ai_chat: True — POST /api/ai/local/chat
- webcommand_health: True — GET /api/webcommand/health
- webcommand_status: True — POST /api/webcommand action=status
- webcommand_backend-root: True — POST /api/webcommand action=backend-root
- webcommand_pm2-health: True — POST /api/webcommand action=pm2-health
- actions_v4_ping: False — Response status code does not indicate success: 503 (Service Unavailable).

Backend: NO_TOCADO
PM2: NO_TOCADO
n8n: NO_TOCADO
D: NO_TOCADO

Siguiente: RF_RUNEFORGE_COCKPIT_ENDPOINT_BIND_REPAIR_CURRENT
