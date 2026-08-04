# RF_CURRENT_OVERWRITE_POLICY_V1

Fecha actualización: 2026-05-31 18:09:47

## Regla principal
- Los archivos CURRENT representan el estado vivo actual del sistema.
- Los archivos CURRENT se sobrescriben.
- No crear archivos nuevos con timestamp para estados vivos, planes activos o briefs actuales.

## Se sobrescriben
- *_CURRENT.md
- *_current.json
- *_STATUS_CURRENT.md
- *_PLAN_CURRENT.md
- RF_SESSION_BRIEF_CURRENT.md
- RF_MARKOV_V1_CURRENT_STATUS.md
- RF_EVENT_ACCUMULATION_PLAN_CURRENT.md

## Se versionan solo como hito
- *_CLOSE_MEMORY_YYYYMMDD_HHMMSS.md
- *_APPLY_YYYYMMDD_HHMMSS.md
- *_BACKUP_YYYYMMDD_HHMMSS.*
- *_EXPORT_FINAL_YYYYMMDD_HHMMSS.*

## No versionar por rutina
- status repetidos
- prechecks repetidos
- planes activos
- briefs actuales
- roadmaps actuales
- policies activas

## Política de limpieza
- No borrar histórico ya creado sin plan de cuarentena.
- Si un archivo viejo estorba, mover primero a cuarentena.
- Cuarentena antes de borrar.

## Impacto
- Backend: NO_TOCADO
- PM2: NO_TOCADO
- n8n: NO_TOCADO
