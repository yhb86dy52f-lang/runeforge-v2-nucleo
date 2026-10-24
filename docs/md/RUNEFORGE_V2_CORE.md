# RUNEFORGE V2 CORE - Documentación Arquitectónica
**Fecha de Reestructuración:** 2026-10-24
**Estado:** Estable / Producción Local

## 1. Resumen Ejecutivo
El ecosistema ha sido purgado de "Bloat" (archivos temporales, backups obsoletos y dashboards duplicados). Se ha implementado un modelo modular estricto con separación de responsabilidades.

## 2. Estructura de Carpetas (Canónica)
C:\RUNEFORGE_V2_CORE
├── core_data\         # Memoria operativa y Prompts maestros para IA
├── docs\md\           # Documentación (este archivo)
├── firmware\          # Código de hardware (ESP32, Radar, GPS)
├── forja\             # Proyectos en desarrollo (Tauri, Svelte)
├── logs\              # Transcripciones de arranque/apagado y logs de error
├── public\dashboards\ # Interfaces UI y simuladores HTML finales
├── scripts\           # Automatización (.ps1, .ahk, .bat)
└── target\            # Binarios compilados de Tauri (Rust)

## 3. Matriz de Servicios y Puertos
| Servicio | Puerto / Proceso | Gestor | Script de Arranque |
| :--- | :--- | :--- | :--- |
| **Whisper IA** | `8081` | Python Venv (CUDA) | `RUNEFORGE_BOOT.ps1` |
| **Fastify (Backend)** | `3100` | PM2 (Node.js) | `pm2 start 1` |
| **Ollama (LLM)** | `11434` | Nativo | `ollama serve` |
| **Tauri Core** | `app.exe` / `8080` | Cargo / NPM | `npm run tauri dev` |
| **Nexus Brain** | `python.exe` | Python Global | `brain_hub.py` |
| **Tailscale Mesh** | Servicio Windows | Windows Svc | `Start-Service` |

## 4. Flujos de Operación
- **Arranque (`rf-boot`):** Levanta Tailscale, Ollama, PM2, Whisper, Brain y Tauri. Espera 12s y audita.
- **Apagón (`rf-stop`):** Mata PM2, Ollama, Tailscale. Fusila procesos Node/Python/Tauri. Libera puertos.
- **Auditoría (`rf-audit`):** Verifica puertos y devuelve reporte forense al portapapeles.