---
title: "Note Taking & Research Assistant Powered by AI"
source: "https://notebook.google.com/notebook/1de78c19-16b8-4e49-9765-4fdceed0cf5f?utm_source=gemini_notebook&utm_medium=referral&original_referer=https%3A%2F%2Fgemini.google.com%23&pli=1&authuser=1&pageId=none"
author:
published:
created: 2026-10-08
description: "Use the power of AI for quick summarization and note taking, Gemini Notebook is your powerful virtual research assistant rooted in information you can trust."
tags:
  - "clippings"
---
Las fuentes documentan la infraestructura, desarrollo y optimización del ecosistema técnico autónomo **RUNEFORGE V2 CORE**, centrado en el hardware local **RUNEFORGE-PC** y entornos móviles en dispositivos Android con **Termux**. Se detalla la configuración de herramientas de alto rendimiento como **Rust**, el optimizador de compilación **sccache** para agilizar el desarrollo con el framework **Tauri v2**, y la gestión de bases de datos mediante **SQLite** y almacenamiento en formato **JSON**. Asimismo, se abordan los subsistemas especializados del proyecto, incluyendo el motor de procesamiento de voz **faster-whisper** optimizado con **CUDA**, la red de telemetría de sensores **BLE** y microcontroladores **ESP32** comunicados vía **MQTT** con cifrado **AES-128-ECB**, y el desarrollo de la aplicación laboral **RUNFORGE BITÁCORA PRO** para la gestión de turnos, nómina semanal de **miércoles a martes**, horas extras y generación de reportes técnicos.

¿Cómo se optimizan los tiempos de compilación con sccache?

¿Cuáles son las reglas de negocio para el control laboral y nómina?

¿Cómo funciona la telemetría y el escaneo BLE con los dispositivos ESP32?

Introducción

¿Es posible desplegar un ecosistema tecnológico 100% soberano, local e independiente que combine aplicaciones de escritorio hiperaceleradas en Rust, IA de transcripción de voz por GPU, mallas de microcontroladores BLE encriptados y telemetría avanzada para flotas pesadas? A través de la arquitectura unificada RUNEFORGE V2 CORE y la plataforma móvil RUNFORGE BITÁCORA PRO, esta guía demuestra cómo lograr la máxima soberanía digital e integración de hardware de campo sin depender de servicios en la nube.

Al finalizar esta lección, serás capaz de:

- **Diferenciar** las cuatro capas del framework Tauri v2 y el impacto del gestor de caché `sccache` en la aceleración de compilación.

- **Analizar** el pipeline de transcripción de audio con Whisper backend (`large-v3-turbo` en CUDA) y la mitigación de alucinaciones lingüísticas.

- **Explicar** el esquema criptográfico de rotación EID AES-128-ECB en microcontroladores ESP32 y su integración con brokers Mosquitto MQTT.

- **Mapear** las conversiones matemáticas de telemetría y protocolos de comunicación (BLE Advertising y RS-485) entre rastreadores CalAmp LMU y sensores de combustible Escort.

- **Diagnosticar** fallas de integración en campo y ejecutar comandos de recuperación en la arquitectura móvil local-first en Termux.

Arquitectura RUNEFORGE V2 CORE y Aceleración de Compilación

El núcleo informático del sistema opera sobre la estación **RUNEFORGE-PC** (Windows 10 Build 19045 x64, procesador AMD Ryzen 3 3200G, 16 GB RAM DDR4 y GPU NVIDIA GeForce GTX 1660 SUPER de 6 GB VRAM con Driver 610.47 y CUDA 13.3). La estructura central reside en `C:\RUNEFORGE_V2_CORE` y organiza aplicaciones de escritorio, firmware, backends de inteligencia artificial y herramientas de automatización.

La capa de cliente liviano está construida sobre el framework **Tauri v2** y el lenguaje **Rust 1.98.1**, utilizando el motor WebView2 para garantizar un consumo en memoria RAM de aproximadamente 30 MB por aplicación.

**Estructura de 4 Capas en Tauri v2:**

- **Capa 1 (El Molde):** `apps_template` — Plantilla vacía de aplicación para rápida clonación.

- **Capa 2 (El Motor):** `apps\...\src-tauri` — Código ejecutable de alto rendimiento en Rust (`tauri 2.12.0`, `wry 0.57.0`, `tao 0.37.1`).

- **Capa 3 (La Cara):** `apps\...\dist\index.html` — Interfaz monoinforme empaquetada (ej. DICTATE Studio de 209,550 bytes) sin dependencias web externas.

- **Capa 4 (El Repartidor):** `src-tauri\tauri.conf.json` — Configuración de ventana (1440x900 px), puente `withGlobalTauri: true` y actualizador criptográfico Minisign hacia GitHub Releases (`nesthor_99/RUNEFORGE_V2_CORE`).

**Aceleración de Compilación con sccache 0.18.0:** Tradicionalmente, la compilación de las dependencias de Rust (~436 *crates*) requería **39 minutos y 18 segundos**. La integración de `sccache` mediante la directiva `[build] rustc-wrapper = "sccache"` en `C:\Users\nesth\.cargo\config.toml` transforma radicalmente los tiempos de desarrollo.

- **Directorio de caché:** `C:\RUNEFORGE_V2_CORE\.sccache` (Límite máximo: 50 GiB).

- **Primera compilación (Llenado de bodega):** **12 minutos 17 segundos** (194 *crates* procesados mediante `cargo check`, acumulando 1004 MiB de binarios intermediarios).

- **Compilaciones subsecuentes (Caché caliente):** **10 a 20 segundos** (>90% de aciertos de caché *hits*).

**Subsistema Whisper (Procesamiento de Audio por GPU):** Ubicado en `C:\RUNEFORGE_V2_CORE\whisper-backend`, opera bajo Python 3.11.9 en un servidor FastAPI/Uvicorn expuesto en `http://127.0.0.1:8081`.

- **Modelo de Inferencia:** `large-v3-turbo` (809M parámetros) mediante `faster-whisper >= 1.1.0` en motor CTranslate2.

- **Configuración Cómputo:** Dispositivo `cuda` con precisión cuantizada `int8_float16` (adaptado a los 6 GB de VRAM de la GTX 1660 SUPER).

- **Inyección de DLLs CUDA 12:** Copia manual de `cublas64_12.dll`, `cublasLt64_12.dll` y `cudart64_12.dll` en `whisper-backend\venv\Lib\site-packages\ctranslate2` para evitar fallos de inicialización.

- **Formato del Cliente (SHIM\_V3\_WAV):** Audio en bloques de 8000 ms en formato **WAV PCM 16 kHz, mono, int16** enviado vía `__TAURI__.http.fetch` para eludir restricciones de CORS.

- **Parámetros Antialucinación:** `BEAM_SIZE = 1` (búsqueda codiciosa para baja latencia), `vad_filter = True` (`min_silence_duration_ms = 400`), `no_speech_threshold = 0.8`, `log_prob_threshold = -1.0` y `condition_on_previous_text = False` (elimina bucles repetitivos como "Gracias!"). Latencia en silencio: 0.10s–0.13s.

### Resumen de la Arquitectura RUNEFORGE V2 CORE y Métricas sccache

Visualización esquemática de la arquitectura en 4 capas de Tauri v2, el flujo de compilación con sccache y los parámetros de inferencia GPU de Whisper.

Malla IoT: Microcontroladores ESP32 ScannerPRO y Criptografía EID

El monitoreo de campo en tiempo real se gestiona mediante microcontroladores **ESP32-D0WD-V3** (revisión v3.1, MAC `3c:8a:1f:a1:aa:84`, 4 MB Flash) ejecutando el firmware `ScannerPRO_v9_COLLAB.ino` cargado a través del puerto `COM5` a 115200 baudios.

**Modo Red Dual (AP + STA):**

- **Modo Estación (STA):** Conectado a la red Wi-Fi `517388haieksja_2.4G` con IP fija `192.168.100.3` (-67 dBm RSSI).

- **Modo Punto de Acceso (AP):** Emite la red `ScannerPRO-Setup` (IP `192.168.4.1`, canal 6, contraseña `12345678`) y responde a mDNS en `http://scanner-pro.local`.

- **Broker MQTT Mosquitto 2.1.2:** Alojado en RUNEFORGE-PC (`192.168.100.10`) en puerto TCP `1883` (ingesta hardware) y WebSocket `9001` (interfaces web). Tópico activo: `scannerpro/collab/SCANNER-14-TORREON/report`.

**Flashing Manual sin Auto-Reset:** Debido a la ausencia de circuito de auto-reset en el módulo de desarrollo, el flasheo requiere la ejecución del script en PowerShell `flash-manual.ps1` con un conteo regresivo de 30 segundos para presionar manualmente la secuencia física **BOOT + EN**. Para eliminar parámetros IP obsoletos en memoria no volátil, se fuerza el borrado de la región NVS en las direcciones `0x9000` a `0x6000`.

**Criptografía Efímera (EID) y Protecciones Anti-Rastreo:** Las balizas del sistema ejecutan `Tag_RUNEFORGE_FINAL_v2.ino`, generando Identificadores Efímeros Rotativos (**EID**) actualizados en intervalos de 300 segundos para impedir el rastreo físico.

$\text{EID} = \text{AES128}_{K}(\text{Epoch})$

Donde $K$ es una clave secreta compartida de 128 bits (16 bytes) y $\text{Epoch} = \lfloor \text{Tiempo Unix} / 300 \rfloor$.

**Estructura del Payload EID (16 Bytes):**

- **Byte 0:** `0xAA` (Encabezado de servicio Eddystone).

- **Byte 1:** `0xFE` (UUID de servicio corto `0xFEAA`).

- **Byte 2:** `0x50` (Especificador de trama de telemetría EID v2).

- **Bytes 3–10:** 8 Bytes del identificador efímero derivado por AES-128-ECB.

- **Byte 11:** Nivel de batería (porcentaje de carga restante).

- **Bytes 12–15:** Contador `Epoch` en formato Big-Endian.

El script `haystack_decoder_v2.py` intercepta los reportes del broker MQTT y aplica la clave $K$ sobre una ventana de tiempo definida para autenticar balizas autorizadas y descartar retransmisiones fuera de tiempo.

Integración de Telemetría Avanzada: CalAmp LMU y Sensores Escort (RS-485 & BLE)

La integración vehicular elimina la necesidad de hardware intermediario (como microcontroladores ESP32 o convertidores MAX3232), permitiendo la comunicación nativa entre el rastreador **CalAmp LMU-2630MB / LMU-4350** y los sensores de combustible **Escort TD-BLE / TD-600**.

**Advertencia Crítica de Firmware para Escort TD-BLE:** Los sensores pertenecientes a la carcasa de diseño anterior (S/N `< 268489`, como el equipo con S/N `260463959191` y MAC `D1:6D:2A:5B:BE:07`) **NUNCA deben flashearse a la versión de firmware 1.4.0**, ya que está concebida únicamente para carcasas nuevas y provocará un bloqueo irreversible. La versión estable y validada en producción es la **1.3.9**.

**Flujo de Datos y Conexión de Hardware:**

```
[ Sensor Escort TD-BLE ] --- BLE Advertising (3000 ms) ---> [ CalAmp LMU-2630MB ]
[ Sensor Escort TD-600 ] --- RS-485 / Serial (9600 8N1) --> [ CalAmp LMU-4350 AUX2 ]
                                                                      |
                                                              Red Celular / GPRS
                                                                      v
                                                            [ Servidor de Plataforma ]
```

**Fórmulas Matemáticas de Conversión de Parámetros Crudos (****accum\_X** **/** **esc\_X****):**

- **Voltaje de Unidad:** $\text{Voltaje (V)} = \frac{\text{accum\_0}}{1000}$ (Ejemplo: `accum_0 = 13315` $\rightarrow$ `13.32 V`).

- **Voltaje Interno GPS:** $\text{Voltaje GPS (V)} = \frac{\text{accum\_1}}{1000}$ (Ejemplo: `accum_1 = 3986` $\rightarrow$ `3.99 V`).

- **Odómetro Acumulado:** $\text{Odómetro (km)} = \frac{\text{accum\_5}}{1000}$ (Ejemplo: `accum_5 = 31086775` $\rightarrow$ `31086.78 km`).

- **Temperaturas:** `esc_temp_1` (T1) y `esc_temp_0` (T2) mapeados directamente en grados Celsius (°C).

- **Niveles de Combustible:** `esc_lev_1` (Tanque 1 / Piloto) y `esc_lev_0` (Tanque 2 / CoPiloto) se leen en un rango ADC crudo de **1 a 4095**. Para convertirlos a litros reales, se aplica una curva de calibración lineal por tramos definida por una **tabla de 28 puntos** (`tbl`). El volumen total de combustible es la suma directa: $\text{Total} = \text{Tanque 1} + \text{Tanque 2}$.

**Configuración de Streams Seriales en CalAmp LMU-4350:** Para la lectura de sensores Escort por cable RS-485 en el puerto AUX2:

- `STREAM_PEG_SERIAL` asignado al Stream 6 (`PORTID_AUX2`, 9600 baudios, formato `8/N/1`).

- Parámetros clave: `AT$APP PARAM 3072,6` (habilita stream), `AT$APP PARAM 3073,6` (fija velocidad a 9600 en S-Register 131).

### Generando presentación…

Guía de Integración y Calibración CalAmp-Escort

RUNFORGE BITÁCORA PRO: Arquitectura Móvil Local-First y Diagnóstico de Campo

La gestión operativa de campo corre sobre la aplicación **RUNFORGE BITÁCORA PRO** (versión v11.3 / v12.0), ejecutada en un entorno **Termux en Android 11** (Smartphone Moto G9 con 16 GB de almacenamiento libre y 1.5 GB de RAM disponible).

**Arquitectura del Backend Servidor (Fastify + SQLite WAL):**

- **Entorno de ejecución:** Node.js (v26.4.0) impulsando **Fastify 5.11.0** y la librería SQLite de alto rendimiento `better-sqlite3 13.0.2`.

- **Persistencia Isolada:** La base de datos relacional vive exclusivamente en `~/runeforge_data/telemetry.db` (o `db.json`), en modo **WAL (Write-Ahead Logging)** para permitir lecturas concurrentes sin bloquear escrituras. La capa de código habita de forma independiente en `~/runeforge_web/`, permitiendo actualizaciones totales de UI sin riesgo de borrar el historial.

- **Proceso Persistente:** Mantenido mediante una sesión `tmux` denominada `runeforge` y supervisado por el script de diagnóstico `rf_tunnel.sh` (valida `df -BG /data > 2G`, `free -m > 300M`, extrae la IP local en `wlan0` y verifica respuestas HTTP 200 OK en `http://127.0.0.1:8080`).

**Reglas Laborales y de Negocio Implemetadas:**

- **Técnico Asignado Unico:** **Néstor Corchado Valenzuela**.

- **Ciclo Semanal de Nómina:** Arranca los días **Miércoles** y concluye los días **Martes**.

- **Jornada Regular (Lunes a Sábado):** **8 horas diarias**. Cualquier tiempo laborado después de las 8 horas en estos días se clasifica como **Horas Extras**.

- **Regla Especial de Domingos:** El domingo no es día laboral regular. Por lo tanto, **el 100% de las horas trabajadas en domingo son Horas Extras**.

**Funcionalidades de la Aplicación Móvil:**

- **Captura de Evidencia Fotográfica:** Módulo de compresión de imágenes a formato **Base64** adjuntado directamente a las órdenes de servicio (`procedure_log` / `POST /api/orders`).

- **Reporte Oficial Kenworth / SEPCOLGPS:** Módulo con plantilla de hoja de servicio oficial para exportación directa a PDF, incluyendo membrete, desglose de tiempos, procedimientos y la **firma digital oficial de Néstor Corchado Valenzuela**.

- **Barra de Telemetría en Vivo (Footer):** Muestra el consumo de hardware en tiempo real: `RAM: 1.5G libre | Storage: 16G libre | Túnel: http://192.168.100.20:8080 | Server: tmux runeforge`.

**Protocolos y Comandos AT de Diagnóstico en Campo:**

- **Verificación de IMEI y Odómetro:** `AT+CGSN` (extrae IMEI del módem) y `AT$TTODOM?` (consulta lectura del odómetro).

- **Diagnóstico General de Módulo:** Envío del comando `!r0`. Si el equipo no responde en 15 minutos, se diagnostica daño en la SIM o en el módulo de comunicación.

- **Módulo GPS y Sincronización:** Si `!r0` responde `No time Sync`, el módulo GPS está apagado. Se reactiva enviando `!r3,20,0` y esperando 5 minutos.

- **Limpieza de Eventos / Desbloqueo de Memoria:** Si hay paquetes erróneos o saturación de almacenamiento en el equipo, se ejecuta `!r3,5,0` (o el comando `deleterecords`) para purgar el log y reanudar el reporte regular.

- **Verificación de Alimentación:** Antes de reemplazar un equipo que dejó de reportar, se revisa el historial de eventos en busca de una desconexión de batería. Si la lectura de voltaje es menor a 12V, el equipo tiene un falso contacto en la instalación eléctrica.

- **Verificación de Integridad de Base de Datos Local:** Antes de copiar respaldos automáticos diarios, se ejecuta el comando de validación relacional:

```
sqlite3 ~/runeforge_data/backups/manual_2026-07-28.db "PRAGMA integrity_check;"
# Resultado esperado: ok
```

Resumen y Evaluación

El ecosistema unificado RUNEFORGE V2 CORE y RUNFORGE BITÁCORA PRO representa una solución tecnológica soberana e integral. Al combinar la compilación hiperacelerada en Rust con `sccache`, la transcripción local de voz asistida por GPU con Whisper, la seguridad criptográfica EID en balizas BLE y la ingesta directa de telemetría de combustible (sin dependencias de hardware externo), el sistema garantiza la máxima estabilidad operativa tanto en el taller como en carretera.

**Puntos Clave para Recordar:**

- **Aceleración Rust:** `sccache` reduce los tiempos de recompilación de 39 min a un rango de 10–20 segundos reutilizando artefactos binarios.

- **Whisper GPU:** Ejecuta `large-v3-turbo` en precisión `int8_float16` con soporte CUDA, filtrando pausas silenciosas en 0.10s y suprimiendo alucinaciones mediante calibración VAD.

- **Criptografía EID:** Las balizas rotan su identificador cada 300 segundos utilizando encriptación AES-128-ECB basada en bloques de tiempo `Epoch`.

- **Firmware Escort Crítico:** Los sensores de combustible Escort TD-BLE con carcasa clásica (S/N `< 268489`) deben operar **únicamente en versión 1.3.9** para evitar su inutilización física.

- **Telemetría CalAmp:** Las lecturas crudas (`accum_X`) se escalan mediante división entre 1000 para obtener voltajes y odómetros, mientras que el volumen de combustible se calcula aplicando tablas de calibración de 28 puntos sobre el valor ADC (1–4095).

- **RUNFORGE BITÁCORA PRO:** Opera de forma *local-first* sobre Termux/Fastify/SQLite WAL. Mantiene un ciclo semanal de Miércoles a Martes, asigna fija la firma de **Néstor Corchado Valenzuela** y liquida los Domingos al 100% de Horas Extras.

### Evaluación de Comprensión del Ecosistema RUNEFORGE

Cuestionario de opción múltiple para evaluar el dominio técnico sobre la arquitectura RUNEFORGE V2 CORE, la telemetría CalAmp-Escort y el diagnóstico de campo.

<iframe allow="clipboard-write; web-share" src="chrome-extension://cnjifjpddelmedmihgijeibhnjfabmlf/side-panel.html?context=iframe"></iframe>