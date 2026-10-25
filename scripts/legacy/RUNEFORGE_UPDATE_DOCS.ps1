# =====================================================================
# RUNEFORGE_UPDATE_DOCS.ps1
# Actualiza los tres archivos de documentación maestra con los datos
# reales del sistema tras la Purga Nuclear (19 de Octubre de 2026).
# =====================================================================

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

$Buf = New-Object System.Collections.Generic.List[string]
function W($m) { $Buf.Add([string]$m) | Out-Null; Write-Host $m }

W "==================================================================="
W " RUNEFORGE · ACTUALIZACIÓN DE DOCUMENTACIÓN · $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
W "==================================================================="

$DocsDir = "C:\RUNEFORGE_V2_CORE\docs\RUNEFORGE_EXPLICADO"
New-Item -ItemType Directory -Force -Path $DocsDir | Out-Null
Set-Location "C:\RUNEFORGE_V2_CORE"

# =====================================================================
# ARCHIVO 1: 01_README_PRINCIPIANTE.md
# =====================================================================
W "`n[FASE 1] Actualizando 01_README_PRINCIPIANTE.md..."
$readmeContent = @"
# RUNEFORGE V2 CORE — Explicado para alguien que no sabe nada

## ¿Qué es esto?

Imagina que tienes una **fábrica de juguetes** en tu computadora.

En lugar de hacer cada juguete desde cero, ya tienes:
- Un molde (la plantilla)
- Las herramientas (Rust, Tauri, sccache)
- Los materiales guardados (la bodega de piezas)

**RUNEFORGE** es esa fábrica. Le dices "quiero una app para dictar por voz"
y en pocos minutos tienes un programa `.exe` que abre en Windows como
cualquier otro.

## ¿Para qué sirve en la vida real?

Vas a poder crear:
- **Programas de escritorio** que abren con doble clic
- **Apps que funcionan sin internet** (todo está dentro del .exe)
- **Herramientas que se actualizan solas** (van a GitHub, ven si hay versión nueva, se bajan)

Ejemplo real que ya funciona: **DICTATE Studio**
- Es un programa que abre una ventana de 1440x900 píxeles
- Sirve para dictar por voz y transcribir con Inteligencia Artificial
- Está en `C:\RUNEFORGE_V2_CORE\apps\dictate-studio-v2`

## ¿Cómo funciona? (con palabras simples)

Imagina 4 capas:

| Capa | Qué es | Dónde está |
|---|---|---|
| 1. El molde | Una plantilla de app vacía | `apps\_template` |
| 2. El motor | La parte que corre rápido (Rust) | `apps\...\src-tauri` |
| 3. La cara | Lo que ves en pantalla (HTML) | `apps\...\dist\index.html` |
| 4. El repartidor | Va a GitHub a ver si hay actualización | `tauri.conf.json` |

## ¿Por qué antes tardaba 1-2 HORAS y ahora 10-20 segundos?

Antes, cada vez que hacías una app, la computadora **fabricaba todos los
ladrillos de LEGO desde cero**. Cada ladrillo = un pedacito de código.

**Ahora instalaste `sccache`** (versión 0.18.0). Funciona como una bodega:
- Primera vez: fabrica los ladrillos, los guarda en la bodega
- Segunda vez: en lugar de fabricarlos, los saca de la bodega

La bodega está en `C:\RUNEFORGE_V2_CORE\.sccache` y ya tiene **1004 MB de
ladrillos guardados**.

## ¿Qué hay dentro de la caja grande?

En `C:\RUNEFORGE_V2_CORE` hay muchas carpetas. Las principales:

- **apps/** → tus programas (dictate-studio-v2, nexus-lab, etc.)
- **.sccache/** → la bodega de ladrillos (para compilar rápido)
- **runeforge-v2-nucleo/simulador/** → PWA local, inicia con `Lanzar_RUNEFORGE.bat`.
- **scripts/** → herramientas para automatizar cosas
- **docs/** → documentos como este
- **firmware/** → código para chips pequeños (ESP32)
- **whisper-backend/** → motor de transcripción de voz

## ¿Qué es GitHub?

Es como Google Drive pero para programadores. Ahí guardas tus apps
para que no se pierdan.

**Tu cuenta actual es:** `yhb86dy52f-lang`
**Tu repositorio:** `runeforge-v2-nucleo`

## Resumen para recordar

**RUNEFORGE = tu fábrica personal de apps de Windows que ya no tarda horas.**
"@
$readmeContent | Set-Content -Path "$DocsDir\01_README_PRINCIPIANTE.md" -Encoding UTF8
W "  [+] 01_README_PRINCIPIANTE.md actualizado."

# =====================================================================
# ARCHIVO 2: 02_RUTAS_VALIDADAS.md
# =====================================================================
W "`n[FASE 2] Actualizando 02_RUTAS_VALIDADAS.md..."
$rutasContent = @"
# RUTAS Y HERRAMIENTAS VALIDADAS

**Fecha:** 2026-10-20
**Origen:** logs reales de terminal (RUNEFORGE V2) tras Purga Nuclear.

---

## 1. RUTAS CANONICAS

### Raiz
`C:\RUNEFORGE_V2_CORE`

### App principal (DICTATE Studio)
- `C:\RUNEFORGE_V2_CORE\apps\dictate-studio-v2`
- `dist\index.html` = 209,550 bytes (single file HTML)
- `src-tauri\tauri.conf.json` (contenido verificado)

### PWA Simulador
- `C:\RUNEFORGE_V2_CORE\runeforge-v2-nucleo\simulador`
- Lanzador: `Lanzar_RUNEFORGE.bat` (Puerto 8080 local o red).

### Cache sccache
`C:\RUNEFORGE_V2_CORE\.sccache`

### Whisper backend
- Ruta: `C:\RUNEFORGE_V2_CORE\whisper-backend`
- Server: `http://127.0.0.1:8081`
- Venv: `whisper-backend\venv` (Python 3.11.9)

---

## 2. CONFIGURACION TAURI

Archivo: `C:\RUNEFORGE_V2_CORE\apps\dictate-studio-v2\src-tauri\tauri.conf.json`

Campos clave:
- `build.frontendDist`: `../dist`
- `identifier`: `com.runeforge.dictate_studio_v2`
- `productName`: `DICTATE Studio`
- `app.windows[0].width x height`: `1440 x 900`
- `plugins.updater.endpoints`: `https://github.com/yhb86dy52f-lang/runeforge-v2-nucleo/releases/latest/download/latest.json`
- `bundle.createUpdaterArtifacts`: `true`

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
- URL: `http://127.0.0.1:8081`
- Modelo: `large-v3-turbo` (809M parametros)
- Motor: `faster-whisper >= 1.1.0`
- Compute: `int8_float16`
- Device: `cuda`

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
- **2.3 GB** de archivos LFS (Large File Storage) bloqueaban los `push`.
- Se erradicaron todos los `.gitattributes` y se reinició el historial.
- Se configuró red a prueba de Timeouts (`HTTP 408/500`):
  - `http.version HTTP/1.1`
  - `http.postBuffer 1048576000` (1GB)
  - `core.compression 9`
- **Commits estables:** `a8bf1dc` (Consolidación de .gitignore) y `9a03aad` (Purga).

---

## 7. PENDIENTES (no resueltos)

- Dashboard visualizador muestra datos DEMO (MACs DEADBEEF, COFFEE12)
- Ollama offline
- Fastify backend offline
- Tailscale offline en ultimo reporte
"@
$rutasContent | Set-Content -Path "$DocsDir\02_RUTAS_VALIDADAS.md" -Encoding UTF8
W "  [+] 02_RUTAS_VALIDADAS.md actualizado."

# =====================================================================
# ARCHIVO 3: 03_DATOS_VALIDADOS.json
# =====================================================================
W "`n[FASE 3] Actualizando 03_DATOS_VALIDADOS.json..."
$jsonContent = @"
{
  "proyecto": "RUNEFORGE_V2_CORE",
  "fecha_validacion": "2026-10-20",
  "hostname": "RUNEFORGE-PC",
  "hardware": {
    "cpu": "AMD Ryzen 3 3200G",
    "ram_gb": 16,
    "gpu": "NVIDIA GeForce GTX 1660 SUPER 6GB",
    "so": "Windows 10 19045 x64"
  },
  "rust_toolchain": {
    "rustc": "1.98.1",
    "cargo": "1.98.1",
    "rustup": "1.29.1",
    "sccache": "0.18.0"
  },
  "rutas_canonicas": {
    "raiz": "C:\\RUNEFORGE_V2_CORE",
    "app_principal": "C:\\RUNEFORGE_V2_CORE\\apps\\dictate-studio-v2",
    "pwa_simulador": "C:\\RUNEFORGE_V2_CORE\\runeforge-v2-nucleo\\simulador",
    "whisper_backend": "C:\\RUNEFORGE_V2_CORE\\whisper-backend"
  },
  "github": {
    "usuario": "yhb86dy52f-lang",
    "repositorio": "runeforge-v2-nucleo",
    "rama_principal": "main",
    "commit_actual": "a8bf1dc",
    "estado_purga_lfs": "COMPLETADO - 2.3GB eliminados"
  },
  "whisper_backend": {
    "url": "http://127.0.0.1:8081",
    "modelo": "large-v3-turbo",
    "device": "cuda",
    "compute": "int8_float16"
  },
  "esp32": {
    "chip": "ESP32-D0WD-V3",
    "mac": "3c:8a:1f:a1:aa:84",
    "puerto": "COM5",
    "ip_esp32": "192.168.100.3",
    "mqtt_broker": "192.168.100.10:1883"
  },
  "problemas_resueltos": [
    "faster-whisper 1.0.3 no reconocia large-v3-turbo",
    "WebM fragmentado causaba AVERROR_INVALIDDATA",
    "Saturación de Git por LFS (2.3 GB) resuelto con Purga Nuclear",
    "Timeouts HTTP 408/500 resueltos con HTTP/1.1 y Buffer de 1GB",
    "Archivos .gitignore duplicados (.v2.1, .v2.2) consolidados en uno solo"
  ],
  "pendientes": [
    "Dashboard visualizador muestra datos DEMO",
    "Ollama offline",
    "Fastify offline",
    "Tailscale offline"
  ]
}
"@
$jsonContent | Set-Content -Path "$DocsDir\03_DATOS_VALIDADOS.json" -Encoding UTF8
W "  [+] 03_DATOS_VALIDADOS.json actualizado."

# =====================================================================
# SINCRONIZACIÓN CON GITHUB
# =====================================================================
W "`n[FASE 4] Sincronizando documentación con GitHub..."
cmd /c "git add docs/RUNEFORGE_EXPLICADO/" | Out-Null
cmd /c "git commit -m `"Docs: Auditoría y actualización de MDs post-Purga Nuclear (2026-10-20)`"" | Out-Null
$pushOut = cmd /c "git push origin main 2>&1"
W "  [>] Resultado del Push:"
W $pushOut

W "`n==================================================================="
W " RESUMEN DE OPERACIÓN"
W "==================================================================="
W " Se han reescrito los 3 documentos con los datos del 20 de Octubre."
W " - GitHub actualizado a 'yhb86dy52f-lang'."
W " - Historial de Purga Nuclear documentado."
W " - JSON actualizado con el commit 'a8bf1dc'."
W "==================================================================="

Set-Clipboard -Value ($Buf -join "`r`n")
Write-Host "`n[OK] Salida copiada al portapapeles (Ctrl+V)."
