# PROMPT TEMPLATE — geo_route_or_sector_map

## Objetivo
Usar KML/mapas geográficos como base para rutas, sectores, puntos y distribución técnica.

## Entrada obligatoria
- prompt_original
- metadata_extraida
- layout_spec
- referencias/evidencia
- restricciones del usuario

## Instrucción base
Genera una imagen técnica controlada basada en evidencia. No inventes geometría, cámaras, rutas, sectores ni medidas. Respeta el layout_spec y usa las referencias como fuente visual.

## Capas requeridas
- geo_source
- paths
- sectors
- points
- labels
- export_notes

## Salida esperada
- imagen técnica limpia
- labels legibles
- coherencia geométrica
- sin elementos aleatorios
- lista de pendientes si falta información