# RF_RELAY_LOCAL_RUNTIME_SMOKE_TEST_CURRENT

Fecha: 2026-06-23 13:22:46

Politica salida:
CURRENT_OVERWRITE_WITH_BACKUP

Repo:
C:\RUNEFOGE_PRO\runeforge\lab\github\runeforge-relay-clean

Puerto:
3007

Estado:
SMOKE_TEST_FAILED

Tests:
[
  {
    "name": "health",
    "ok": false,
    "detail": "NO_RESPONSE"
  },
  {
    "name": "api_commands",
    "ok": false,
    "detail": "CATALOG_FAIL"
  },
  {
    "name": "command_schema_blocks_invalid",
    "ok": false,
    "detail": "BLOCK_FAIL"
  },
  {
    "name": "command_allowlist_blocks_unknown",
    "ok": false,
    "detail": "BLOCK_FAIL"
  },
  {
    "name": "whatsapp_webhook_verify",
    "ok": false,
    "detail": "VERIFY_FAIL"
  }
]

Residual risks:
- SMOKE_TEST_FAILED
- PROCESS_EXITED_EARLY

Logs:
- stdout: C:\RUNEFOGE_PRO\runeforge\data\runtime\relay_smoke\rf_relay_smoke_stdout_current.log
- stderr: C:\RUNEFOGE_PRO\runeforge\data\runtime\relay_smoke\rf_relay_smoke_stderr_current.log

Backups:
- current outputs: C:\RUNEFOGE_PRO\runeforge\data\backups\current_overwrite\relay_smoke_test\20260623_132247

Seguridad:
- GitHub: NO_TOCADO
- Drive: NO_TOCADO
- Backend Runeforge: NO_TOCADO
- PM2: NO_TOCADO
- n8n: NO_TOCADO

Siguiente:
RF_RELAY_SMOKE_TEST_REPAIR_CURRENT_V1
