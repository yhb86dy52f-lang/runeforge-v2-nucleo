# Resumen Conceptual: Procesamiento y Estructuración de Telemetría AVL

Este documento resume la arquitectura conceptual, el flujo de procesamiento de datos de telemetría e integración en el grafo de conocimiento (**Obsidian**) realizado a partir de la información de rastreo vehicular y monitoreo de flota.

---

## 1. Mapeo del Flujo de Datos

```
[ Unidades de Flota ] 
        │
        ├── Escoltas (e.g., Escolta 03)
        └── Tractocamiones (e.g., KW 645, KW 680)
        │
        ▼
[ Dispositivos AVL / Telemetría ] 
        │
        ├── Posicionamiento (Latitud, Longitud, Velocidad)
        ├── Sensores FLS (Tanque 1, Tanque 2)
        └── Diagnóstico (Voltaje Batería, Odómetro)
        │
        ▼
[ Consolidación & Estructuración (Markdown) ]
        │
        ├── seguimiento.md   --> Tabla de control de unidades y resolución
        ├── mensajes.md      --> Telemetría en tiempo real y lecturas FLS
        └── dashboard.md     --> Métricas de desempeño y consumo gerencial
        │
        ▼
[ Base de Conocimiento Local (Obsidian PKM) ]
```

---

## 2. Componentes Clave del Sistema

### A. Seguimiento de Unidades (`seguimiento.md`)
* **Objetivo:** Monitoreo operativo y control de estado para resolución de incidencias.
* **Métricas Principales:**
  * Identificador de Unidad (Escoltas y serie KW).
  * Estado de resolución e interacciones.
  * Vinculación de eventos clave.

### B. Registro de Mensajes AVL (`mensajes.md`)
* **Objetivo:** Registro granular de eventos telemáticos para auditoría física y mecánica.
* **Métricas Analizadas:**
  * **Velocidad Promedio:** $83.53 \text{ km/h}$
  * **Velocidad Máxima:** $111.00 \text{ km/h}$
  * **Niveles de Combustible Dual (FLS):** Monitoreo simultáneo de Tanque 1 y Tanque 2.
  * **Salud del Sistema:** Monitoreo de voltaje nominal (promedio $13.8\text{ V}$).

### C. Dashboard y Análisis Gerencial (`dashboard.md`)
* **Objetivo:** Visión macro de flota para toma de decisiones tácticas y operativas.
* **KPIs Directivos:**
  * **Conectividad:** $504$ Unidades Conectadas vs. $154$ Desconectadas.
  * **Estado Operativo:** $391$ Unidades Paradas vs. $56$ Unidades en Movimiento.
  * **Líder de Recorrido (Grupo):** *Gerente Abasolo* ($979.65\text{ km}$).
  * **Líder de Consumo (Unidad):** *KW 645* ($6,282.05\text{ L}$).

---

## 3. Modelo de Entidades y Relaciones (Obsidian Graph)

Para conectar estos archivos dentro de un **Knowledge Graph**, se utilizan los siguientes tipos de enlaces conceptuales:

* `[[seguimiento]]` $\rightarrow$ Relaciona eventos operativos con el estado actual de la unidad.
* `[[mensajes]]` $\rightarrow$ Alimenta los datos numéricos de velocidad, odómetro y FLS a cada unidad.
* `[[dashboard]]` $\rightarrow$ Agrupa las métricas de `[[seguimiento]]` y `[[mensajes]]` en indicadores gerenciales.

---

## 4. Próximos Pasos Sugeridos
1. Integrar etiquetas (*tags*) como `#telemetria`, `#flota`, `#fls` para facilitar las búsquedas.
2. Definir alertas automatizadas para fluctuaciones abruptas en las lecturas de los tanques FLS.
3. Vincular los registros de consumo con las rutas de mayor kilometraje para calcular eficiencias ($km/L$).