# Runeforge v2.0 - Ecosistema Local-First

![Local-First](https://img.shields.io/badge/Local--First-100%25-00C853?style=for-the-badge)
![Fastify](https://img.shields.io/badge/Backend-Fastify-black?style=flat-square&logo=fastify)
![Ollama](https://img.shields.io/badge/LLM-Ollama%20qwen2.5%3A1.5b-blueviolet?style=flat-square&logo=ollama)
![PM2](https://img.shields.io/badge/PM2-2%20services%20online-2B037A?style=flat-square&logo=pm2)
![PWA](https://img.shields.io/badge/PWA-Offline%20Ready-FF6D00?style=flat-square&logo=pwa)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)

Centro de operaciones digital personal, 100% local, sin dependencias de nube. Integra gestión de conocimiento, automatización, IA ligera y telemetría.

> Filosofía: **Local-First / Soberanía Digital / Bajo Consumo / Modular**

Repo: `https://github.com/yhb86dy52f-lang/runeforge-v2-nucleo` | Dashboard: `http://localhost:3100` | Docs: `http://localhost:3100/docs`

---

## 🚀 Arquitectura

```mermaid
graph TD
    U[Usuario] --> D[Dashboard :3100<br/>HTML + CSS + Vanilla JS]
    D --> B[Backend Fastify :3100<br/>src/backend/app/src/server.js]
    B --> O[Ollama :11434<br/>qwen2.5:1.5b]
    B --> R[Relay WhatsApp :3198]
    B --> DOCS[/docs<br/>documentacion y propuestas]
    B --> TRACE[data/traces JSONL]
    R --> WA[WhatsApp]
    O --> QWEN[(Modelo Local)]

    subgraph Frontend 10 Pestañas
      D --> F1[forge - Bitácora PRO]
      D --> F2[mission - Mission Control]
      D --> F3[control - Control IA]
      D --> F4[pwa - Offline]
      D --> F5[acceso - iPhone QR]
      D --> F6[deepseek - Chat minimal]
      D --> F7[infograma - Chart.js/Plotly]
      D --> F8[roadmap - Roadmap]
      D --> F9[chat - Chat Simple]
      D --> F10[docs - Documentación]
    end
```

**Stack:**
- Backend: `Fastify + Node.js` - `ecosystem.config.js` - PM2 - Puerto 3100
- Frontend: `public/index.html` + `public/pages/*.html` - Vanilla JS + Three.js + Chart.js
- LLM: `Ollama` `qwen2.5:1.5b` Puerto 11434
- Relay: Node.js Puerto 3198
- Meta-Prompt: `RUNEFORGE META-PROMPT UNIFICA.md` inyectado como system prompt

---

## 📁 Estructura Confirmada

```
C:\RUNEFORGE_V2_CORE\
├── public\
│   ├── index.html                 # Dashboard principal
│   ├── pages\                     # 10 pestañas
│   │   ├── forge.html             # Bitácora PRO - CRUD + Three.js
│   │   ├── mission.html           # Mission Control - HW + radar IA
│   │   ├── control.html           # Control IA - temp, presets, webcommand
│   │   ├── pwa.html               # PWA Offline - IndexedDB queue
│   │   ├── acceso.html            # Acceso iPhone - QR local + Tailscale
│   │   ├── deepseek.html          # Chat minimalista
│   │   ├── infograma.html         # KPIs Chart.js/Plotly
│   │   ├── roadmap.html           # Roadmap interactivo
│   │   └── chat.html              # Chat Simple vs Ollama
│   └── documentacion y propuestas\index.html # Servido en /docs
├── src\backend\app\src\server.js  # Fastify main
├── RUNEFORGE META-PROMPT UNIFICA.md
├── MANIFIESTO.md
├── ESTATUS.md
├── runeforge_launcher.ps1         # Launcher principal PowerShell
├── runeforge_start.bat            # Launcher .bat
├── ecosystem.config.js            # PM2 config
├── .env.example
├── .gitignore
└── README.md
```

---

## ⚡ Instalación Rápida

### Requisitos
- Node.js 20+ - `node -v`
- PM2 - `npm i -g pm2`
- Ollama - `https://ollama.com`
- PowerShell 5.1+ (ADMIN)

### Paso a Paso

**1. Clonar y entrar:**
```powershell
git clone https://github.com/yhb86dy52f-lang/runeforge-v2-nucleo.git
Set-Location runeforge-v2-nucleo
# Si tu carpeta es C:\RUNEFORGE_V2_CORE, usa esa
```

**2. Instalar dependencias:**
```powershell
npm install
npm install --prefix src\backend\app
```

**3. Modelo IA local:**
```powershell
ollama serve
ollama pull qwen2.5:1.5b
ollama list
```

**4. Variables de entorno:**
```powershell
Copy-Item .env.example .env -ErrorAction SilentlyContinue
Copy-Item src\backend\app\.env.example src\backend\app\.env -ErrorAction SilentlyContinue
# Edita .env con tus puertos si cambias 3100/3198/11434
```

**5. Arranque con launcher (recomendado):**
```powershell
# Opción A - PowerShell
.\runeforge_launcher.ps1

# Opción B - BAT
.\runeforge_start.bat

# Opción C - Manual PM2
pm2 start ecosystem.config.js --env development
pm2 list
pm2 logs runeforge-backend --lines 50
```

**6. Verificación:**
```powershell
Invoke-RestMethod http://localhost:3100/health | Format-List
# status: ok, model: qwen2.5:1.5b
Start-Process http://localhost:3100
Start-Process http://localhost:3100/docs
```

---

## 🖥️ Uso de `runeforge_launcher.ps1`

Launcher unificado que hace:
1. Verifica puertos 3100/3198/11434 libres
2. Inicia Ollama si no está
3. `pm2 start ecosystem.config.js`
4. Abre dashboard + logs

```powershell
# Ejecución normal
.\runeforge_launcher.ps1

# Ver estado
pm2 monit

# Detener todo
pm2 stop all
pm2 delete all

# Reinicio limpio post-git pull
pm2 restart ecosystem.config.js --update-env
```

`ecosystem.config.js` gestiona:
- `runeforge-backend` → `src\backend\app\src\server.js` → 3100
- `runeforge-relay` → relay WhatsApp → 3198

---

## 🔌 Endpoints Principales

| Endpoint | Método | Descripción |
|---|---|---|
| `/health` | GET | Health check - uptime, modelo, ollama |
| `/api/chat` | POST | Chat contra Ollama local |
| `/api/webcommand` | POST | Comandos web remotos |
| `/api/webcommand/health` | GET | Health del webcommand |
| `/api/manifiesto` | GET | Manifiesto Runeforge |
| `/api/estatus` | GET | Estatus servicios |
| `/docs` | GET | Documentación técnica |

Ejemplo chat:
```powershell
Invoke-RestMethod -Uri http://localhost:3100/api/chat -Method POST -Body (@{message="Hola Runeforge"} | ConvertTo-Json) -ContentType "application/json"
```

---

## 🛡️ Seguridad Local-First

`.gitignore` protege:
```
.env, *.env, **/app.env, **/.env.backup*
**/_exports/, **/_cleanup_quarantine/, **/knowledge/
**/data/traces/, **/data/storage/
**/ssh_host_*_key, **/authorized_keys
```

Nunca se sube:
- `src/backend/.env`, `app.env`, `*.backup_whatsapp_*`
- Claves SSH `ssh_host_*_key`
- Carpeta `_exports/` y `knowledge/`

Repo actual: 2 commits limpios, tag `v2.0.0`, 0 secretos en `git ls-files`.

---

## 🗺️ Roadmap

- [x] v2.0.0 - Unificación completa - Dashboard 10 pestañas + Fastify + Ollama + PM2
- [ ] v2.1 - LFS para `*.fac`, `*.pdf`, `*.pptx` (reduce 215MB → <50MB)
- [ ] v2.2 - Fix `/api/estatus` alias `/api/status` + Ollama 127.0.0.1 binding
- [ ] v2.3 - PWA push + Tailscale QR dinámico
- [ ] v2.4 - Bitácora PRO con Three.js manual 3D v2

---

## 📄 Licencia

MIT - Copyright (c) 2026 CINER / Runeforge v2.0

## 🔗 Links

- Repo: https://github.com/yhb86dy52f-lang/runeforge-v2-nucleo
- Issues: https://github.com/yhb86dy52f-lang/runeforge-v2-nucleo/issues
- Tag: `v2.0.0` - `fix: limpieza final backups de codigo pre-push`

---
*Generado en MODO DOCUMENTACION - Runeforge v2.0 - 2026-08-04*
