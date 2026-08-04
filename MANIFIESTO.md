# MANIFIESTO DE MIGRACIÓN Y ESTABILIZACIÓN CORE
Fecha: 2026-08-03 02:00:00
Origen: C:\RUNEFOGE_PRO
Destino: C:\RUNEFORGE_V2_CORE

## Principios Fundamentales:
- **Local-First:** CERO dependencia de nubes externas para inferencia y control.
- **Bajo Consumo:** Optimizado para hardware local (Ryzen 3 3200G + GTX 1660 SUPER).
- **Resiliencia:** Procesos supervisados vía PM2 con `ecosystem.config.js` inmutable.
- **Tolerancia Cero a Invención:** Logs estructurados e interfaces de diagnóstico en tiempo real.

## Módulos Migrados y Funcionales:
- Backend Engine (src/backend) - ID PM2: 0
- WhatsApp Relay Service (src/relay) - ID PM2: 1
- Base de Conocimiento (knowledge)
- Scripts de Automatización, Diagnóstico y Amarre (scripts)

## Protocolo de Amarre (Estado Actual):
- **Arranque silencioso:** Se ejecuta mediante `runeforge_start.bat` (lanzador .vbs opcional para invisibilidad total).
- **Reseteo de emergencia:** `runeforge_amarre.ps1` restaura el sistema en 10 segundos.
- **Inferencia local:** Ollama iniciado en segundo plano con `start /min ollama serve`.
- **Forge UI:** `http://localhost:3100/`
- **PWA Offline-First:** `http://localhost:3100/pwa`

El núcleo v2.0 se encuentra 100% operativo y en estado estable. El caos estructural ha sido domado.