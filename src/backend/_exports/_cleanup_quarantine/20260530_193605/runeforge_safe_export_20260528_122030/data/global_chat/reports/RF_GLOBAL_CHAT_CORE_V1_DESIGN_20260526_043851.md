# RF_GLOBAL_CHAT_CORE_V1

## Objetivo
Crear bus global de chats para Runeforge: entrada normalizada, memoria, trace y acciones seguras.

## Principios
- Backend primero.
- Canales desacoplados.
- IA no ejecuta acciones directo.
- Todo evento útil debe generar trace.
- Markdown para humano, JSONL/SQLite para máquina.

## Endpoints propuestos
- POST /api/chat/global
- GET /api/chat/global/health
- GET /api/chat/global/recent
- POST /api/chat/global/trace

## Estado
estado=DISEÑO_CREADO
backend=NO_TOCADO
siguiente=crear endpoint MVP solo trace
