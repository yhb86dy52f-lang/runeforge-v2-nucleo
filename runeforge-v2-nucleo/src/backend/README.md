# Runeforge MVP

Backend local-first para Windows + PowerShell 7 + Node.js.

## Incluye
- GET `/health`
- GET `/status`
- POST `/command`
- GET `/api/forge`
- Webhook base para WhatsApp Cloud API (apagado por defecto)
- Logs básicos en `data/logs/runeforge.log`
- Allowlist de comandos

## Arranque rápido
1. Copia `.env.example` a `.env`
2. Instala dependencias con `npm install`
3. Ejecuta `npm run dev`

## Rutas
- `GET /health`
- `GET /status`
- `POST /command`
- `GET /api/forge`
- `GET /api/relay/whatsapp/webhook`
- `POST /api/relay/whatsapp/webhook`

## Seguridad base
- Nunca subas `.env`
- No expongas el puerto públicamente
- Usa Tailscale para acceso remoto privado
- Mantén comandos en allowlist
