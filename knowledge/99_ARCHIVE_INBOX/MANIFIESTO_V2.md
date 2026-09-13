# MANIFIESTO RUNEFORGE v2.0 - Soberanía Digital Local-First

> **"Tu infraestructura, tus reglas, tus datos. Cero nube."**

## Principios

1. **Local-First Absoluto**
   - Todo corre en `C:\RUNEFORGE_V2_CORE`
   - Sin dependencias de nube para operación crítica
   - Datos en `src/backend/data/` nunca salen sin cifrado

2. **Soberanía Digital**
   - Código auditable, sin telemetría oculta
   - Modelos IA locales `qwen2.5:1.5b` vía Ollama :11434
   - Comunicación directa, sin intermediarios

3. **Bajo Consumo**
   - Backend Fastify <100MB RAM
   - Relay <70MB RAM
   - Modelo 1.5B optimizado para CPU

4. **Modular**
   - 10 pestañas independientes
   - API `/api/chat`, `/api/webcommand`, `/health`
   - PM2 orquesta, no acopla

## Arquitectura de Poder

```
INPUT > ROUTER > SKILL > ACTION > TRACE > MEMORY > RESPONSE
```

- **INPUT:** Dashboard, PWA, WhatsApp Relay :3198
- **ROUTER:** Fastify :3100 - skill-router.js
- **SKILL:** general.js, system.js, telemetria.js
- **ACTION:** forge, mission, control, deepseek, etc.
- **TRACE:** `data/traces/rf_*.json` - JSONL auditables
- **MEMORY:** `src/knowledge/MASTER_MEMORY.md`
- **RESPONSE:** Chat, WebCommand, Bitácora PRO

## Compromiso

- No inventar datos. Si no existe, se solicita.
- No asumir rutas. Todo se verifica con `Test-Path`.
- Scripts PowerShell con `Set-Clipboard` final.
- Seguridad: `.env` y `ssh_host_*_key` jamás en Git.

## Estado Actual v2.0.0

- ✅ Backend 3100 ONLINE (Fastify)
- ✅ Relay 3198 ONLINE (WhatsApp)
- ✅ Ollama 11434 ONLINE (qwen2.5:1.5b)
- ✅ Dashboard 10 pestañas activo
- ✅ GitHub limpio: 0 secretos, tag v2.0.0

---

*Soberanía no es aislamiento. Es elegir cuándo conectarse.*
