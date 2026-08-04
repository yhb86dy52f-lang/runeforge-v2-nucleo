# RF_EVENT_ACCUMULATION_PLAN_V1

Fecha: 2026-05-31 15:34:01

## Objetivo
- Subir de 30 eventos canónicos a 100.
- Eventos faltantes: 70.
- Acción real: NO_IMPORT_EVENTS.

## Fuentes candidatas
- data\traces: existe=True archivos=81 prioridad=ALTA
- data\reports: existe=True archivos=26 prioridad=ALTA
- data\memory: existe=True archivos=30 prioridad=MEDIA
- data\visual_layout_engine: existe=True archivos=256 prioridad=BAJA_CONTROLADA
- data\webcommand: existe=True archivos=11 prioridad=BAJA_CONTROLADA
- data\n8n_canary_2_20_12: existe=True archivos=860 prioridad=BAJA_CONTROLADA

## Reglas
- No tocar backend.
- No tocar PM2.
- No tocar n8n.
- No importar eventos sin dry-run.
- Priorizar traces y reports sobre carpetas grandes.
- Mantener Markov en VALIDATION_ONLY hasta 100+ eventos.

## Siguiente
- RF_EVENT_ACCUMULATION_DRYRUN_V1
