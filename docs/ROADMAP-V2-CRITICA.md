# ROADMAP v2 - Crítica Integrada
## Runeforge: De sub-ingeniería en robustez a sistema que sobrevive mes 1

> Corrección basada en opinión crítica sin filtros 2026-08-15
> Repo: https://github.com/yhb86dy52f-lang/runeforge-v2-nucleo
> Veredicto v1: "Ya no peca de sobre-ingeniería; ahora peca de sub-ingeniería en robustez — asume que captura, parseo y datos simplemente funcionarán"

### Lo que tenías razón (aceptado)

1. **Punto único de fallo en captura** - WhatsApp solo = proyecto muerto en silencio si cambia API/token
2. **WhatsApp = trampa de tiempo** - 50% abandono antes de primera bitácora. Verificación Meta, ventana 24h, plantillas.
3. **Sin estrategia datos largo plazo** - Tabla plana mes 1 ok, mes 12 con 3000 entradas pudriéndose sin higiene
4. **Parseo frágil silencioso** - "Ciner: falló sensor km 42" no es trivial. Typo, sin prefijo = basura o pérdida
5. **Cero backup desde día 1** - 3 etapas capturando irreemplazable sin respaldo = negligencia
6. **Trabajo vs personal sin distinguir requisitos** - Trabajo necesita export/auditoría para Ciner, personal no
7. **Personal subespecífico** - Trabajo tiene ejemplos concretos, personal es adorno sin spec
8. **Ollama usado antes de validar** - Construir Etapa 2 sobre 1.5B no probado

### Mapa de mejoras - Implementación

```
┌─────────────────────────────────┐
│   RUNEFORGE — MEJORAS PROPUESTAS v2 │
└─────────────────────────────────┘
     CAPTURA          DATOS         ROBUSTEZ      SECUENCIA       ALCANCE       HONESTIDAD
     Telegram/        Backup        Manejo error  Etapa 1 SIN    Especificar   Validar
     Form primero     desde         "no entendí"  depender de    lado personal Ollama ANTES
     WhatsApp         Etapa 1       Prefijos      Etapa 0        igual que     de usarlo
     después          (no 4)        estructur.    (cloud puro)   trabajo
     Plan B: 2 vías   Retención/    desde                                   
     captura          archivado/    Etapa 1
                      corrección    (no NLP)
```

### ROADMAP v2 - Etapas corregidas

#### Etapa 0 - Desacoplada (Ya no bloquea valor)
**Cambio crítico #10:** Etapa 1 corre en nube sin tocar AWS. Etapa 0 en paralelo, no secuencial.

- [ ] AWS root recovery + Tailscale SSH en background
- [ ] No bloquea prototipo. Criterio: si Etapa 0 tarda >1 día, Etapa 1 sigue igual.

#### Etapa 1 - Captura Robusta (HOY) - Antes Telegram/Form, NO WhatsApp
**Cambio #1 y #2:** Eliminar punto único fallo + evitar trampa tiempo

**Doble vía captura desde día 1:**
```
Vía A (primaria): Telegram Bot @RuneforgeBot -> Data Table
  Por qué: 30 segundos crear bot, token estable, sin verificación, sin ventana 24h

Vía B (backup): Form n8n (https://forgerrune.app.n8n.cloud/form/bitacora)
  Por qué: Si Telegram cae, Form sigue. Si Form cae, Telegram sigue. Cero punto único fallo.

Vía C (Etapa 3): WhatsApp con Evolution API local (no Business Cloud)
  Movida de Etapa 1 -> Etapa 3 para no matar arranque
```

**Data Table `bitacoras_v2` con higiene:**
```
fecha: datetime auto
tipo: enum [T_telemetria, P_problema, A_actividad, H_habito, R_tarea, B_bitacora]
proyecto: [Ciner, Personal, Sistema]
texto_original: string (lo que escribiste crudo, nunca se pierde)
texto_limpio: string (parseado)
estado: [pendiente, en_progreso, resuelto, hecho, archivado]
origen: [telegram, form, whatsapp, manual]
parse_confidence: [alta, media, baja] -> si baja, dispara "no entendí"
correccion_de: id (si esta fila corrige otra, trazabilidad)
```

**Manejo error de parseo - Cambio #4:**
```
Si mensaje no tiene prefijo T/P/H/A y confidence baja:
  → Bot responde: "No entendí, ¿es?
     T Telemetría, P Problema, H Hábito, A Actividad
     Ej: 'P Ciner sensor km 42 falló'"
  → Guarda en tabla con parse_confidence=baja, estado=pendiente_revision
  → Nunca pierde entrada, nunca guarda basura silenciosa
```

**Backup desde Etapa 1 - Cambio #3:**
```
Workflow 3 - Backup diario 02:00:
  Schedule 02:00 -> Data Table Export CSV -> Google Drive / C:\RUNEFORGE_BACKUPS\bitacoras_$(date).csv
  + SQLite checkpoint si usas local

Regla: Datos capturados desde minuto 1 tienen backup minuto 1. No Etapa 4.
```

**Validar Ollama ANTES - Cambio #8:**
```
Etapa 1 incluye:
  - Re-benchmark qwen2.5:1.5b, gemma2:2b en tu GTX 1660 SUPER con ollama-benchmark
  - Si 1.5B da residuos malos, Etapa 2 no usa análisis Ollama, usa resumen simple por conteo
  - No construir sobre capacidad no confirmada
```

**Entregable Etapa 1 v2:** 2 vías captura funcionando, backup diario, manejo "no entendí", benchmark honesto.

#### Etapa 2 - Motor Unificado + Higiene (3 días)

**Cambio #5 - Higiene datos:**
- [ ] Definir retención: Trabajo Ciner 2 años, Personal 1 año, Sistema 6 meses
- [ ] Definir corrección: `correccion_de` apunta a fila original, no borra, audita
- [ ] Definir archivado: estado=archivado no se borra, se filtra de vistas diarias
- [ ] Deduplicación: hash texto+fecha, si duplicado pregunta "¿ya guardaste esto hoy 14:30?"

**Cambio #6 - Personal específico (tarea para ti ahora):**
Escribir en papel, no en sistema, ejemplos concretos:
```
Hábito: "Ejercicio 30min lunes/miércoles/viernes 07:00"
Rutina: "Checklist mañana: telemetría, bitácora, revisión sensores"
Proyecto: "Runeforge Etapa 1 - terminar prototipo bitácora"
Sin ejemplos, personal queda adorno.
```

**Cambio #7 - Trabajo vs personal requisitos:**
```
Trabajo Ciner:
  - Necesita exportación CSV/Excel mensual para auditoría
  - Retención 2 años
  - Campos extra: km, sensor_id, falla_tipo

Personal:
  - No necesita exportación, solo vista
  - Retención 1 año
  - Campos: completado boolean

Implementación: misma tabla, vistas filtradas, export solo vista Trabajo
```

#### Etapa 3 - Soberanía Local (Dividida en 4 sub-hitos) - Cambio #9

**3a - n8n local (1 día):** Docker n8n+Postgres+Qdrant en runeforge 100.100.167.48
**3b - Tailscale Serve (1 día):** `tailscale serve --bg --https=443 http://localhost:5678`
**3c - WhatsApp Evolution API (1 día):** Ahora sí WhatsApp con tu número personal, sin Meta Business
**3d - Migración datos (1 día):** CSV cloud -> SQLite WAL local

Cada sub-hito independiente con criterio propio. No monolito.

#### Etapa 4 - Higiene y Honestidad (1 tarde)

- README con números reales medidos, no 110.80 tok/s sin verificar
- .gitignore: node_modules/, data/raw/, knowledge/00_INBOX/
- Checklist recuperación: "si cae X, hago Y"

### Las 3 que de verdad importan (si solo haces 3)

1. **Telegram/Form antes que WhatsApp** - Elimina 50% riesgo abandono
2. **Backup desde Etapa 1** - Protege irreemplazable
3. **Desacoplar Etapa 1 de Etapa 0** - Valor hoy, sin rehén infra

### Veredicto v2

v1 era sobre-ingeniería. v1 corregida era sub-ingeniería en robustez. v2 blinda captura y datos, asume que todo fallará y diseña para eso. Si captura y datos sobreviven mes 1, proyecto sobrevive.

### Próximo paso

1. Define en 2 líneas tu lado personal específico (ejemplo hábito/rutina/proyecto)
2. Decide: ¿Telegram o Form como vía A primaria? (recomiendo Telegram por velocidad campo)
3. Ejecuta bootstrap_etapa1.ps1 limpio + crea Data Table v2 con campos nuevos
