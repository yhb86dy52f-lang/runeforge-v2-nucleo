# PROMPT PARA CHATGPT — CONEXIÓN PANEL HTML A WEBCCOMMAND

## 🎯 OBJETIVO PRINCIPAL
POST http://127.0.0.1:3100/api/webcommand

Conectar el panel HTML real (frontend de Runeforge) al endpoint:

El panel debe dejar de simular acciones y comenzar a ejecutar **comandos seguros reales** sobre el Action Router V3 / Actions Controladas V4.

---

## 🧠 CONTEXTO TÉCNICO (ESTADO ACTUAL)

### 🔹 Componentes validados como operativos

| Componente | Estado | Endpoint / Nota |
|------------|--------|------------------|
| **Runeforge Core** | ✅ Vivo | |
| **WebCommand** | ✅ Activo | `POST /api/webcommand` responde `{"ok":true, "service":"Runeforge WebCommand", "mode":"safe-readonly"}` |
| **n8n canary** | ✅ Operativo | |
| **Action Router V3** | ✅ Cerrado (estable) | |
| **Actions Controladas V4** | ✅ Cerrado | Incluye: `ping`, `echo`, `trace_event`, `health_check_request` |
| `run_powershell` | ❌ **Bloqueado** | No debe usarse en este panel |

### 🔹 Hitos ya validados

- ✅ `RF_ACTIONS_CONTROLADAS_V4` con:
  - `ping` → verifica conectividad interna.
  - `echo` → prueba de respuesta.
  - `trace_event` → registra eventos en el sistema de trazabilidad.
  - `health_check_request` → consulta estado del Core.
- ✅ `run_powershell` **bloqueado explícitamente** (no permitido).

---

## 📌 REQUISITOS DEL PANEL HTML

### 1. Acciones permitidas (solo las que están en Actions Controladas V4)

El panel debe tener botones que ejecuten **exactamente** estos comandos a través de `POST /api/webcommand`:

| Botón | Comando (JSON a enviar) |
|-------|--------------------------|
| 🟢 **Ping Core** | `{"action":"ping"}` |
| 🔁 **Echo test** | `{"action":"echo", "data":"mensaje de prueba"}` |
| 📝 **Trace event** | `{"action":"trace_event", "event":"user_click", "details":"botón X presionado"}` |
| ❤️ **Health check** | `{"action":"health_check_request"}` |

### 2. Comportamiento de cada botón

- Al hacer clic, se debe enviar una petición **POST** al endpoint `http://127.0.0.1:3100/api/webcommand` con el JSON correspondiente.
- Mostrar la respuesta del servidor en un área de **log/consola** dentro del propio panel.
- Si hay error de red o timeout, mostrar mensaje claro.
- No se debe permitir enviar `run_powershell` ni ningún otro comando no listado.

### 3. Estilo y usabilidad

- Panel limpio, oscuro (Cyber Monja / Tinkerbell), monoespaciado.
- Cada botón debe tener su propio indicador de carga (spinner o texto "Enviando...").
- Área de respuesta con scroll y formato JSON legible.
- El panel debe ser **100% local‑first** (no depende de internet, solo de `127.0.0.1:3100`).

---

## 🧱 ESTRUCTURA ESPERADA DEL CÓDIGO

Genera **un solo archivo HTML** (puede ser `.html` o incrustado en una respuesta) que contenga:

- Estilos CSS en `<style>`.
- Lógica JavaScript en `<script>`.
- Usar `fetch` con `async/await`.
- Manejador de errores (try/catch).
- No utilizar librerías externas (solo vanilla JS).

---

## ⚠️ RESTRICCIONES IMPORTANTES

- ❌ **No usar `run_powershell`**.
- ❌ **No simular acciones** (todo debe ir al endpoint real).
- ❌ **No depender de nube** (solo localhost).
- ✅ **Validar que el endpoint responda `ok:true` antes de habilitar botones** (opcional pero recomendado).
- ✅ **Registrar cada acción en el área de log** (timestamp + comando + respuesta).

---

## 📤 FORMATO DE RESPUESTA QUE ESPERO DE TI (CHATGPT)

1. **HTML completo** (copiar y pegar en un archivo `.html` y abrir en navegador).
2. **Explicación breve** de cómo se conecta al WebCommand.
3. **Comando de prueba** para verificar que el backend responde (curl opcional).
4. **Posibles errores** y cómo depurarlos (CORS, puerto no abierto, etc.).

---

## 🚀 EJEMPLO DE LLAMADA CORRECTA (desde JS)

```javascript
fetch('http://127.0.0.1:3100/api/webcommand', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ action: 'ping' })
})
.then(res => res.json())
.then(data => console.log(data));

 CRITERIO DE ACEPTACIÓN
El panel generado debe:

Ejecutar acciones reales sobre el Action Router V3.

Mostrar respuestas reales del Core.

No contener código simulado.

Funcionar en un navegador local (Chrome, Edge, Brave) apuntando a 127.0.0.1:3100.

Entiendo que ya tienes el endpoint funcionando y validado. Solo necesitas el frontend que lo consuma correctamente.

text

---

Este prompt ya incluye **todo el contexto**, las **acciones permitidas**, las **restricciones** y el **formato de respuesta esperado**. Cuando lo copies en ChatGPT, la IA generará el HTML exacto que necesitas para conectar tu panel real.
