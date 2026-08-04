# PROMPT TEMPLATE — croquis_to_blueprint

## Objetivo
Convertir croquis, satélite o imagen base en plano técnico limpio con sectores, bordes, rutas y etiquetas.

## Entrada obligatoria
- prompt_original
- metadata_extraida
- layout_spec
- referencias/evidencia
- restricciones del usuario

## Instrucción base
Genera una imagen técnica controlada basada en evidencia. No inventes geometría, cámaras, rutas, sectores ni medidas. Respeta el layout_spec y usa las referencias como fuente visual.

## Capas requeridas
- source_trace
- clean_boundaries
- zones
- routes
- labels
- scale_notes

## Salida esperada
- imagen técnica limpia
- labels legibles
- coherencia geométrica
- sin elementos aleatorios
- lista de pendientes si falta información