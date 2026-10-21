# RUNEFORGE V2 CORE — Explicado para alguien que no sabe nada

## ¿Qué es esto?

Imagina que tienes una **fábrica de juguetes** en tu computadora.

En lugar de hacer cada juguete desde cero, ya tienes:
- Un molde (la plantilla)
- Las herramientas (Rust, Tauri, sccache)
- Los materiales guardados (la bodega de piezas)

**RUNEFORGE** es esa fábrica. Le dices "quiero una app para dictar por voz"
y en pocos minutos tienes un programa .exe que abre en Windows como
cualquier otro.

## ¿Para qué sirve en la vida real?

Vas a poder crear:
- **Programas de escritorio** que abren con doble clic
- **Apps que funcionan sin internet** (todo está dentro del .exe)
- **Herramientas que se actualizan solas** (van a GitHub, ven si hay versión nueva, se bajan)

Ejemplo real que ya funciona: **DICTATE Studio**
- Es un programa que abre una ventana de 1440x900 píxeles
- Sirve para dictar por voz y transcribir con Inteligencia Artificial
- Está en C:\RUNEFORGE_V2_CORE\apps\dictate-studio-v2

## ¿Cómo funciona? (con palabras simples)

Imagina 4 capas:

| Capa | Qué es | Dónde está |
|---|---|---|
| 1. El molde | Una plantilla de app vacía | pps\_template |
| 2. El motor | La parte que corre rápido (Rust) | pps\...\src-tauri |
| 3. La cara | Lo que ves en pantalla (HTML) | pps\...\dist\index.html |
| 4. El repartidor | Va a GitHub a ver si hay actualización | 	auri.conf.json |

## ¿Por qué antes tardaba 1-2 HORAS y ahora 10-20 segundos?

Antes, cada vez que hacías una app, la computadora **fabricaba todos los
ladrillos de LEGO desde cero**. Cada ladrillo = un pedacito de código.

**Ahora instalaste sccache** (versión 0.18.0). Funciona como una bodega:
- Primera vez: fabrica los ladrillos, los guarda en la bodega
- Segunda vez: en lugar de fabricarlos, los saca de la bodega

La bodega está en C:\RUNEFORGE_V2_CORE\.sccache y ya tiene **1004 MB de
ladrillos guardados**.

## ¿Qué hay dentro de la caja grande?

En C:\RUNEFORGE_V2_CORE hay muchas carpetas. Las principales:

- **apps/** → tus programas (dictate-studio-v2, nexus-lab, etc.)
- **.sccache/** → la bodega de ladrillos (para compilar rápido)
- **runeforge-v2-nucleo/simulador/** → PWA local, inicia con Lanzar_RUNEFORGE.bat.
- **scripts/** → herramientas para automatizar cosas
- **docs/** → documentos como este
- **firmware/** → código para chips pequeños (ESP32)
- **whisper-backend/** → motor de transcripción de voz

## ¿Qué es GitHub?

Es como Google Drive pero para programadores. Ahí guardas tus apps
para que no se pierdan.

**Tu cuenta actual es:** yhb86dy52f-lang
**Tu repositorio:** uneforge-v2-nucleo

## Resumen para recordar

**RUNEFORGE = tu fábrica personal de apps de Windows que ya no tarda horas.**
