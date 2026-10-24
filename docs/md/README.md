# ⚡ RUNEFORGE V2.6.2 - Manual de Operación

## 1. Inicio Rápido
1. Haz clic derecho en el icono de **Windows Terminal** y selecciona "Ejecutar como Administrador".
2. El perfil cargará automáticamente el banner de estado (Fastify, Ollama, PM2, Tailscale).
3. Escribe `rf-help` para ver los comandos disponibles.

## 2. Comandos de Terminal (pwsh)
- `rf-cd` : Viaja a la raíz del CORE.
- `rf-boot` : Inicia el Ecosistema Global (6 servicios).
- `rf-stop` : Apagón Nuclear (mata todo, incluso red Mesh).
- `rf-audit` : Ejecuta la auditoría forense y copia el reporte al portapapeles.

## 3. Panel de Control AHK
Ejecuta `RUNEFORGE_MASTER_PANEL.ahk` en `C:\RUNEFORGE_V2_CORE\scripts`.
- **MASTERS (UI):** Abre Dashboards, Radar y GPS.
- **SISTEMA / CORE:** Botones de Arranque, Apagado, Auditoría y Reset RAM.
- **CÓDIGO:** Creación de módulos y búsqueda en el repo.

## 4. Resolución de Problemas
- Si un servicio falla, revisa los logs en `C:\RUNEFORGE_V2_CORE\logs\`.
- Si el puerto `3100` (Fastify) está caído, ejecuta `pm2 resurrect`.
- Si Tauri no arranca, verifica que el puerto `8080` esté libre y que `cargo` esté en el PATH.