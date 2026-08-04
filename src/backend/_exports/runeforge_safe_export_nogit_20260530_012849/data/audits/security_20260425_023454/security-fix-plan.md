# RUNEFORGE SECURITY FIX PLAN

Fecha: 2026-04-25T02:35:32
Estado: Pendiente de revisión humana

## Orden recomendado de corrección

1. Confirmar que .env no está rastreado por git.
2. Revisar .gitignore.
3. Revisar puertos en 0.0.0.0 / ::.
4. Revisar reglas firewall relevantes.
5. Revisar exclusiones Defender.
6. Revisar indicadores de secretos en archivos/logs sin exponer valores.
7. Revisar npm audit.
8. Aplicar correcciones una por una con rollback.

## Regla

No aplicar fixes hasta que el usuario pegue audit-summary.txt y se confirme el siguiente bloque.
