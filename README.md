# Runeforge v2.1 - Ecosistema Local-First - HOTFIX OK

![Local-First](https://img.shields.io/badge/Local--First-100%25-00C853?style=for-the-badge)
![Fastify](https://img.shields.io/badge/Backend-Fastify%20v2.1-black?style=flat-square&logo=fastify)
![Ollama](https://img.shields.io/badge/LLM-Ollama%20qwen2.5%3A1.5b%20OK-blueviolet?style=flat-square&logo=ollama)
![PM2](https://img.shields.io/badge/PM2-2%20services%20online%2096.9MB-2B037A?style=flat-square&logo=pm2)
![Chat](https://img.shields.io/badge/Chat-200%20OK%201030ms-brightgreen?style=flat-square)
![Version](https://img.shields.io/badge/Version-v2.1.0%20Hotfix-blue?style=flat-square)

Centro de operaciones digital personal, 100% local, sin dependencias de nube. Integra gestión de conocimiento, automatización, IA ligera y telemetría.

> Filosofía: **Local-First / Soberanía Digital / Bajo Consumo / Modular / Auto-reparable**

Repo: `https://github.com/yhb86dy52f-lang/runeforge-v2-nucleo` | Dashboard: `http://localhost:3100` | Forge: `http://192.168.100.8:3100/forge` | Status: `http://localhost:3100/api/ollama/status`

**Último hotfix:** 2026-08-05 00:55:59 - Chat responde "¡Hola! ¿Cómo puedo ayudarte hoy?" - 1030ms - qwen2.5:1.5b

---

## 🚀 Arquitectura v2.1

```mermaid
graph TD
    U[Usuario - iPhone QR 192.168.100.8:3100/forge] --> D[Dashboard :3100<br/>HTML + CSS + Vanilla JS]
    D --> B[Backend Fastify v2.1 :3100<br/>src/backend/app/src/server.js<br/>routerOptions fix + /api/ollama/status]
    B --> O[Ollama :11434 PID 11828<br/>qwen2.5:1.5b, gemma2:2b, deepseek-coder, nomic-embed-text]
    B --> R[Relay WhatsApp :3198 - 65.2MB]
    B --> DOCS[/docs<br/>documentacion y propuestas]
    B --> TRACE[data/traces JSONL]
    R --> WA[WhatsApp]
    O --> QWEN[(Modelo Local 1030ms)]

    subgraph Frontend 10 Pestañas
      D --> F1[forge - Bitácora PRO]
      D --> F2[mission - Mission Control]
      D --> F3[control - Control IA]
      D --> F4[pwa - Offline]
      D --> F5[acceso - iPhone QR - VERIFICADO OK]
      D --> F6[deepseek - Chat minimal]
      D --> F7[infograma - Chart.js/Plotly]
      D --> F8[roadmap - Roadmap]
      D --> F9[chat - Chat Simple - 200 OK]
      D --> F10[docs - Documentación]
    end
```

**Stack v2.1 Verificado:**
- Backend: `Fastify + Node.js` - `ecosystem.config.js` - PM2 IDs 3 y 1 - 96.9MB/65.2MB - Puerto 3100 - routerOptions fix
- Frontend: `public/index.html` + `public/pages/*.html` - Vanilla JS + Three.js + Chart.js - Chat OK
- LLM: `Ollama` 4 modelos - `qwen2.5:1.5b` activo - Puerto 11434 PID 11828 LISTENING
- Relay: Node.js Puerto 3198 - 65.2MB
- Meta-Prompt: `RUNEFORGE META-PROMPT UNIFICA.md` v1.3 inyectado como system prompt

---

## ⚡ Instalación Rápida v2.1

### Requisitos
- Node.js 20+ - `node -v`
- PM2 - `npm i -g pm2`
- Ollama - `https://ollama.com`
- PowerShell 5.1+ (ADMIN)

### Paso a Paso Verificado 00:55:59

**1. Clonar y entrar:**
```powershell
git clone https://github.com/yhb86dy52f-lang/runeforge-v2-nucleo.git
Set-Location runeforge-v2-nucleo
```

**2. Modelo IA local (4 modelos):**
```powershell
ollama serve
ollama pull qwen2.5:1.5b
ollama pull gemma2:2b
ollama list # debe mostrar 4 modelos
```

**3. Arranque:**
```powershell
.\runeforge_launcher.ps1
pm2 list # debe mostrar backend 96.9MB online y relay 65.2MB online
```

**4. Verificación v2.1 (OBLIGATORIO):**
```powershell
Invoke-RestMethod http://localhost:3100/api/ollama/status # ok:true, online:true, 4 modelos
Invoke-RestMethod -Uri http://localhost:3100/api/chat -Method POST -Body (@{message="Hola"} | ConvertTo-Json) -ContentType "application/json"
# -> response: "¡Hola! ¿Cómo puedo ayudarte hoy?" - 1030ms
```

---

## 🔌 Endpoints Principales v2.1

| Endpoint | Método | Descripción | Estado v2.1 |
|---|---|---|---|
| `/health` | GET | Health check - uptime, modelo, ollama | ✅ OK |
| `/api/chat` | POST | Chat contra Ollama local - 1030ms | ✅ 200 OK |
| `/api/ollama/status` | GET | **NUEVO v2.1** - Estado Ollama + modelos | ✅ ok:true online:true |
| `/api/webcommand` | POST | Comandos web remotos | ✅ OK |
| `/api/webcommand/health` | GET | Health del webcommand | ✅ OK |
| `/api/manifiesto` | GET | Manifiesto Runeforge | ✅ OK |
| `/api/estatus` | GET | Estatus servicios | ✅ OK |
| `/docs` | GET | Documentación técnica | ✅ OK |

Ejemplo chat v2.1 verificado:
```powershell
Invoke-RestMethod -Uri http://localhost:3100/api/chat -Method POST -Body (@{message="Hola Runeforge"} | ConvertTo-Json) -ContentType "application/json"
# -> { "response": "¡Hola! ¿Cómo puedo ayudarte hoy?", "meta": { "model":"qwen2.5:1.5b","elapsed_ms":1030 } }
```

---

## 🛡️ Seguridad Local-First + Fix v2.1

**Fixes v2.1:**
- `FSTDEP022` corregido con `routerOptions`
- `SyntaxError fetch(http://)` corregido con `node --check` previo a PM2 restart
- Backup automático `server.js.bak_20260805_0032`
- Validación `pm2 list` + `/api/ollama/status` + `/api/chat` antes de push

Repo actual: v2.1.0 hotfix - 3a3fe40 mergeado a main - 0 secretos - Chat OK

---

## 🗺️ Roadmap Actualizado

- [x] v2.0.0 - Unificación completa - Dashboard 10 pestañas + Fastify + Ollama + PM2
- [x] v2.1.0 - Hotfix Ollama + Chat OK - Fix FSTDEP022 + /api/ollama/status + SyntaxError fetch + Chat 200 OK 1030ms (2026-08-05 00:55:59)
- [ ] v2.2 - Opciones: A) Frontend Chat con mensaje humano "Ollama apagado - reintentando" usando /api/ollama/status, B) Dashboard muestra 4 modelos + RAM, C) Launcher auto-levanta ollama serve si puerto 11434 cerrado
- [ ] v2.3 - PWA push + Tailscale QR dinámico
- [ ] v2.4 - Bitácora PRO con Three.js manual 3D v2

---

*Generado en MODO DOCUMENTACION - Runeforge v2.1 - Hotfix verificado 2026-08-05 00:55:59 - Chat OK*
