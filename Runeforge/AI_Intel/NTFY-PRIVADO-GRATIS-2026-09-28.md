---
sello: Forneus
sello_numero: 30
origen: RUNEFORGE_V2_CORE
tipo: AI_Intel
up: "[[Runeforge/MOCs/MOC-AI_Intel]]"
tags: [Runegea, AI, Forneus, ntfy, notificaciones, privado, gratis, tailnet]
fecha_forja: 2026-09-28
puertos_core: [3100, 11434, 3198, 8085]
---

> [!RUNE] Sello #30 Forneus
> Forjado desde anillo huérfano -> [[Runeforge/MOCs/MOC-AI_Intel]]

# NTFY PRIVADO GRATIS - RUNEFORGE

**Fecha:** 2026-09-28
**Puerto:** 8085
**Topic:** runeforge-estatus
**Modo:** Self-host privado 100% local-first, sin ntfy.sh público
**Tailnet:** desktop-ndfe0b0.tailad757b.ts.net

## Resumen
ntfy self-host levantado en Docker runeforge-ntfy, gratis y privado, integrado a Get-Runegea-Estatus-Content.ps1

## Uso
- App ntfy -> Settings -> Add Server -> http://100.111.32.10:8085 o https://runeforge.tail12b297.ts.net
- Subscribe -> runeforge-estatus
- Test: curl -d "Hola Runeforge" http://localhost:8085/runeforge-estatus

## Integración
El script Get-Runegea-Estatus-Content.ps1 ahora envía push automático al topic privado tras cada ejecución.

## Estado
✅ Config en C:\RUNEFORGE_V2_CORE\ntfy-config/server.yml con deny-all
✅ Cache en C:\RUNEFORGE_V2_CORE\ntfy-cache
✅ Docker: runeforge-ntfy
✅ Tailscale serve bg 8085

**Forjado por RUNEFORGE Agent - Mente de Pionero - PWSH 7.6.3+ Autónomo**