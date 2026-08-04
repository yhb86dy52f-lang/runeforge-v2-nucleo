# RUNEFORGE — ESTADO GLOBAL CURRENT
## Corte operativo: 2026-06-07

## [RESUMEN CORTO]

```txt
Estado general : ACTIVO_CONSOLIDACION
Fase           : RF-FASE-06_PREP / FORGE_UI_OPERATIVA_EN_PROGRESO
Arquitectura   : INPUT → ROUTER → SKILL → ACTION → TRACE → MEMORY → RESPONSE
Modo           : local-first / backend-first / trace-first
Backend        : validar 127.0.0.1:3100 antes de UI
n8n            : capa canary/orquestación, no núcleo
iPhone         : consola ligera local-first
Markov         : VALIDATION_ONLY
Política files : RF_CURRENT_OVERWRITE_POLICY_V1
```

## [ARQUITECTURA CANÓNICA]

```txt
INPUT
  ↓
ROUTER
  ↓
SKILL
  ↓
ACTION
  ↓
TRACE
  ↓
MEMORY
  ↓
RESPONSE
```

## [MAPA OPERATIVO]

```txt
┌──────────────────────────────────────────────┐
│ INPUT                                        │
│ ChatGPT │ iPhone │ Termius │ Shortcuts │ UI  │
└──────────────────────┬───────────────────────┘
                       ↓
┌──────────────────────────────────────────────┐
│ RUNEFORGE CORE                               │
│ Node.js / PM2 / Router / Seguridad / Trace   │
└──────────────────────┬───────────────────────┘
                       ↓
┌───────────────┬───────────────┬──────────────┐
│ ACTIONS V4    │ MEMORY        │ OBSERVABILITY│
│ allowlist     │ JSONL/SQLite  │ reports/traces│
│ no shell libre│ Obsidian MD   │ health/PM2   │
└───────┬───────┴───────┬───────┴──────┬───────┘
        ↓               ↓              ↓
┌───────────────┐ ┌───────────────┐ ┌──────────────┐
│ n8n CANARY    │ │ GRAPH/MARKOV  │ │ FORGE UI     │
│ orquestador   │ │ análisis only │ │ canal visual │
│ no cerebro    │ │ no ejecución  │ │ no lógica    │
└───────────────┘ └───────────────┘ └──────────────┘
```

## [RUTAS CANÓNICAS]

| Tipo | Ruta |
|---|---|
| Base | `C:\RUNEFOGE_PRO` |
| Raíz Runeforge | `C:\RUNEFOGE_PRO\runeforge` |
| Backend | `C:\RUNEFOGE_PRO\runeforge\app` |
| Traces | `C:\RUNEFOGE_PRO\runeforge\data\traces` |
| Reports | `C:\RUNEFOGE_PRO\runeforge\data\reports` |
| Memory | `C:\RUNEFOGE_PRO\runeforge\data\memory` |
| Event Model | `C:\RUNEFOGE_PRO\runeforge\data\event_model` |
| Graph | `C:\RUNEFOGE_PRO\runeforge\data\graph` |
| Markov | `C:\RUNEFOGE_PRO\runeforge\data\markov` |
| n8n canary runtime | `C:\RUNEFOGE_PRO\runeforge\lab\n8n\runtime_canary_2_20_12` |
| Obsidian | `C:\Users\nesth\Documents\EL_ABISMO\RUNEFORGE_OBSIDIAN` |
| State Current | `C:\RUNEFOGE_PRO\runeforge\data\state\current` |

## [MÓDULOS — ESTADO ACTUAL]

| Módulo | Capa | Estado | Nota |
|---|---|---|---|
| `RUNEFORGE_CORE` | core | NUCLEO_CANONICO | backend, router, seguridad, trace, endpoints |
| `RF_ACTION_ROUTER_V3` | integration | CERRADO_OPERATIVO | Core consume n8n Action Router con allowlist y bloqueo de run_powershell |
| `RF_ACTIONS_CONTROLADAS_V4` | actions | CERRADO_OPERATIVO |  |
| `RF_WEBCOMMAND` | interface/backend_adapter | ACTIVO_PREVIAMENTE_VALIDADO / REQUIERE_VALIDACION_ACTUAL_DEL_BACKEND | Panel web debe usar same-origin para evitar CORS/file://. |
| `RF_FORGE_UI` | interface | EN_PROGRESO |  |
| `RF_N8N_CANARY` | orchestration | OPERATIVO_CANARY_PREVIAMENTE_VALIDADO | orquestador visual reemplazable, no núcleo |
| `RF_EVENT_MODEL_V1` | memory/analytics | BASE_INICIAL_CERRADA | Base canónica para grafo y Markov; objetivo siguiente histórico: 100+ eventos. |
| `RF_GRAPH_MODEL_V1` | analytics | OK_BASE_INICIAL | Grafo útil para relaciones y validación; no meter Neo4j todavía. |
| `RF_MARKOV_V1` | analytics | VALIDATION_ONLY | Modelo de validación, no decisión operativa fuerte. Esperar 100+ eventos para interpretar patrones. |
| `RF_VISUAL_LAYOUT_ENGINE_V1` | visual/data | ACTIVO_COMO_BANCO_DE_CASOS | plantillas visuales, layout_spec, checklist, metadata |
| `RF_RESOURCE_DISCOVERY_GDRIVE_ZOD` | resources | TRIAGE_E_IMPORT_PLAN_VALIDADO_PREVIAMENTE | No copiar masivo sin dry-run. |
| `RF_SHORTCUTS_CORE` | iphone | ACTIVO_FUNCIONAL_PARCIAL |  |
| `RF_OBSIDIAN_BRIDGE` | memory/documentation | FUNCIONAL_PREVIAMENTE_VALIDADO | memoria documental, bitácora, evidencia y navegación humana |
| `RF_TELEMETRIA_OBSIDIAN_EXTRACTOR` | telemetry/data | DRYRUN_OK_EN_KW519 / APPLY_PENDIENTE_SEGUN_FLUJO | Captura de tabla real desde Web Clipper; falta normalización Apply cuando se pida. |


## [IPHONE — ENTORNO OPERATIVO]

| App | Rol |
|---|---|
| Termius | SSH hacia PC por Tailscale; comandos PowerShell en una sola línea. |
| Shortcuts | orquestación visual; formularios, llamadas API, Data Jar, NFC. |
| Data Jar | persistencia local de estado y runtime. |
| a-Shell/a-Shell mini | motor local Python/Shell dentro de ~/Documents/runeforge. |
| iCloud Drive | filesystem compartido para JSON/evidencia/shortcuts exportados. |
| Obsidian iOS | consulta documental, no ejecución. |
| Tailscale | canal seguro. |


### Reglas móviles

- iPhone vía Termius: una sola línea, sin saltos, sin here-strings, sin indentación.
- iPhone local a-Shell: preferir comandos compactos; si aparece >>> estás en Python REPL y debes salir con exit().
- Shortcuts: separar Acción / Campo / Valor; no inventar nombres de acciones.
- Atajos offline-first/híbridos con modos ONLINE, LAN, OFFLINE, SYNC_PENDING.

## [REGLAS DE EJECUCIÓN]

### Globales

- No avanzar con comandos encadenados sin validar la salida previa.
- Diagnóstico solo lectura por defecto salvo EJECUTAR/APLICAR/MODIFICAR explícito.
- Antes de comandos: validar sintaxis, comillas, paréntesis, llaves, variables, rutas, impacto y rollback si aplica.
- Si aparece prompt secundario >>: CTRL+C, esperar prompt normal, no pegar nada más.
- No imprimir secretos ni valores de .env.

### Formato obligatorio PowerShell

```txt
[OBJETIVO]
[VALIDACIÓN GPT]
[BLOQUE DE INSTRUCCIÓN]
[CONFIRMA CON]
[ESTADO]
```

### Impactos

```txt
SOLO_LECTURA
MODIFICA_ARCHIVOS
MODIFICA_FIREWALL
MODIFICA_BACKEND
MODIFICA_SERVICIOS
```

## [POLÍTICA CURRENT / SOBRESCRITURA]

```txt
ID        : RF_CURRENT_OVERWRITE_POLICY_V1
Objetivo  : evitar múltiples archivos repetidos de la misma temática y mantener un CURRENT actualizado
Current   : sobrescribir archivo CURRENT con backup timestamp previo
History   : conservar versión timestamp solo en hitos/evidencia
Backup    : obligatorio antes de overwrite
```

### Layout recomendado

| Tipo | Ruta |
|---|---|
| current | `C:\RUNEFOGE_PRO\runeforge\data\state\current` |
| history | `C:\RUNEFOGE_PRO\runeforge\data\state\history` |
| backups | `C:\RUNEFOGE_PRO\runeforge\data\state\_backups` |
| manifest | `C:\RUNEFOGE_PRO\runeforge\data\state\current\RUNEFORGE_STATE_MANIFEST.json` |

### Reglas

- Si el destino existe, copiarlo primero a _backups\<timestamp>.
- Después escribir con -Force.
- Registrar tamaño, fecha y SHA256 cuando aplique.
- Nunca sobrescribir .env, DB productiva, backups, firewall export, scripts críticos o código fuente sin precheck y rollback específico.
- Para reportes de estado recurrentes usar nombres CURRENT fijos.
- Para cierres de hito conservar también versión timestamp.

## [SEGURIDAD]

- .env fuera de Git y nunca expuesto.
- GitHub versiona, no guarda secretos.
- Google Drive respalda/documenta, no es base viva.
- Obsidian documenta, no ejecuta.
- n8n orquesta, no gobierna.
- PowerShell solo por acciones controladas; nada de shell libre.
- Markov/Grafos analizan, no ejecutan.

### Bloqueos

- run_powershell desde IA
- Invoke-Expression
- exec arbitrario
- n8n Execute Command libre
- automatización crítica sin trace
- Drive/GitHub como verdad viva
- agentes autónomos sin policy router

## [RIESGOS ABIERTOS]

| Riesgo | Impacto | Control |
|---|---|---|
| Expansión modular excesiva | Frankenstein modular | Congelar nuevas herramientas y cerrar flujo canónico completo. |
| Backend 3100/PM2 puede estar abajo en el último corte de Forge UI | UI no valida aunque el panel exista | Primero diagnóstico/read-only y arranque con node directo, sin patch. |
| Markov con muestra baja | Falsas conclusiones probabilísticas | Mantener VALIDATION_ONLY hasta 100+ eventos canónicos. |
| Memoria acumulada sin estructura | Fósiles digitales no reutilizables | Todo evento con tipo, fecha, origen, evidencia, trace y relación. |


## [SIGUIENTE PASO RECOMENDADO]

```txt
1. Validar/levantar backend 127.0.0.1:3100 antes de seguir Forge UI.
2. Instalar este paquete como CURRENT con backup previo.
3. Continuar acumulación de eventos canónicos hasta 100+ antes de usar Markov como lectura operativa.
```

## [VALIDACIÓN]

```txt
[ ] JSON maestro creado.
[ ] Markdown operativo creado.
[ ] Excel índice creado.
[ ] Script instalador creado.
[ ] No se tocaron rutas reales de Windows.
[ ] No se tocó backend.
[ ] No se leyeron secretos.
[ ] El paquete es portable.
```

## [ESTADO]

```txt
ESTADO=RUNEFORGE_GLOBAL_STATE_CURRENT_GENERADO
SIGUIENTE=INSTALAR_CURRENT_CON_BACKUP_PREVIO_SI_LO_QUIERES_APLICAR_EN_PC
PENDIENTES=CONFIRMAR_PM2_3100; CONFIRMAR_RUTA_DE_INSTALACION; CONFIRMAR_SI_SE_COPIA_A_OBSIDIAN
```
