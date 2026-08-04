# RUNEFORGE — HITO CORE ↔ n8n TASK INTAKE

Fecha: 2026-05-23 10:55:03

## Estado

[PROGRESO RUNEFORGE]
Global   [████████░░] 83%
n8n      [██████████] 100%
Core     [█████████░] 85%
Fase     CORE_N8N_TASK_INTAKE_CERRADO
Estado   PING_OK / TASK_INTAKE_OK / TRACE_OK

## Resultado

Runeforge Core ya puede consumir n8n canary mediante endpoints internos.

## Endpoints Core

GET  http://127.0.0.1:3100/integrations/n8n/ping
GET  http://127.0.0.1:3100/api/integrations/n8n/ping

POST http://127.0.0.1:3100/integrations/n8n/task-intake
POST http://127.0.0.1:3100/api/integrations/n8n/task-intake

## Endpoint n8n

POST http://127.0.0.1:5680/webhook/rf-task-intake-v2

## Workflow n8n validado

ID      : rf_task_intake_v2
Nombre  : RF_N8N_TASK_INTAKE_V2
Estado  : active=true
Modo    : POST / responseMode=lastNode

## Backend

PM2        : runeforge-mvp
Core       : http://127.0.0.1:3100
Ruta tocada: C:\RUNEFOGE_PRO\runeforge\app\src\modules\integrations\n8n.routes.js
Runtime n8n original: NO_TOCADO

## Validación final

ParserOk              : True
Pm2RestartExitCode    : 0
HealthOk              : True
N8nTaskDirectOk       : True
CoreTaskIntakeOk      : True
CoreTaskIntakeAliasOk : True

## Siguiente fase

DISEÑAR_WORKFLOW_REAL_V3_CON_ACCIONES_CONTROLADAS