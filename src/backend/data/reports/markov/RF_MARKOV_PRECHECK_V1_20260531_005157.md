# RF_MARKOV_PRECHECK_V1

Fecha: 2026-05-31 00:51:57

Estado: MARKOV_PRECHECK_OK
Eventos: 30
Parse errors: 0
Estados: 30
Estados únicos: 16
Transiciones: 29
Transiciones únicas: 27
Ready for train: True

## Estados principales
- actions|trace_observed|ok: 7
- n8n|trace_observed|ok: 3
- actions|action_execute|ok: 2
- actions|blocked_action|blocked: 2
- actions|memory_written|ok: 2
- actions|patch_applied|ok: 2
- actions|trace_observed|error: 2
- export_cleanup|safe_export_finalized|ok: 2
- event_model|bootstrap_created|ok: 1
- export_cleanup|cleanup_closed|closed: 1

## Transiciones principales
- actions|memory_written|ok, actions|trace_observed|ok: 2
- actions|trace_observed|ok, actions|action_execute|ok: 2
- actions|action_execute|ok, actions|blocked_action|blocked: 1
- n8n|trace_observed|ok, n8n|trace_observed|ok: 1
- n8n|trace_observed|ok, n8n|patch_applied|ok: 1
- n8n|trace_observed|ok, actions|memory_written|ok: 1
- n8n|patch_applied|ok, n8n|memory_written|ok: 1
- n8n|memory_written|ok, actions|trace_observed|ok: 1
- export_cleanup|safe_export_finalized|ok, export_cleanup|safe_export_finalized|ok: 1
- export_cleanup|safe_export_finalized|ok, export_cleanup|cleanup_plan_generated|ok: 1

## Impacto
- Backend: NO_TOCADO
- PM2: NO_TOCADO
- n8n: NO_TOCADO

## Siguiente
- RF_MARKOV_TRAIN_DRYRUN_V1 si Ready for train = True
