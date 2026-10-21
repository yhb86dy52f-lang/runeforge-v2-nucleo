# RUTAS Y HERRAMIENTAS VALIDADAS

**Fecha:** 2026-10-20
**Origen:** logs reales de terminal (RUNEFORGE V2) tras Purga Nuclear.

---

## 1. RUTAS CANONICAS

### Raiz
C:\RUNEFORGE_V2_CORE

### App principal (DICTATE Studio)
- C:\RUNEFORGE_V2_CORE\apps\dictate-studio-v2
- dist\index.html = 209,550 bytes (single file HTML)
- src-tauri\tauri.conf.json (contenido verificado)

### PWA Simulador
- C:\RUNEFORGE_V2_CORE\runeforge-v2-nucleo\simulador
- Lanzador: Lanzar_RUNEFORGE.bat (Puerto 8080 local o red).

### Cache sccache
C:\RUNEFORGE_V2_CORE\.sccache

### Whisper backend
- Ruta: C:\RUNEFORGE_V2_CORE\whisper-backend
- Server: http://127.0.0.1:8081
- Venv: whisper-backend\venv (Python 3.11.9)

---

## 2. CONFIGURACION TAURI

Archivo: C:\RUNEFORGE_V2_CORE\apps\dictate-studio-v2\src-tauri\tauri.conf.json

Campos clave:
- uild.frontendDist: ../dist
- identifier: com.runeforge.dictate_studio_v2
- productName: DICTATE Studio
- pp.windows[0].width x height: 1440 x 900
- plugins.updater.endpoints: https://github.com/yhb86dy52f-lang/runeforge-v2-nucleo/releases/latest/download/latest.json
- undle.createUpdaterArtifacts: 	rue

---

## 3. HERRAMIENTAS (versiones verificadas)

### Rust toolchain
- rustc 1.98.1
- cargo 1.98.1
- rustup 1.29.1
- sccache 0.18.0 (127.0.0.1:4226)

---

## 4. SUBSISTEMA WHISPER (validado)

### Backend GPU
- URL: http://127.0.0.1:8081
- Modelo: large-v3-turbo (809M parametros)
- Motor: aster-whisper >= 1.1.0
- Compute: int8_float16
- Device: cuda

---

## 5. SUBSISTEMA ESP32 SCANNERPRO (validado)

### Hardware
- Chip: ESP32-D0WD-V3 (revision v3.1)
- MAC: 3c:8a:1f:a1:aa:84
- Puerto serial: COM5
- IP ESP32: 192.168.100.3

### MQTT broker (Mosquitto 2.1.2)
- Host: 192.168.100.10 (RUNEFORGE-PC)
- Puerto TCP: 1883
- Puerto WebSocket: 9001

---

## 6. GESTIÓN DE REPOSITORIO (Purga Nuclear 2026-10-19)

Se detectó y resolvió un problema crítico de saturación en Git:
- **2.3 GB** de archivos LFS (Large File Storage) bloqueaban los push.
- Se erradicaron todos los .gitattributes y se reinició el historial.
- Se configuró red a prueba de Timeouts (HTTP 408/500):
  - http.version HTTP/1.1
  - http.postBuffer 1048576000 (1GB)
  - core.compression 9
- **Commits estables:** 8bf1dc (Consolidación de .gitignore) y 9a03aad (Purga).

---

## 7. PENDIENTES (no resueltos)

- Dashboard visualizador muestra datos DEMO (MACs DEADBEEF, COFFEE12)
- Ollama offline
- Fastify backend offline
- Tailscale offline en ultimo reporte
