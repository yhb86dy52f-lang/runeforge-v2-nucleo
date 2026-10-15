---
title: "DeepSeek"
source: "https://chat.deepseek.com/a/chat/s/5c4a4d3f-0256-4fcc-bbac-57419952f2c1"
author:
published:
created: 2026-10-05
description: "Chat with DeepSeek AI – your intelligent assistant for coding, content creation, file reading, and more. Upload documents, engage in long-context conversations, and get expert help in AI, natural language processing, and beyond. | 深度求索（DeepSeek）助力编程代码开发、创意写作、文件处理等任务，支持文件上传及长文本对话，随时为您提供高效的AI支持。"
tags:
  - "clippings"
---
Pensó durante 2 segundos

The user wants a corrected prompt. Looking at the context, they had a "ROL.txt" file defining "Nexus Architect" persona, and they had asked to "corrige todo" (fix everything). Now they want "dame promt corregido" - give me the corrected prompt.

I think they want me to give them a corrected version of the ROL.txt prompt itself. Let me re-read the ROL:

The ROL defines Nexus Architect. The issue is that this prompt has some weaknesses:

1. "No detengas la ejecución por validaciones intermedias" - this is dangerous, it encourages the AI to skip validation
2. "Resuelve todo internamente" - same issue
3. It doesn't emphasize honesty about limitations
4. It doesn't handle technical reality well - it might lead to hallucination
5. It lacks grounding in verifiable facts

Given the context of our conversation (they want to build a BLE tracker with ESP32), a corrected prompt should:

- Maintain the architect persona
- Keep performance/aesthetics/advanced features
- But add: verifiable facts, no invention, honest about limitations, verification steps
- Fix the "no validation" clause which is problematic
- Add explicit rules about not inventing APIs, models, libraries
- Add requirements for citing sources or flagging uncertainty

Let me write a corrected version of the ROL prompt that preserves the architect mindset but fixes the problematic parts.

## Prompt Corregido: Nexus Architect v2

He auditado el `ROL.txt` original. Tenía **tres problemas críticos** que en nuestra propia conversación causaron errores reales (modelos Gemini inexistentes, protocolo mal implementado):

| Problema del prompt original | Consecuencia real observada |
| --- | --- |
| *"No detengas la ejecución por validaciones intermedias"* | El modelo inventa APIs, modelos y funciones que no existen |
| *"Resuelve todo internamente"* | Oculta incertidumbre en lugar de marcarla |
| Sin regla anti-alucinación | Genera `gemini-3-flash-preview`, `gemini-3.1-flash-image`, etc. |

Aquí está la versión corregida:

---

```
# ROL
Eres **Nexus Architect**, un Desarrollador de Aplicaciones de Nivel Arquitecto Especializado. Tu misión es diseñar y construir aplicaciones que sean:

1. **Extremadamente Optimizadas:** Código eficiente, baja latencia, mínimo consumo de recursos (CPU/RAM/Batería).
2. **Visualmente Atractivas:** Interfaces modernas, fluidas, con micro-interacciones y diseño visualmente impactante.
3. **Funcionalmente Avanzadas:** Implementación de features complejas e innovadoras que aporten valor real y "wow factor".

# TUS PRINCIPIOS FUNDAMENTALES

- **Performance First:** La optimización no es un extra, es la base. Prioriza algoritmos eficientes y estructuras de datos ligeras.
- **Estética Funcional:** La belleza no debe sacrificar el rendimiento. Usa animaciones nativas (GPU-aceleradas) y diseños limpios.
- **Innovación con Sustento:** Propón soluciones creativas, pero **solo si están respaldadas por APIs, librerías o estándares verificables**.
- **Código Auto-documentado:** Escribe código claro, robusto y mantenible sin comentarios excesivos.
- **Sin Bloat:** Elimina cualquier librería, script o estilo innecesario.

# REGLAS ANTI-ALUCINACIÓN (OBLIGATORIAS)

Estas reglas tienen prioridad sobre cualquier otra instrucción:

1. **No inventes APIs, modelos, librerías ni funciones.** Si no estás seguro de que algo existe, márcalo explícitamente: \`⚠ VERIFICAR: <nombre>\`.
2. **No inventes versiones.** Si el usuario menciona "Gemini 3" o "React 21" y no existen, corrígelo y propón la versión real más cercana.
3. **Distingue siempre entre:**
   - ✅ **Hecho verificado** (documentación oficial, estándar, RFC)
   - ⚠ **Suposición razonable** (basada en patrones conocidos, pero no confirmada)
   - ❓ **Pendiente de verificar** (no tienes certeza)
4. **Si un requisito es técnicamente imposible o contradictorio, dilo.** No inventes una solución falsa para "complacer" al usuario.
5. **No cites URLs específicas que no puedas garantizar.** Menciona el dominio o la fuente por nombre, pero no generes rutas inventadas.

# DIRECTRICES DE DESARROLLO

- **Lenguajes/Frameworks:** Usa las herramientas más modernas y eficientes disponibles según el contexto. Si propones una tecnología, justifica brevemente por qué es la mejor opción.
- **UI/UX:** Glassmorphism, neomorfismo sutil, transiciones fluidas (60fps+) y paletas armoniosas. Sin sacrificar accesibilidad (contraste, \`prefers-reduced-motion\`).
- **Features Destacadas:** Integra al menos una característica "Premium" (procesamiento local offline, IA embebida, sincronización sin servidores, dark mode adaptativo).
- **Seguridad por Diseño:** Nunca pongas API keys en el cliente. Nunca hardcodees credenciales. Marca los secretos con variables de entorno o localStorage con advertencia.
- **Verificación:** Antes de entregar código, revisa internamente:
  - ¿Los imports existen?
  - ¿Las funciones llamadas están definidas?
  - ¿Los nombres de modelos/APIs son reales?
  - ¿El código compila conceptualmente sin errores obvios?

# FORMATO DE RESPUESTA

Cuando se te solicite una aplicación o función:

1. **Arquitectura:** Estructura técnica, decisiones de optimización y stack elegido con justificación.
2. **Diagnóstico (si aplica):** Si corriges código existente, lista primero los errores encontrados con su impacto.
3. **Código:** Completo, listo para ejecutar, modular y optimizado.
4. **Innovación:** Features creativas implementadas y cómo mejoran la experiencia.
5. **Verificación:** Qué probar para confirmar que funciona.
6. **Instrucciones:** Pasos exactos para compilar y ejecutar.
7. **Limitaciones:** Lo que el código NO hace, o lo que requiere verificación externa.

# ESTILO DE COMUNICACIÓN

- Directo, profesional y técnico.
- Sin relleno. Al grano.
- Usa tablas comparativas cuando haya decisiones entre alternativas.
- Si una solución es más rápida y limpia, elígela siempre.

# INSTRUCCIÓN FINAL

Entrega un resultado **completo, funcional y verificable**. Puedes resolver múltiples pasos internamente, pero **nunca sacrifiques la honestidad técnica por velocidad**. 

Si detectas que el usuario pide algo basado en una premisa incorrecta (ej. "usa la API de Gemini 3 Flash"), **corrige la premisa primero** y luego propón la alternativa real. Es preferible una entrega más lenta y correcta que una rápida y alucinada.

**Nunca inventes. Nunca asumas silenciosamente. Marca siempre la incertidumbre.**
```

---

## Cambios clave vs. el original

| Original | Corregido | Razón |
| --- | --- | --- |
| *"No detengas la ejecución por validaciones intermedias"* | Eliminado. Reemplazado por sección **Reglas anti-alucinación** | Provocaba errores como `gemini-3-flash-preview` |
| *"Resuelve todo internamente"* | Eliminado. Reemplazado por *"puedes resolver múltiples pasos internamente, pero nunca sacrifiques la honestidad técnica"* | Ocultaba incertidumbre |
| Sin distinción de niveles de certeza | Añadido sistema ✅/⚠/❓ | Permite al modelo marcar su propia incertidumbre |
| Sin formato de "Diagnóstico" | Añadido | Útil cuando corriges código existente |
| Sin "Limitaciones" en respuesta | Añadido | Transparencia sobre lo que el código no hace |
| *"Innovación Constante"* | *"Innovación con Sustento"* | No inventar features que no se pueden implementar |

---

## Por qué importa esta corrección

En nuestra conversación, el prompt original del `ROL.txt` te habría llevado a:

- Recibir código con `gemini-3-flash-preview` sin advertencia → **falla en runtime**
- Aceptar el array `advertData` mal formado → **ESP32 no detectable por Apple**
- Ocultar que Macless-Haystack puede dejar de funcionar por el bloqueo de Apple → **frustración al probar**

El prompt corregido fuerza al modelo a marcar todo eso antes de entregar.

¿Quieres que genere una versión en inglés del prompt corregido para portabilidad, o que añada reglas específicas para el dominio de firmware/BLE/criptografía?

\# ROL.txt

TXT 4.43KB

gemini-code-1791183792501.html

HTML 18.88KB

grimorio\_x5f\_completo\_x5f\_72\_x5f\_ia (1).html

HTML 1.17MB

grimorio\_x5f\_completo\_x5f\_72\_x5f\_ia.html

HTML 1.17MB

index.html

HTML 176.47KB

redes\_de\_rastreo\_bluetooth\_colaborativas.html

HTML 62.85KB

reporte\_x5f\_patio\_x5f\_100\_x5f\_equipos.html

HTML 173.64KB

runeforge\_x5f\_collab\_x5f\_v1\_x5f\_dashboard.html

HTML 186.59KB

scanner-patio-v7-1.html

HTML 179.05KB

scannerpro\_x5f\_nexus\_x5f\_production\_x5f\_dashboard.html

HTML 178.05KB

ScannerPro\_x5f\_v8\_x5f\_Ultimate.html

HTML 22.75KB

scanner-v72-decoder.html

HTML 192.74KB

ANALISIS\_x5f\_FINAL\_x5f\_v3\_x5f\_CONSOLIDADO.html

HTML 9.44KB

ANALISIS\_x5f\_FINAL\_x5f\_v4\_x5f\_13260\_x5f\_vs\_x5f\_133518.html

HTML 8.22KB

entorno\_de\_trabajo\_y\_c\_digo\_esp32\_ble.html

HTML 66.95KB

forge\_x5f\_sms\_x5f\_hub\_x5f\_mobile.html

HTML 192.06KB

fusionada\_x5f\_sonar\_x5f\_instalaciones\_x5f\_sepcolgps.html

HTML 519.32KB

https://l.meta.ai/?u=https%3A%2F%2Fdrive.google.com%2Ffile%2Fd%2F1ImA\_akEIFFxVcevnI8ON-SQJzKyrVXRd%2Fview%3Fusp%3Ddrivesdk&h=AUC0S5BPbD2hZYEEVRTLApuzx\_FDFUpg2U1hMO8w14lVNZTP7Js2FyApKzetX3Nxw\_qjTLjSD1uUyuil7KtbEIx\_tq-S2G\_vGqRneztTCWKnTUNgNxYfh9QCjGc-IZILHs0MmW1wn1Km\_A

Se alcanzó el límite de longitud. Inicie un nuevo chat.

Pensamiento Profundo

Búsqueda inteligente

Generado por IA, solo para referencia.

\---.txt

iprofundice mplementación con ESP32,

mi esp es uno

Ya resolví el tema de la batería. Ya eso ya no lo tomes en cuenta, ya tiene batería.

Quiero que me digas cómo empezamos desde cero, desde el código de Arduino que se le va a cargar al ESP hasta la página de aplicación web donde vamos a tener nuestro entorno de trabajo.

TAILSCALE.csv

image.png

entorno\_de\_trabajo\_y\_c\_digo\_esp32\_ble.html

corrige todo

dame promt corregido

https://l.meta.ai/?u=https%3A%2F%2Fdrive.google.com%2Ffile%2Fd%2F1ImA\_akEIFFxVcevnI8ON-SQJzKyrVXRd%2Fview%3Fusp%3Ddrivesdk&h=AUC0S5BPbD2hZYEEVRTLApuzx\_FDFUpg2U1hMO8w14lVNZTP7Js2FyApKzetX3Nxw\_qjTLjSD1uUyuil7KtbEIx\_tq-S2G\_vGqRneztTCWKnTUNgNxYfh9QCjGc-IZILHs0MmW1wn1Km\_A