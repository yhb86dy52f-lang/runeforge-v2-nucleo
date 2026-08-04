# RF_GRAPH_MODEL_STATUS_V1

Fecha: 2026-05-30 23:58:42

Estado: GRAPH_MODEL_OK
Nodes total: 81
Edges total: 150
Node parse errors: 0
Edge parse errors: 0
Node duplicates: 0
Edge duplicates: 0
Invalid edges: 0
Orphan edges: 0

## Node types
- event: 30
- trace_file: 30
- action: 10
- domain: 5
- status: 4
- risk: 2

## Relaciones
- ejecuto_accion: 30
- pertenece_a_dominio: 30
- registrado_en: 30
- tiene_estado: 30
- tiene_riesgo: 30

## Impacto
- Backend: NO_TOCADO
- PM2: NO_TOCADO
- n8n: NO_TOCADO

## Siguiente
- RF_MARKOV_PRECHECK_V1 si Estado = GRAPH_MODEL_OK
