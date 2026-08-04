# PROMPT TEMPLATE — cctv_coverage_map

## Objetivo
Generar o limpiar mapas/layouts de CCTV, cobertura, zonas, cámaras, rutas internas y visor técnico.

## Entrada obligatoria
- prompt_original
- metadata_extraida
- layout_spec
- referencias/evidencia
- restricciones del usuario

## Instrucción base
Genera una imagen técnica controlada basada en evidencia. No inventes geometría, cámaras, rutas, sectores ni medidas. Respeta el layout_spec y usa las referencias como fuente visual.

## Capas requeridas
- base_map
- camera_points
- coverage_zones
- routes
- labels
- legend

## Salida esperada
- imagen técnica limpia
- labels legibles
- coherencia geométrica
- sin elementos aleatorios
- lista de pendientes si falta información