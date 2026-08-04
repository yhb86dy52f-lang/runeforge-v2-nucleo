# RF_VISUAL_IMAGE_DEVELOPMENT_FOCUS_V1

Estado: ACTIVO
Modulo: RF_VISUAL_LAYOUT_ENGINE_V1

## Enfoque actual

entrada previa -> extraccion de reglas -> layout_spec.json -> plantilla reutilizable -> biblioteca creciente -> generacion mas consistente

## Registro obligatorio por caso

- PROMPT ORIGINAL
- METADATA EXTRAIDA
- LAYOUT_SPEC
- CHECKLIST
- RESULTADO
- VERSION

## Categorias iniciales
- vehicle_blueprint_transport
- electrical_sensor_diagram
- maintenance_technical_diagram
- architectural_site_layout
- security_route_map
- sector_distribution_map
- parking_distribution_layout
- croquis_to_blueprint
- cctv_coverage_map

## Politica

- No generar imagenes aleatorias.
- No guardar prompts sueltos sin metadata.
- Todo resultado debe alimentar plantilla, checklist y version.
- Si falta informacion, marcar PENDIENTE.

## Estado

backend=NO_TOCADO
n8n=NO_TOCADO
siguiente=RF_VISUAL_RESOURCES_IMPORT_V1