# RF_RELAY_SOURCE_SYNC_FIX_PLAN_V1

Fecha: 2026-06-22 02:04:49

## Estado

Repo limpio:
C:\RUNEFOGE_PRO\runeforge\lab\github\runeforge-relay-clean

Status:
FIX_PLAN_READY

Next:
RF_RELAY_SOURCE_SYNC_PATCH_V1

## Riesgos detectados

- INDEX_EXEC_PRESENT
- WA_SIGNATURE_DEFAULT_FALSE
- CATALOG_STARTSWITH_PATH_CHECK
- ENV_EXAMPLE_IDENTIFIABLE_VALUES
- INDEX_TS_NOT_USING_RUNNER_MODULE

## Fixes propuestos

- P0_001_SOURCE_SYNC_INDEX_TS: Reemplazar src/index.ts por entrada modular que use env, catalog, runner, logs y router WhatsApp.
- P0_002_WA_SIGNATURE_DEFAULT_TRUE: Cambiar default de WA_VALIDATE_SIGNATURE a true y fallar si falta WA_APP_SECRET cuando está activo.
- P0_003_ENV_EXAMPLE_SANITIZE: Sustituir valores identificables por placeholders genéricos y marcar rotación manual de credenciales expuestas.
- P1_001_STRICT_PATH_VALIDATION: Sustituir startsWith por path.relative + extensión .ps1 + rechazo absoluto/traversal.
- P1_002_COMMAND_SCHEMA: Agregar Zod schema para POST /command.

## Seguridad

- GitHub: NO_TOCADO
- Drive: NO_TOCADO
- Backend Runeforge: NO_TOCADO
- PM2: NO_TOCADO
- n8n: NO_TOCADO

## Nota

Este plan NO aplica cambios. Solo prepara el patch controlado sobre el clone limpio.
