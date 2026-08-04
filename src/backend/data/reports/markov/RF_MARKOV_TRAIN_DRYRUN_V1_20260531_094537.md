# RF_MARKOV_TRAIN_DRYRUN_V1

Fecha: 2026-05-31 09:45:37

Estado: MARKOV_TRAIN_DRYRUN_DONE
Eventos leídos: 30
Parse errors: 0
Estados únicos: 16
Transiciones: 29
Transiciones únicas: 27
Backend: NO_TOCADO
PM2: NO_TOCADO
n8n: NO_TOCADO
Acciones automáticas: BLOQUEADAS

## Archivos
- Modelo: C:\RUNEFOGE_PRO\runeforge\data\markov\dryrun\rf_markov_model_v1_dryrun_20260531_094537.json
- Estados CSV: C:\RUNEFOGE_PRO\runeforge\data\markov\dryrun\rf_markov_states_v1_dryrun_20260531_094537.csv
- Transiciones CSV: C:\RUNEFOGE_PRO\runeforge\data\markov\dryrun\rf_markov_transitions_v1_dryrun_20260531_094537.csv
- Trace: C:\RUNEFOGE_PRO\runeforge\data\traces\rf_markov_train_dryrun_v1_20260531_094537.json

## Estados principales
- actions|trace_observed|ok: 7 / freq=0.233333
- n8n|trace_observed|ok: 3 / freq=0.1
- actions|action_execute|ok: 2 / freq=0.066667
- actions|blocked_action|blocked: 2 / freq=0.066667
- actions|memory_written|ok: 2 / freq=0.066667
- actions|patch_applied|ok: 2 / freq=0.066667
- actions|trace_observed|error: 2 / freq=0.066667
- export_cleanup|safe_export_finalized|ok: 2 / freq=0.066667
- event_model|bootstrap_created|ok: 1 / freq=0.033333
- export_cleanup|cleanup_closed|closed: 1 / freq=0.033333

## Transiciones principales
- actions|memory_written|ok -> actions|trace_observed|ok: count=2 / p=1
- actions|trace_observed|ok -> actions|action_execute|ok: count=2 / p=0.285714
- actions|action_execute|ok -> actions|blocked_action|blocked: count=1 / p=0.5
- n8n|trace_observed|ok -> n8n|trace_observed|ok: count=1 / p=0.333333
- n8n|trace_observed|ok -> n8n|patch_applied|ok: count=1 / p=0.333333
- n8n|trace_observed|ok -> actions|memory_written|ok: count=1 / p=0.333333
- n8n|patch_applied|ok -> n8n|memory_written|ok: count=1 / p=1
- n8n|memory_written|ok -> actions|trace_observed|ok: count=1 / p=1
- export_cleanup|safe_export_finalized|ok -> export_cleanup|safe_export_finalized|ok: count=1 / p=0.5
- export_cleanup|safe_export_finalized|ok -> export_cleanup|cleanup_plan_generated|ok: count=1 / p=0.5

## Siguiente
- RF_MARKOV_MODEL_STATUS_V1
