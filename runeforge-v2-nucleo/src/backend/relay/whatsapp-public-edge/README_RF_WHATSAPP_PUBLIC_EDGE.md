# RF_WHATSAPP_PUBLIC_EDGE

Estado: SCAFFOLD_ONLY

Rol: borde HTTPS publico minimo para Meta WhatsApp Webhooks.

No es nucleo. No ejecuta PowerShell. No lee secretos. No expone Runeforge Core.

Endpoints:
- GET /health
- GET /webhooks/whatsapp
- POST /webhooks/whatsapp

Siguiente: decidir hosting publico y credenciales reales.

Opciones futuras: VPS, Render, Railway, Fly, Cloudflare Worker o n8n publico como relay.

Runeforge Core permanece privado/local-first.
