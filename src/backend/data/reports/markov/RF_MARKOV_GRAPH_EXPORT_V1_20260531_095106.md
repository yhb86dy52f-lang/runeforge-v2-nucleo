# RF_MARKOV_GRAPH_EXPORT_V1

Fecha: 2026-05-31 09:51:06

Estado: MARKOV_GRAPH_EXPORT_DONE
Modelo fuente: C:\RUNEFOGE_PRO\runeforge\data\markov\dryrun\rf_markov_model_v1_dryrun_20260531_094537.json
Estados: 16
Transiciones: 27
Policy OK: True

## Archivos generados
- Mermaid: C:\RUNEFOGE_PRO\runeforge\data\markov\graph_export\rf_markov_graph_v1_20260531_095106.mmd
- DOT: C:\RUNEFOGE_PRO\runeforge\data\markov\graph_export\rf_markov_graph_v1_20260531_095106.dot
- CSV edges: C:\RUNEFOGE_PRO\runeforge\data\markov\graph_export\rf_markov_graph_edges_v1_20260531_095106.csv
- JSON export: C:\RUNEFOGE_PRO\runeforge\data\markov\graph_export\rf_markov_graph_export_v1_20260531_095106.json
- Trace: C:\RUNEFOGE_PRO\runeforge\data\traces\rf_markov_graph_export_v1_20260531_095106.json

Backend: NO_TOCADO
PM2: NO_TOCADO
n8n: NO_TOCADO

## Top states
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

## Top transitions
- actions|memory_written|ok -> actions|trace_observed|ok: count=2 / p=1
- actions|trace_observed|ok -> actions|action_execute|ok: count=2 / p=0.285714
- actions|action_execute|ok -> actions|trace_observed|ok: count=1 / p=0.5
- actions|blocked_action|blocked -> actions|patch_applied|ok: count=1 / p=0.5
- actions|blocked_action|blocked -> system|memory_written|ok: count=1 / p=0.5
- actions|patch_applied|ok -> actions|memory_written|ok: count=1 / p=0.5
- actions|patch_applied|ok -> actions|trace_observed|error: count=1 / p=0.5
- actions|trace_observed|error -> export_cleanup|safe_export_finalized|ok: count=1 / p=0.5
- actions|trace_observed|error -> system|patch_applied|ok: count=1 / p=0.5
- actions|trace_observed|ok -> actions|blocked_action|blocked: count=1 / p=0.142857

## Mermaid preview
```mermaid
flowchart TD
  S6["actions|trace_observed|ok<br/>count=7 freq=0.233333"]
  S14["n8n|trace_observed|ok<br/>count=3 freq=0.1"]
  S1["actions|action_execute|ok<br/>count=2 freq=0.066667"]
  S2["actions|blocked_action|blocked<br/>count=2 freq=0.066667"]
  S3["actions|memory_written|ok<br/>count=2 freq=0.066667"]
  S4["actions|patch_applied|ok<br/>count=2 freq=0.066667"]
  S5["actions|trace_observed|error<br/>count=2 freq=0.066667"]
  S11["export_cleanup|safe_export_finalized|ok<br/>count=2 freq=0.066667"]
  S7["event_model|bootstrap_created|ok<br/>count=1 freq=0.033333"]
  S8["export_cleanup|cleanup_closed|closed<br/>count=1 freq=0.033333"]
  S9["export_cleanup|cleanup_plan_generated|ok<br/>count=1 freq=0.033333"]
  S10["export_cleanup|move_to_quarantine|ok<br/>count=1 freq=0.033333"]
  S12["n8n|memory_written|ok<br/>count=1 freq=0.033333"]
  S13["n8n|patch_applied|ok<br/>count=1 freq=0.033333"]
  S15["system|memory_written|ok<br/>count=1 freq=0.033333"]
  S16["system|patch_applied|ok<br/>count=1 freq=0.033333"]
  S3 -->|p=1 count=2| S6
  S6 -->|p=0.285714 count=2| S1
  S1 -->|p=0.5 count=1| S2
  S14 -->|p=0.333333 count=1| S14
  S14 -->|p=0.333333 count=1| S13
  S14 -->|p=0.333333 count=1| S3
  S13 -->|p=1 count=1| S12
  S12 -->|p=1 count=1| S6
  S11 -->|p=0.5 count=1| S11
  S11 -->|p=0.5 count=1| S9
  S10 -->|p=1 count=1| S8
  S9 -->|p=1 count=1| S10
  S8 -->|p=1 count=1| S7
  S6 -->|p=0.142857 count=1| S14
  S6 -->|p=0.142857 count=1| S6
  S6 -->|p=0.142857 count=1| S5
  S6 -->|p=0.142857 count=1| S4
  S6 -->|p=0.142857 count=1| S2
  S5 -->|p=0.5 count=1| S16
  S5 -->|p=0.5 count=1| S11
  S4 -->|p=0.5 count=1| S5
  S4 -->|p=0.5 count=1| S3
  S2 -->|p=0.5 count=1| S15
  S2 -->|p=0.5 count=1| S4
  S1 -->|p=0.5 count=1| S6
  S15 -->|p=1 count=1| S6
  S16 -->|p=1 count=1| S6
```

## Siguiente
- RF_MARKOV_GRAPH_REVIEW_V1
