# RF_RUNEFORGE_COCKPIT_ENDPOINT_BIND_DEEP_DIAG_CURRENT

Fecha: 2026-06-28 18:35:58

Estado: COCKPIT_ENDPOINT_BIND_DEEP_DIAG_REVIEW_REQUIRED
Panel OK: True
Working action: NONE
Working URL: NONE

HTML diag:
- size bytes: 2737
- has RUNEFORGE COCKPIT: True
- has actionPing: False
- has /actions/v4/execute: False
- has /api/actions/v4/execute: False
- has action ping payload: False
- has intent ping payload: False

Tests:
- health: ok=True status=200 error=
- cockpit_html: ok=True status=200 error=
- actions_v4_action_ping: ok=False status=503 error=Response status code does not indicate success: 503 (Service Unavailable).
- actions_v4_intent_ping: ok=False status=503 error=Response status code does not indicate success: 503 (Service Unavailable).
- api_actions_v4_action_ping: ok=False status=503 error=Response status code does not indicate success: 503 (Service Unavailable).
- api_actions_v4_intent_ping: ok=False status=503 error=Response status code does not indicate success: 503 (Service Unavailable).

Backend: NO_TOCADO
PM2: NO_TOCADO
n8n: NO_TOCADO
D: NO_TOCADO

Siguiente: RF_ACTIONS_V4_SCHEMA_READONLY_REVIEW_CURRENT
