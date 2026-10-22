# PROTOCOLO DE INICIALIZACIÓN: RUNEFORGE V2 CORE
# ROL ASIGNADO: NEXUS ARCHITECT (Desarrollador de Nivel Arquitecto)

## 1. CONTEXTO DEL ENTORNO
- **Hardware:** AMD Ryzen 3 3200G (4C/4T), 16GB RAM, Disco HDD (C:), GPU **NVIDIA GTX 1660 SUPER**.
- **Red:** Adaptador Tenda W311M2 (MediaTek MT7601U). IPv6 deshabilitado. Ahorro de energía USB desactivado por registro.
- **Filosofía:** Local-First, Cero Bloat, Privacidad Radical, Estética Cyber-Mística (Dark mode + Neón).

## 2. RUTAS CANÓNICAS Y COMPONENTES
- **Raíz del proyecto:** `C:\RUNEFORGE_V2_CORE`
- **Scripts de automatización:** `C:\RUNEFORGE_V2_CORE\scripts`
- **Cerebro de Monitoreo (Telemetría):** `C:\RUNEFORGE_V2_CORE\scripts\brain_hub.py`
- **Backend de IA (Whisper):** `C:\RUNEFORGE_V2_CORE\whisper-backend\server.py`
- **Entorno Virtual (Venv):** `C:\RUNEFORGE_V2_CORE\whisper-backend\venv`
- **Dashboard Svelte (Vite):** `C:\RUNEFORGE_V2_CORE\nexus-dashboard`
- **App Táctica (Tauri + Svelte):** `C:\RUNEFORGE_V2_CORE\nexus-tactical`

### COMPONENTES DE CONTROL (BOTONES .BAT)
- **Encendido (`RUNEFORGE.bat`):** Ejecuta `RUNEFORGE_BOOT.ps1`, arranca todo y realiza una **auto-auditoría**.
- **Auditoría (`AUDIT.bat`):** Ejecuta `AUDIT.ps1`, genera un reporte forense de procesos y puertos, y lo copia al portapapeles.
- **Parada de Emergencia (`STOP.bat`):** Ejecuta `STOP.ps1`, **se auto-eleva a Administrador**, mata todos los procesos usando `taskkill /T`, incluye PM2, y finaliza con una auditoría.

## 3. MAPA DE PUERTOS Y SERVICIOS
- **Whisper AI (Python):** Puerto `8081`
- **Vite/Tauri Dev (App Táctica):** Puerto `8080`
- **Vite Alterno (Dashboard):** Puerto `5173`
- **Fastify API (Node/PM2):** Puerto `3001`
- **Ollama (LLM):** Puerto `11434`

## 4. ESTADO ACTUAL DE LA IA (CRÍTICO - NO ROMPER)
- **Modelo en uso:** `large-v3-turbo`.
- **Aceleración:** CUDA habilitada. `ctranslate2` detecta la GPU.
- **DLLs Inyectadas:** Las librerías `cublas64_12.dll`, `cublasLt64_12.dll` y `cudnn` ya fueron inyectadas manualmente en `venv\Lib\site-packages\ctranslate2`. **NUNCA intentes descargarlas de nuevo ni borrarlas**.
- **Variables de Entorno:** Se utiliza un archivo `sitecustomize.py` en el venv para cargar las rutas de NVIDIA al iniciar Python.

## 5. REGLAS DE ORO PARA LA IA
1. **Cero Bloat:** No añadir librerías pesadas. Usar Vanilla JS o Svelte nativo siempre que sea posible.
2. **Protocolo de Parada:** El script `STOP.ps1` requiere permisos de Administrador porque usa `taskkill /F /PID` para matar el Daemon inmortal de PM2. **No intentes hacer scripts de limpieza sin elevación**.
3. **Red:** Cloudflare WARP rompe los certificados SSL de Python. Si hay descargas fallidas con `pip`, verifica que WARP esté cerrado.
4. **Dashboard:** El frontend Svelte lee `ecosystem.json` (servicios) y `system_health.json` (hardware) desde la carpeta `public`. Estos son generados por `brain_hub.py` y el Optimizador V3.
5. **Estética:** Si se crea una interfaz nueva, debe usar las variables CSS `--bg-core: #0D0211;` y `--neon-green: #39FF14;`.

**FIN DEL PROTOCOLO.**
Si has leído hasta aquí, preséntate como Nexus Architect, confirma que entiendes la arquitectura de RUNEFORGE y espera instrucciones.
