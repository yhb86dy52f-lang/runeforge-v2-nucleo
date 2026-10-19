---
sello: Forneus
sello_numero: 30
origen: 00_INBOX
tipo: AI_Intel
up: "[[Runeforge/MOCs/MOC-AI_Intel]]"
tags: [Runegea, AI, Forneus]
fecha_forja: 2026-09-28
---

> [!RUNE] Sello #30 Forneus
> Forjado desde anillo huérfano -> [[Runeforge/MOCs/MOC-AI_Intel]]

## Resumen de fusión

Este documento fusiona tus dos clippings del 2026-08-15:

1.  **Página de inicio de la Consola AWS (us-east-2)** - Estás logueado como root. Vista de widgets por defecto.
2.  **Tailscale Machines** - Tu tailnet tiene 2 dispositivos online en la misma cuenta `forgerrune@gmail.com`.

### 1. Página de inicio de la Consola

La página de inicio de la consola muestra widgets con información importante sobre el entorno de AWS.

> **Dato del video (58s):** En tu grabación se ve `AWS Health` con 1 problema abierto, `Costo y uso` en 0 US$ de 100 US$ de créditos, y el banner azul "Habilitación de reglas de participante - Nuevo Control". Confirmado que ya estás dentro, no necesitas reset.

**Personalización del panel:**
- **Agregue widgets** mediante **+Agregar widgets** + arrastre con el indicador de 6 puntos.
- **Elimine** con los 3 puntos verticales arriba a la derecha del widget.
- **Reorganice** arrastrando con el indicador de 6 puntos.
- **Cambie tamaño** arrastrando el icono de la esquina inferior derecha.

Ref: [Trabajar con widgets](https://docs.aws.amazon.com/awsconsolehelpdocs/latest/gsg/work-with-widgets.html?icmpid=docs_console_unmapped)

### 2. Tailscale - Estado actual

[Learn more](https://tailscale.com/docs/features/access-control/device-management/how-to/filter)

**2 machines conectadas:**

| Machine | IP Tailscale | Cuenta | Acción pendiente |
| --- | --- | --- | --- |
| desktop-ndfe0b0 | 100.83.105.117 | forgerrune@gmail.com | Ninguna |
| runeforge | 100.100.167.48 | forgerrune@gmail.com | Ejecutar `sudo tailscale set --ssh` dentro de la instancia |

Ambas máquinas ya están en la tailnet, por lo que el túnel EC2 <-> Desktop ya existe.

### 3. Siguiente paso (lo que te faltaba en el video)

Como ya tienes la red montada, lo que intentabas hacer al final del video (CloudShell) no es necesario. Ve directo:

```bash
# Desde tu desktop con Tailscale ya conectado:
ssh forgerrune@runeforge
# o por IP:
ssh 100.100.167.48

# Una vez dentro de runeforge:
sudo tailscale set --ssh
sudo tailscale up --ssh
```

Esto habilita Tailscale SSH y ya no necesitas abrir puerto 22 en el Security Group de EC2.

### Contexto guardado

- Región activa en clipping: `us-east-2`
- Console Home URL: `https://us-east-2.console.aws.amazon.com/console/home?region=us-east-2`
- Tailscale Admin: `https://console.tailscale.com/admin/machines`
