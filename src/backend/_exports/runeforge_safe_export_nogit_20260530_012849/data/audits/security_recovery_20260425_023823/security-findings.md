# RUNEFORGE SECURITY FINDINGS

Fecha: 2026-04-25T02:38:39
Modo: AUDIT_ONLY_NO_FIX_RECOVERY

## Hallazgos

- HIGH: hay puertos escuchando en 0.0.0.0 o ::.
- MEDIUM: existen archivos .env/.env.*; no se leyó contenido.
- MEDIUM: existen exclusiones Defender.
- MEDIUM: indicadores de secretos en archivos no .env.
- MEDIUM: indicadores de secretos en logs/txt.

## Nota

No se leyó .env.
No se imprimieron secretos.
No se modificó backend, firewall ni Defender.
