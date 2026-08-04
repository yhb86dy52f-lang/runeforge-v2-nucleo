# RUNEFORGE - Plan de Normalización de Nombres

## Criterio
No se renombra ninguna carpeta activa sin revisar dependencias.

## Plan
| current | proposed | action | risk | reason |
| --- | --- | --- | --- | --- |
| C:\RUNEFOGE_PRO\runeforge | C:\RUNEFOGE_PRO\runeforge | MANTENER | BAJO | Raíz activa declarada. No romper referencias. |
| C:\RUNEFOGE_PRO\runeforge\app | C:\RUNEFOGE_PRO\runeforge\app | MANTENER | BAJO | Backend principal según estructura cerrada. |
| C:\RUNEFOGE_PRO\runeforge\scripts | C:\RUNEFOGE_PRO\runeforge\scripts | MANTENER | BAJO | Automatización central. Nombre simple y claro. |
| C:\RUNEFOGE_PRO\runeforge\lab | C:\RUNEFOGE_PRO\runeforge\lab | MANTENER | BAJO | Pruebas controladas. Correcto para RF Security Lab. |
| C:\RUNEFORGE_PRO | C:\RUNEFOGE_PRO\runeforge\archive\legacy_RUNEFORGE_PRO | PROPONER_MIGRACION_NO_APLICADA | ALTO | Ruta inconsistente sin E: C:\RUNEFORGE_PRO vs C:\RUNEFOGE_PRO. Requiere revisar contenido antes de mover. |
| C:\Users\nesth\Documents\EL_ABISMO | C:\Users\nesth\Documents\EL_ABISMO | MANTENER_COMO_MEMORIA_EXTERNA | MEDIO | Memoria documental/IA; no debe mezclarse con backend. |

## Aplicación futura segura
1. Inventariar contenido de ruta no canónica.
2. Confirmar que no hay procesos apuntando a esa ruta.
3. Crear backup.
4. Mover a rchive.
5. Crear nota de migración.
6. Validar backend y PM2.

## Estado
PENDIENTE_APLICACION
