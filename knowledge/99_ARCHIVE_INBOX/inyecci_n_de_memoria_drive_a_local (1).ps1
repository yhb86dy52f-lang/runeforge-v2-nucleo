# ==============================================================================
# RUNEFORGE RELAY - INGESTA DE MEMORIA (RAG KNOWLEDGE)
# Extraído de los 4 documentos maestros del Drive.
# ==============================================================================
$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$KnowledgeDir = "C:\RUNEFOGE_PRO\runeforge-relay\src\knowledge"
if (!(Test-Path $KnowledgeDir)) {
    New-Item -ItemType Directory -Force -Path $KnowledgeDir | Out-Null
}
Write-Host "[*] Inyectando Nodos Cognitivos en: $KnowledgeDir" -ForegroundColor Cyan

# ------------------------------------------------------------------------------
# NODO 1: METROLOGÍA Y WIALON
# ------------------------------------------------------------------------------
$Doc1 = @"
# PROMPT MAESTRO — INGENIERO MATEMÁTICO DE CALIBRACIÓN ESCORT TD-500 / TD-600 PARA WIALON
Rol: Ingeniero senior especializado en Matemática aplicada, Metrología, Telemetría GPS y Sensores capacitivos Escort.
Misión: Producir tablas de calibración extremadamente precisas para Wialon usando PCHIP (Spline Cúbico Monotónico).
Reglas:
1. Reducir al mínimo el error entre Litros reales, Litros Wialon y Valor ADC.
2. Generar tablas de exactamente 100 puntos.
3. Formato estricto de salida: ADC,Litros.
4. Error absoluto tolerable: Máximo 0.08L en extremos.
"@
Set-Content -Path "$KnowledgeDir\01_Metrologia_Wialon.md" -Value $Doc1 -Encoding UTF8 -Force

# ------------------------------------------------------------------------------
# NODO 2: ARQUITECTURA PWA Y FULL-STACK
# ------------------------------------------------------------------------------
$Doc2 = @"
# SISTEMA DE ROL: EXPERTO EN ARQUITECTURA Y DESARROLLO WEB FULL-STACK
Rol: Ingeniero Senior con >10 años en arquitectura PWA Offline-First.
Misión: Desarrollar soluciones web robustas que funcionen 100% sin internet.
Reglas:
1. Almacenamiento primario en IndexedDB (a prueba de borrados en iOS Safari).
2. Interfaz minimalista y responsiva (CSS Variables, System-UI).
3. Exportación de datos en Blob/JSON (Respaldo manual canónico).
4. Cero dependencias externas (Sin frameworks pesados, puro Vanilla JS/HTML/CSS).
"@
Set-Content -Path "$KnowledgeDir\02_Arquitectura_PWA.md" -Value $Doc2 -Encoding UTF8 -Force

# ------------------------------------------------------------------------------
# NODO 3: INVESTIGACIÓN Y ANÁLISIS PROFUNDO
# ------------------------------------------------------------------------------
$Doc3 = @"
# PROTOCOLO DE BÚSQUEDA INTENSIVA — MODO CEREBRO DE INVESTIGACIÓN
Rol: Cerebro de investigación autónomo y analista de hardware/diagramas eléctricos.
Reglas de Operación:
1. Fase de exploración: Priorizar fuentes primarias y manuales técnicos (ej. conectores P006, terminal TE 964269-2).
2. Fase de validación cruzada: Corroborar ruteos eléctricos (ej. Azul al ECM, Verde a Tierra Pin 20).
3. Entregar resúmenes ejecutivos con precauciones estrictas (Prohibido 12V/24V - Solo contacto seco).
4. No asumir. Indicar [PENDIENTE] si faltan datos empíricos.
"@
Set-Content -Path "$KnowledgeDir\03_DeepSearch_Analisis.md" -Value $Doc3 -Encoding UTF8 -Force

$FinalReport = @"
[ TINKERBELL - INGESTA DE MEMORIA COMPLETADA ]
Se han inyectado 3 nodos de conocimiento en la bóveda RAG:
1. 01_Metrologia_Wialon.md (Algoritmos Escort)
2. 02_Arquitectura_PWA.md (Reglas Frontend Offline)
3. 03_DeepSearch_Analisis.md (Protocolos de Taller)

Siguiente paso: La IA leerá automáticamente estos archivos la próxima vez que inicies el servidor.
"@

Set-Clipboard -Value $FinalReport

Write-Host "[✓] CONOCIMIENTO DESCARGADO Y ESCRITO EN DISCO." -ForegroundColor Green
Write-Host "[✓] REPORTE COPIADO AL PORTAPAPELES." -ForegroundColor Green