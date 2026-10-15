# RUTAS Y HERRAMIENTAS VALIDADAS

**Fecha:** 2026-10-08
**Origen:** logs reales de terminal (RUNEFORGE V2)

---

## 1. RUTAS CANONICAS

### Raiz
`C:\RUNEFORGE_V2_CORE`

### App principal (DICTATE Studio)
- `C:\RUNEFORGE_V2_CORE\apps\dictate-studio-v2`
- `dist\index.html` = 209,550 bytes (single file HTML)
- `src-tauri\tauri.conf.json` (contenido verificado)

### Apps en disco
_template, dictate-backend, dictate-studio, dictate-studio-v2, nexus-lab,
openwash-real, openwash-real-v2, opt-verify, panel-relevadores, sms-hub, sms-hub-hmi

### Frontend global (ROTO)
`C:\RUNEFORGE_V2_CORE\frontend`
- Contiene: node_modules, src, desktop.ini
- Falta: package.json (no se puede hacer npm install)

### Cache sccache
`C:\RUNEFORGE_V2_CORE\.sccache`

### Config cargo
`C:\Users\nesth\.cargo\config.toml`
Contenido: `[build] rustc-wrapper = "sccache" incremental = true`

### Binario sccache
`C:\Users\nesth\.cargo\bin\sccache.exe`

### Whisper backend
- Ruta: `C:\RUNEFORGE_V2_CORE\whisper-backend`
- Server: `http://127.0.0.1:8081`
- Venv: `whisper-backend\venv` (Python 3.11.9)
- DLLs CUDA en: `whisper-backend\venv\Lib\site-packages\ctranslate2`

### ESP32 / firmware
- Fuente: `C:\RUNEFORGE_V2_CORE\firmware\RUNEFORGE_COLLAB_FINAL_CORREGIDO_v1\firmware`
- Dashboard: `C:\RUNEFORGE_V2_CORE\firmware\RUNEFORGE_COLLAB_FINAL_CORREGIDO_v1\dashboard`

---

## 2. CONFIGURACION TAURI (verificada con Get-Content)

Archivo: `C:\RUNEFORGE_V2_CORE\apps\dictate-studio-v2\src-tauri\tauri.conf.json`

Campos clave:
- `build.frontendDist`: `../dist`
- `identifier`: `com.runeforge.dictate_studio_v2`
- `productName`: `DICTATE Studio`
- `version`: `1.0.0`
- `app.withGlobalTauri`: `true`
- `app.windows[0].width x height`: `1440 x 900`
- `plugins.http.scopeRedirects`: `true`
- `plugins.updater.endpoints`: `https://github.com/nesthor_99/RUNEFORGE_V2_CORE/releases/latest/download/latest.json`
- `bundle.createUpdaterArtifacts`: `true`

---

## 3. HERRAMIENTAS (versiones verificadas)

### Rust toolchain
- rustc 1.98.1
- cargo 1.98.1
- rustup 1.29.1

### sccache
- Version: 0.18.0
- Instalado con: `cargo install sccache`
- Tiempo de instalacion: 39m 18s
- Cache maxima: 50 GiB
- Cache actual: 1004 MiB
- Servidor local: 127.0.0.1:4226

### Primera compilacion con sccache (cargo check)
- Tiempo: 12m 17s
- Perfil: dev [unoptimized + debuginfo]
- Compilaciones: 194
- Cache hits: 0
- Cache misses: 194
- Tiempo promedio del compilador: 8.215s

### Crates Tauri validados
- tauri 2.12.0
- tauri-runtime 2.12.0
- tauri-runtime-wry 2.12.0
- tauri-utils 2.10.1
- tauri-plugin-fs 2.5.2
- tauri-plugin-process 2.4.0
- tauri-plugin-updater 2.13.2
- tauri-plugin-http 2.7.0
- wry 0.57.0
- tao 0.37.1
- webview2-com 0.39.1

---

## 4. SUBSISTEMA WHISPER (validado en sesion)

### Backend GPU
- URL: `http://127.0.0.1:8081`
- Modelo: `large-v3-turbo` (809M parametros)
- Motor: `faster-whisper >= 1.1.0`
- Compute: `int8_float16`
- Device: `cuda`
- Python: 3.11.9 en venv aislado
- Server: FastAPI + uvicorn

### Parametros activos en server.py
- BEAM_SIZE = 1
- COMPUTE = "int8_float16"
- without_timestamps = True
- vad_filter = True (min_silence_duration_ms=400)
- condition_on_previous_text = False
- no_speech_threshold = 0.8
- log_prob_threshold = -1.0
- temperature = 0.0

### Latencia medida
- 5.83s de audio -> ~6.96s la primera vez
- Chunks silenciosos -> 0.10-0.13s

### DLLs CUDA copiadas a ctranslate2
- cublas64_12.dll
- cublasLt64_12.dll
- cudart64_12.dll

### Shim cliente DICTATE Studio
- Marca: `SHIM_V3_WAV`
- Formato: WAV 16kHz mono int16
- Chunks: 8000ms
- POST a `http://127.0.0.1:8081/api/transcribe`
- Usa `__TAURI__.http.fetch` (evita CORS)

---

## 5. SUBSISTEMA ESP32 SCANNERPRO (validado en sesion)

### Hardware
- Chip: ESP32-D0WD-V3 (revision v3.1)
- MAC: 3c:8a:1f:a1:aa:84
- Features: WiFi, BT, Dual Core + LP Core, 240MHz
- Cristal: 40MHz
- Flash: 4MB
- Auto-reset: NO (requiere secuencia BOOT+EN manual)

### Puerto serial
- Windows: COM5
- Driver: Silicon Labs CP210x USB to UART Bridge
- Monitor baud: 115200

### Red
- WiFi STA: 517388haieksja_2.4G
- IP ESP32: 192.168.100.3
- RSSI: -67 dBm
- Modo: AP+STA
- AP SSID: ScannerPRO-Setup (pass 12345678, canal 6, IP 192.168.4.1)
- mDNS: http://scanner-pro.local

### MQTT broker (Mosquitto 2.1.2)
- Host: 192.168.100.10 (RUNEFORGE-PC)
- Puerto TCP: 1883
- Puerto WebSocket: 9001
- Config: `C:\Program Files\mosquitto\mosquitto.conf`
- Servicio Windows: mosquitto

### Firmware
- Nombre: ScannerPRO_v9_COLLAB.ino
- Rol: Scanner
- config.h defaults:
  - DEF_MDNS = "scanner-pro"
  - DEF_MQTT_SERVER = "192.168.100.10"
  - DEF_MQTT_PORT = 1883
  - DEF_MQTT_TOPIC = "scannerpro/collab"
  - DEF_MQTT_CLIENT = "SCANNER-14"

### Toolchain ESP32
- arduino-cli: `C:\Program Files\Arduino CLI\arduino-cli.exe`
- Core: esp32:esp32@3.3.12
- Core alterno: arduino:esp32@2.0.18-arduino.5
- esptool: `C:\Users\nesth\AppData\Local\Arduino15\packages\esp32\tools\esptool_py\5.3.1\esptool.exe`
- esp-x32: `...\tools\esp-x32\2601`
- esp-rv32: `...\tools\esp-rv32\2601`

### Layout de flash
| Offset  | Binario         |
|---------|-----------------|
| 0x1000  | bootloader.bin  |
| 0x8000  | partitions.bin  |
| 0xe000  | boot_app0.bin   |
| 0x10000 | app.bin         |

### Tags BLE detectados
| MAC                 | Nombre          | Familia |
|---------------------|-----------------|---------|
| b4:0e:cf:44:fe:ba   | TL-B40ECF44FEB9 | tile    |
| 7a:8b:11:98:82:db   | (sin nombre)    | other   |

### Topic MQTT confirmado
`scannerpro/collab/SCANNER-14-TORREON/report`

### Scripts de flash
- `C:\RUNEFORGE_V2_CORE\flash.ps1` (12s countdown)
- `C:\RUNEFORGE_V2_CORE\flash-manual.ps1` (30s countdown, manual BOOT+EN)
- `C:\RUNEFORGE_V2_CORE\flash-auto.ps1` (auto-reset, no funciono)

---

## 6. ESTADO DE SERVICIOS (ultimo reporte)

**2026-10-08 18:48:40**
- Fastify Backend: OFFLINE
- Ollama LLM: OFFLINE
- PM2 Supervisor: ONLINE
- Tailscale Mesh: OFFLINE

**2026-10-07 01:03:42**
- Fastify Backend: OFFLINE
- Ollama LLM: OFFLINE
- PM2 Supervisor: ONLINE
- Tailscale Mesh: ONLINE

---

## 7. PROBLEMAS RESUELTOS EN ESTA SESION

### Whisper backend
- faster-whisper 1.0.3 no reconocia large-v3-turbo -> actualizar a 1.1.0+
- cublas64_12.dll no encontrado -> instalar nvidia-cublas-cu12 + copiar DLL
- Puerto 8081 ocupado -> matar proceso previo
- Alucinaciones "Gracias!" -> no_speech_threshold=0.8 + log_prob=-1.0

### Shim cliente
- WebM fragmentado -> AVERROR_INVALIDDATA -> reemplazar con WAV crudo v3
- MediaRecorder.stop() creaba huecos -> MediaRecorder continuo con start(1000)

### ESP32
- esptool_py faltaba -> pip install + verificar versiones
- Toolchains anidados (11 paquetes) -> aplanado masivo
- sysroot faltante (stdint.h) -> re-extraccion selectiva desde ZIP
- config.h apuntaba a IP .5 -> editar a .10
- NVS guardaba IP vieja -> borrar region 0x9000 0x6000
- Chip sin auto-reset -> secuencia manual BOOT+EN con 30s

---

## 8. PENDIENTES (no resueltos)

- Dashboard visualizador muestra datos DEMO (MACs DEADBEEF, COFFEE12)
- Frontend global roto (falta package.json)
- Ollama offline
- Fastify backend offline
- Tailscale offline en ultimo reporte

