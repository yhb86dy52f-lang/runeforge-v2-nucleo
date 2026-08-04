# RF_WHATSAPP_PUBLIC_RELAY_DECISION_CURRENT

- Fecha: 2026-06-15 22:24:00
- Estado: PUBLIC_RELAY_REQUIRED_BEFORE_REAL_SEND
- Decision: PUBLIC_HTTPS_RELAY_MINIMAL
- Motivo: Meta webhook necesita HTTPS publico, pero Runeforge Core debe permanecer privado/local-first
- Public edge: recibir webhook, validar token, normalizar evento, reenviar o encolar hacia core privado
- Private core: router, skill, action, trace, local AI, respuesta controlada
- Real WhatsApp send: NO_REAL_SEND
- Backend: NO_TOCADO
- PM2: NO_TOCADO
- Firewall: NO_TOCADO

## Bloqueado
- REAL_SEND_WITH_PLACEHOLDERS
- OPEN_PORT_3100_PUBLIC
- OPEN_OLLAMA_11434_PUBLIC

## Siguiente
- RF_WHATSAPP_RELAY_PUBLIC_EDGE_SCAFFOLD_V1
