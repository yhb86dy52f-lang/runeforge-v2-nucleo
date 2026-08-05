# MANIFIESTO DE MIGRACIÓN Y ESTABILIZACIÓN CORE
Fecha: 2026-08-05 00:56:00
Origen: C:\RUNEFOGE_PRO
Destino: C:\RUNEFORGE_V2_CORE
Versión: v2.1.0 - Hotfix Ollama + Chat OK

## Principios Fundamentales:
- **Local-First:** CERO dependencia de nubes externas para inferencia y control. Ollama 11434 local con 4 modelos.
- **Bajo Consumo:** Optimizado para hardware local (Ryzen 3 3200G + GTX 1660 SUPER) - Backend 96.9MB, Relay 65.2MB.
- **Resiliencia:** Procesos supervisados vía PM2 con `ecosystem.config.js` inmutable + pm2 save. Auto-reparación Ollama.
- **Tolerancia Cero a Invención:** Logs estructurados + node --check + endpoint /api/ollama/status + Set-Clipboard obligatorio.

## Módulos Migrados y Funcionales v2.1:
- Backend Engine (src/backend) - ID PM2: 3 - Online 96.9MB - Fastify v2.1 con routerOptions fix
- WhatsApp Relay Service (src/relay) - ID PM2: 1 - Online 65.2MB
- Ollama LLM Service - PID 11828 - 4 modelos: qwen2.5:1.5b (activo), gemma2:2b, deepseek-coder, nomic-embed-text
- Base de Conocimiento (knowledge)
- Scripts de Automatización, Diagnóstico y Amarre (scripts)

## Protocolo de Amarre v2.1 (Estado Actual Verificado 00:55:59):
- **Arranque silencioso:** Se ejecuta mediante `runeforge_start.bat` (lanzador .vbs opcional).
- **Reseteo de emergencia:** `runeforge_amarre.ps1` restaura el sistema en 10 segundos.
- **Inferencia local:** Ollama iniciado en segundo plano con `start /min ollama serve` - Verificado LISTENING 0.0.0.0:11434.
- **Forge UI:** `http://localhost:3100/` y `http://192.168.100.8:3100/forge` - Chat OK 200 - QR iPhone operativo
- **PWA Offline-First:** `http://localhost:3100/pwa`
- **Nuevo Endpoint Diagnóstico:** `http://localhost:3100/api/ollama/status` -> { ok:true, online:true, models:[] }
- **Chat API:** `http://localhost:3100/api/chat` -> 200 OK - 1030ms - qwen2.5:1.5b

## Fix v2.1 Aplicado (2026-08-05 00:44 - 00:55):
1. Fix Ollama apagado -> LISTENING 11828
2. Fix FSTDEP022 -> routerOptions: { ignoreTrailingSlash: true }
3. Fix SyntaxError fetch(http://) -> fetch('http://') + node --check OK
4. Nuevo /api/ollama/status para diagnóstico previo
5. Rama mejora/fix-ollama-chat (3a3fe40) mergeada a main y pusheada

El núcleo v2.1 se encuentra 100% operativo, verificado con test real de chat y en estado estable. El caos estructural ha sido domado.
