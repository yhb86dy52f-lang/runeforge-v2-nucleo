# RUNEFORGE — MASTER_MEMORY_MERGED

## [METADATA]
```yaml
version: "MERGED_2026-05-19"
estado: "CONSOLIDADO"
idioma: "es"
perfil_operativo: "Ingeniero Tinkerbell — Seguridad Electrónica, Telemetría y Automatización"
alcance: "Memoria técnica y operativa de Runeforge para migración entre IAs, Obsidian y operación local-first."
datos_personales: "MINIMIZADOS"
secretos: "NO_INCLUIDOS"
fuentes_base:
  - GLOBAL_AI_MEMORY_EXPORT_GEMINI
  - GLOBAL_AI_MEMORY_EXPORT_DEEPSEEK
  - GLOBAL_TECHNICAL_MEMORY_20260414
  - MASTER_MEMORY
  - estructura_cerrada
  - memorias_operativas_validadas
criterio_fusion:
  prioridad_1: "Datos confirmados por ejecución real, estructura cerrada o validaciones operativas."
  prioridad_2: "MASTER_MEMORY y memorias canónicas internas."
  prioridad_3: "Exports Gemini/DeepSeek como contexto, marcando PENDIENTE/ASUNCIÓN cuando falte evidencia."
```

---

## [IDENTIDAD OPERATIVA]

```yaml
usuario_operativo: "Nesthor / Néstor"
rol_general: "Ingeniero en telemetría / seguridad electrónica"
perfil: "Hacedor/reparador técnico, automatización, CCTV, GPS, scripting y diagnóstico"
modo_respuesta_preferido:
  - "Español"
  - "Directo"
  - "Técnico"
  - "Accionable"
  - "Con comandos copiables"
  - "Con validación explícita"
```

### Principio de trabajo

```txt
Si una herramienta no existe, se fabrica.
Si falta contexto crítico, se marca PENDIENTE o se valida antes de tocar producción.
```

---

## [IDENTIDAD CORE DE RUNEFORGE]

```yaml
runeforge:
  tipo: "ecosistema local-first"
  funcion: "núcleo backend, automatización, diagnóstico, memoria técnica y operación controlada"
  alma: "Runeforge = core lógico, IA, automatización, trazabilidad"
  carga: "CCTV, telemetría, GPS, logs y proyectos de campo son payloads desacoplados"
  regla_interfaz: "UI técnica abstracta; no convertir payload industrial en identidad del sistema"
```

---

## [ARQUITECTURA BASE]

Flujo obligatorio:

```txt
INPUT → ROUTER → SKILL → ACTION → TRACE → RESPONSE
```

Blueprint operativo:

```txt
┌──────────────────────────────────────────────┐
│ INPUT                                        │
│ Shortcuts │ AHK │ SSH │ API │ UI │ Archivos │
└──────────────────────┬───────────────────────┘
                       ▼
┌──────────────────────────────────────────────┐
│ ROUTER                                       │
│ Fastify / Express / Relay / Commander        │
└──────────────────────┬───────────────────────┘
                       ▼
┌──────────────────────────────────────────────┐
│ SKILL                                        │
│ system │ telemetria │ cctv │ trace │ general │
└──────────────────────┬───────────────────────┘
                       ▼
┌──────────────────────────────────────────────┐
│ ACTION                                       │
│ PowerShell │ Node │ FFmpeg │ Python │ SQLite │
└──────────────────────┬───────────────────────┘
                       ▼
┌──────────────────────────────────────────────┐
│ TRACE                                        │
│ JSONL │ SQLite │ Logs │ Obsidian │ Auditoría │
└──────────────────────┬───────────────────────┘
                       ▼
┌──────────────────────────────────────────────┐
│ RESPONSE                                     │
│ API │ UI │ Shortcuts │ Termius │ Obsidian    │
└──────────────────────────────────────────────┘
```

---

## [RUTAS CANÓNICAS]

```yaml
base_confirmada: "C:\\RUNEFOGE_PRO"
raiz_activa: "C:\\RUNEFOGE_PRO\\runeforge"
backend_activo: "C:\\RUNEFOGE_PRO\\runeforge\\app"
memoria_documental: "C:\\Users\\nesth\\Documents\\EL_ABISMO\\RUNEFORGE_CENTRO"
lab_controlado: "C:\\RUNEFOGE_PRO\\lab"
memoria_ia_pack: "C:\\RUNEFOGE_PRO\\memoria-ia-pack"
```

### Estructura cerrada

```txt
C:\RUNEFOGE_PRO\runeforge
│
├── app        # backend principal
├── scripts    # automatización
├── docs       # documentación
├── data       # datos operativos
├── backups    # respaldos
├── archive    # legado / colisiones
└── lab        # pruebas controladas
```

---

## [STACK CONSOLIDADO]

```yaml
sistema_principal:
  os: "Windows"
  shell: "PowerShell 7"
  acceso_remoto: "OpenSSH + Tailscale"
  movil: "iPhone + Termius + Shortcuts + a-Shell"

backend:
  runtime:
    - Node.js
    - TypeScript
  frameworks:
    - Fastify
    - Express
  proceso:
    - PM2
  persistencia:
    - SQLite
    - better-sqlite3
    - JSONL
    - archivos Markdown/YAML

automatizacion:
  - PowerShell
  - AutoHotkey
  - Python
  - FFmpeg
  - Scheduled Tasks
  - FileSystemWatcher
  - Start-Transcript

interfaces:
  - Runeforge Commander
  - Quick Dock
  - Forge UI
  - Apple Shortcuts
  - Obsidian Bridge
  - CCTV Viewer 3D

telemetria_y_cctv:
  cctv:
    - Dahua
    - Hikvision
    - EPCOM
    - Ajax
  gps:
    - CalAmp
    - Wialon
    - Traccar
    - Ruptela
    - Escort TD-600/500
```

---

## [ENDPOINTS CONOCIDOS / OBJETIVO]

```yaml
runeforge_core:
  health: "http://127.0.0.1:3100/health"
  relay: "http://127.0.0.1:3100/relay"
  status: "http://127.0.0.1:3100/status"
  command: "http://127.0.0.1:3100/command"

cctv_core_lab:
  frontend: "http://127.0.0.1:5500"
  api: "http://127.0.0.1:5510"
  websocket: "ws://127.0.0.1:5511"

traccar:
  web: "http://127.0.0.1:8082"

commander_trace_spine:
  trace: "http://127.0.0.1:4317/api/commander/trace"
  request: "http://127.0.0.1:4317/api/commander/request"
  metrics: "http://127.0.0.1:4317/metrics"
```

Notas:
- `127.0.0.1` es la política preferida.
- Acceso remoto: solo vía Tailscale/SSH o Tailscale Serve cuando aplique.
- No abrir listeners públicos sin justificación y validación.

---

## [SEGURIDAD OPERATIVA]

```yaml
nivel: "NIVEL_1"
reglas:
  - "Un cambio crítico por bloque."
  - "Validar salida antes de avanzar."
  - "No hardcodear tokens."
  - "No exponer .env."
  - "Separar laboratorio y producción."
  - "Rollback obligatorio cuando se toque sistema/configuración."
  - "Logs y trace obligatorios."
  - "Preferir localhost + Tailscale."
  - "No usar contraseñas SSH."
```

### Estado validado de seguridad

```yaml
ssh:
  estado: "HARDENED"
  password_authentication: false
  pubkey_authentication: true
  allow_users:
    - "nesth"
  acceso: "Tailscale only"
  observacion: "No incluir llaves ni fingerprints completos en memoria pública."

pendientes_seguridad:
  - "Auditoría Traccar 8082 / política firewall"
  - "Sunshine 47990"
  - "Defender exclusions"
  - "Revisión de logs/secret indicators"
```

---

## [PROYECTOS ACTIVOS]

### 1. Runeforge Core

```yaml
estado: "ACTIVO"
prioridad: "ALTA"
ruta: "C:\\RUNEFOGE_PRO\\runeforge\\app"
objetivo_actual:
  - "Consolidar motor conversacional"
  - "Mejorar respuesta estructurada"
  - "Conectar Forge UI"
flujo: "INPUT → ROUTER → SKILL → ACTION → TRACE → RESPONSE"
```

### 2. Runeforge Commander

```yaml
estado: "OPERATIVO"
versiones_relevantes:
  - "V43.5"
  - "V43.6.1_AHK_CALLBACK_FIX_OK"
comandos:
  - "rf-panel"
  - "rf-panel-full"
  - "rf-mini"
launcher: "C:\\RUNEFOGE_PRO\\runeforge\\scripts\\Start-Runeforge-Panel.ps1"
siguiente_logico:
  - "V43.6.2 ajuste visual / layout"
  - "V44 Backend Trace Spine"
```

### 3. CCTV Core / Visor CCTV 3D

```yaml
estado: "ACTIVO_EN_LAB"
ruta: "C:\\RUNEFOGE_PRO\\lab\\PROYEC-APP"
frontend: "http://127.0.0.1:5500"
api: "http://127.0.0.1:5510"
ws: "ws://127.0.0.1:5511"
db: "C:\\RUNEFOGE_PRO\\lab\\PROYEC-APP\\backend\\data\\cctv.db"
pm2: "runeforge-cctv-core"
camaras_importadas: 147
pendientes:
  - "Levantar/validar frontend 5500"
  - "Normalizar columnas x/y/z desde meta.raw.position"
  - "Conectar visor a /cameras"
regla: "Sigue en lab; no mezclar con backend principal hasta validar."
```

### 4. Shortcuts Core / iPhone operativo

```yaml
estado: "ACTIVO"
filosofia: "iPhone como nodo operativo Runeforge, no cliente pasivo"
apps:
  - "Apple Shortcuts"
  - "Data Jar"
  - "a-Shell"
  - "Termius"
  - "Tailscale"
  - "iCloud Drive"
atajo_actual:
  id: "RF-SC-002"
  nombre: "RF_STORAGE_CORE"
  estado: "FUNCIONAL PARCIALMENTE VALIDADO"
pendiente: "Generación y guardado definitivo de JSON persistente"
```

### 5. Obsidian Bridge

```yaml
estado: "FUNCIONAL"
version: "V1.2"
nota_creada: "C:\\Users\\nesth\\Documents\\EL_ABISMO\\RUNEFORGE_OBSIDIAN\\01_RUNEFORGE\\20260518_010236_RUNEFORGE_OBSIDIAN_BRIDGE_V1.2_OK.md"
trace_creado: "C:\\RUNEFOGE_PRO\\runeforge\\data\\obsidian_bridge\\rf_obsidian_20260518_010236.json"
pendiente: "Corregir tags separados; actualmente algunos tags se compactan."
```

### 6. Memoria IA Pack

```yaml
estado: "OPERATIVO"
ruta_objetivo: "C:\\RUNEFOGE_PRO\\memoria-ia-pack"
estructura:
  - "00_raw_imports"
  - "01_normalized"
  - "01_normalized\\PROJECTS"
  - "02_rules"
  - "03_logs"
  - "scripts"
salidas_objetivo:
  - "01_normalized\\MASTER_MEMORY.md"
  - "01_normalized\\FACTS_CANONICAL.yaml"
  - "01_normalized\\CONFLICTS.yaml"
  - "03_logs\\merge_log_YYYY-MM-DD.md"
```

---

## [PROTOCOLO DE RESPUESTA]

Formato preferido para tareas técnicas:

```txt
[OBJETIVO]
Qué se va a lograr.

[BLOQUE DE INSTRUCCIÓN]
Comando, archivo o bloque exacto para ejecutar.

[CONFIRMA CON]
Salida esperada, string esperado o checklist.

[ESTADO]
Estado actual, siguiente paso y candado operativo.
```

### Reglas de terminal

```yaml
pc_directa_powershell:
  formato: "Puede usar bloques multilinea y here-strings."
  etiqueta: "🖥️ Terminal X1/X2 — PC directa / PowerShell 7"

iphone_termius_hacia_pc:
  formato: "Una sola línea continua, sin here-strings ni saltos."
  etiqueta: "📱 Termius → PC / PowerShell"

iphone_ashell_local:
  formato: "Una sola línea cuando sea para copiar desde móvil."
  etiqueta: "📱 iPhone local / a-Shell"
```

---

## [REGLAS DE FUSIÓN DE MEMORIA]

```yaml
trust_policy:
  alta:
    - "Estructura cerrada validada"
    - "MASTER_MEMORY canónico"
    - "Validaciones operativas con estado OK"
    - "Outputs reales de comandos"
  media:
    - "GLOBAL_TECHNICAL_MEMORY consolidada"
    - "Export Gemini cuando no contradice estado validado"
  baja:
    - "Export DeepSeek cuando declara falta de historial o NO DISPONIBLE"
    - "Suposiciones de herramientas o rutas sin prueba"
```

### Resolución de conflictos

```yaml
rutas:
  resolucion: "C:\\RUNEFOGE_PRO\\runeforge manda como raíz activa."
  estado: "RESUELTO"

backend:
  resolucion: "C:\\RUNEFOGE_PRO\\runeforge\\app manda como backend activo."
  estado: "RESUELTO"

rol:
  resolucion: "Usar 'Ingeniero en telemetría / seguridad electrónica' para contexto técnico; 'técnico en seguridad electrónica' como puesto operativo."
  estado: "RESUELTO"

ios_vs_windows:
  resolucion: "Arquitectura híbrida: Windows es core; iPhone es consola/nodo operativo."
  estado: "RESUELTO"

fastify_vs_express:
  resolucion: "Ambos existen en memoria; validar repo activo antes de editar código. No asumir framework por defecto."
  estado: "ABIERTO"

base_de_datos:
  resolucion: "SQLite confirmado en varios módulos; libSQL/Drizzle/Turso se mantiene como arquitectura o evolución, no como runtime probado universal."
  estado: "PARCIAL"

bot_whatsapp:
  resolucion: "Canal/interfaz, no núcleo. Requiere auditoría de seguridad antes de escalar."
  estado: "PARCIAL"
```

---

## [NO TOCAR / CANDADOS]

```yaml
candados:
  - "No tocar backend sin validar archivo objetivo."
  - "No abrir puertos públicos."
  - "No mezclar lab con producción."
  - "No incluir secretos en memorias."
  - "No ejecutar acciones destructivas sin rollback."
  - "No convertir WhatsApp/UI/Atajos en núcleo."
```

---

## [SIGUIENTE MEJORA RECOMENDADA]

```yaml
siguiente:
  prioridad_1: "Instalar esta memoria consolidada en C:\\RUNEFOGE_PRO\\memoria-ia-pack."
  prioridad_2: "Generar script merge-memory.ps1 idempotente para repetir el proceso."
  prioridad_3: "Crear endpoint o comando Runeforge para leer MASTER_MEMORY + FACTS_CANONICAL."
  prioridad_4: "Conectar Obsidian Bridge para escribir notas de actualización automáticamente."
```
