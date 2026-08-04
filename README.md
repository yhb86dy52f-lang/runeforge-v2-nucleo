# Runeforge v2.0 - Ecosistema Local-First

Runeforge es un centro de operaciones digital personal, diseñado para trabajar completamente local, sin dependencias de la nube. Integra gestión de conocimiento, automatización con scripts, modelos de IA ligeros y telemetría de flotas.

## 🚀 Características principales
- **Dashboard unificado** con 10 herramientas integradas en una sola interfaz.
- **Backend Fastify** con endpoints para chat, webcommand y estado.
- **IA local** usando Ollama con el modelo qwen2.5:1.5b.
- **PM2** para gestión de procesos (backend y relay).
- **Soberanía digital:** cero dependencias externas.

## 📁 Estructura del proyecto
C:\RUNEFORGE_V2_CORE
├── public/ # Frontend (dashboard y paneles)
├── src/backend/app/src/ # Backend Fastify
├── runeforge_launcher.ps1 # Script de inicio unificado
└── ... (otros archivos)


## 🔧 Requisitos
- Node.js v20+
- Ollama (con modelo qwen2.5:1.5b)
- PM2 (opcional, pero recomendado)

## 🛠️ Instalación y configuración
1. Clona el repositorio en C:\RUNEFORGE_V2_CORE.
2. Dentro de src/backend/app, ejecuta 
pm install.
3. Copia .env.example a .env y ajusta las variables según tu entorno.
4. Si usas PM2, edita cosystem.config.js con las rutas correctas (opcional).
5. Ejecuta uneforge_launcher.ps1 como administrador para levantar todo el sistema.

## 🌐 Acceso
- Dashboard principal: http://localhost:3100/
- Documentación técnica: http://localhost:3100/docs/

## 📜 Licencia
MIT
