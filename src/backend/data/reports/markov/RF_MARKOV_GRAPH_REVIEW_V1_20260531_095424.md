# RF_MARKOV_GRAPH_REVIEW_V1

Fecha: 2026-05-31 09:54:24

Estado: MARKOV_GRAPH_VALIDATION_ONLY
CSV: C:\RUNEFOGE_PRO\runeforge\data\markov\graph_export\rf_markov_graph_edges_v1_20260531_095106.csv
Mermaid: C:\RUNEFOGE_PRO\runeforge\data\markov\graph_export\rf_markov_graph_v1_20260531_095106.mmd
JSON: C:\RUNEFOGE_PRO\runeforge\data\markov\graph_export\rf_markov_graph_export_v1_20260531_095106.json

Edges: 27
Edges con p=1: 8
Edges con p>=0.5: 18
Edges con muestra débil total_from<3: 18
Self loops: 3

## Lectura
- El grafo sirve como validación visual del pipeline.
- No usar todavía como motor de decisión operativa.
- Las probabilidades altas son preliminares por bajo volumen de datos.
- Siguiente meta recomendada: acumular 100+ eventos canónicos antes de interpretar patrones fuertes.

## Estados origen más conectados
- actions|trace_observed|ok: 6
- n8n|trace_observed|ok: 3
- actions|action_execute|ok: 2
- actions|blocked_action|blocked: 2
- actions|patch_applied|ok: 2
- actions|trace_observed|error: 2
- export_cleanup|safe_export_finalized|ok: 2
- actions|memory_written|ok: 1
- export_cleanup|cleanup_closed|closed: 1
- export_cleanup|cleanup_plan_generated|ok: 1

## Impacto
- Backend: NO_TOCADO
- PM2: NO_TOCADO
- n8n: NO_TOCADO

## Siguiente
- RF_MARKOV_GRAPH_RENDER_V1
