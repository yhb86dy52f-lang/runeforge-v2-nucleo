# MERGE RULES

## Objetivo
Fusionar memorias de distintas IA sin duplicados, sin contradicciones silenciosas y sin perder contexto operativo.

## Reglas
1. Conservar import crudo original.
2. No sobrescribir datos confirmados con datos inferidos.
3. Priorizar información más reciente solo si no contradice una confirmación explícita.
4. Marcar conflictos, no esconderlos.
5. Convertir texto narrativo en hechos canónicos cuando sea posible.
6. Eliminar duplicados semánticos.
7. Separar contexto histórico de contexto operativo actual.
8. Etiquetar cada hecho con source, status, confidence y last_verified.
9. No guardar secretos en memoria global.
10. Mantener proyectos en archivos separados además del resumen maestro.
