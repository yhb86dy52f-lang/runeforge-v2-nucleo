# RF_RUNEFORGE_COCKPIT_ENDPOINT_BIND_REPAIR_CURRENT

Fecha: 2026-06-28 18:25:03

Estado: COCKPIT_ENDPOINT_BIND_REPAIR_REVIEW_REQUIRED
Panel URL: http://127.0.0.1:3100/forge/cockpit.html
Failed count: 2

Tests:
- health: True — GET /health
- cockpit_html: False — GET /forge/cockpit.html + content check
- local_ai_health: True — GET /api/ai/local/health
- local_ai_smoke: True — GET /api/ai/local/smoke
- local_ai_chat: True — POST /api/ai/local/chat
- webcommand_health: True — GET /api/webcommand/health
- webcommand_status: True — POST /api/webcommand action=status
- webcommand_backend-root: True — POST /api/webcommand action=backend-root
- webcommand_pm2-health: True — POST /api/webcommand action=pm2-health
- actions_v4_ping: False — Response status code does not indicate success: 503 (Service Unavailable).

Archivo tocado:
- C:\RUNEFOGE_PRO\runeforge\app\public\forge\cockpit.html

Backup:
- C:\RUNEFOGE_PRO\runeforge\data\backups\current_overwrite\cockpit_endpoint_bind_repair\20260628_182503

Backend: NO_TOCADO
PM2: NO_TOCADO
n8n: NO_TOCADO
D: NO_TOCADO

Siguiente: RF_RUNEFORGE_COCKPIT_ENDPOINT_BIND_DEEP_DIAG_CURRENT
