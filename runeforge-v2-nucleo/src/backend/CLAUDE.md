# CLAUDE.md — Runeforge
## Contexto operativo para Claude Code

## IDENTIDAD
Perfil: CINER Maestro / Ingeniero Tinkerbell
Versión: 2026-05-31
Proyecto: Runeforge — local-first, automatización, diagnóstico, memoria técnica.
Máxima: El resultado me da la razón. El papel me la pide.

## RUNEFORGE — FLUJO CANÓNICO
INPUT → ROUTER → SKILL → ACTION → TRACE → MEMORY → RESPONSE
1. Backend primero. UI después.
2. Seguridad por defecto.
3. Trazabilidad obligatoria.
4. Acciones controladas — allowlist únicamente.
5. Cuarentena antes de borrar. Dry-run antes de apply.

## CONTEXTO TÉCNICO
- CCTV: Dahua, Hikvision, EPCOM, Ajax
- GPS: CalAmp LMU/TTU, Wialon, Traccar, Ruptela
- Sensores: Escort TD-600/TD-500, varillas combustible
- Automatización: PowerShell 7, Node.js, TypeScript, Python, SQLite
- Infra: Windows, OpenSSH, Tailscale, PM2, VS Code, Git
- Móvil: iPhone / Termius / Atajos iOS / a-Shell

## ESTADO PROYECTO — 2026-05-31
Core            = OPERATIVO
Event Model V1  = CERRADO / 30 eventos
Graph Model V1  = CERRADO / 81 nodos / 150 edges
Markov V1       = VALIDATION_ONLY — NO producción todavía
Claude Code     = INSTALADO v2.1.158
Siguiente       = RF_MARKOV_RENDER_REVIEW_V1

## SEGURIDAD — BLOQUEADO SIEMPRE
- run_powershell libre
- lectura .env / secretos
- borrado sin cuarentena
- backend/PM2/n8n sin orden explícita
- producción sin rollback

## MODO RESPUESTA
- Español técnico directo. Sin relleno.
- Comandos copiables con rutas Windows completas.
- Abrir carpeta destino al crear archivos (Invoke-Item).
- Dry-run antes de apply.
- Si toca backend: impacto + respaldo + reversa.

## TERMINAL
PC/PowerShell 7: bloques multilinea OK
iPhone/Termius→PC: UNA SOLA LÍNEA, sin here-string
iPhone/a-Shell: scripts pequeños, sandbox ~/Documents/

## BOOTSTRAP
[ESTADO]
contexto_usado=PERFIL_CINER_OPERATIVO_20260531
runeforge=LOCAL_FIRST_BACKEND_FIRST
seguridad=VALIDAR_ANTES_DE_EJECUTAR
siguiente=RF_MARKOV_RENDER_REVIEW_V1
