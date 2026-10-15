---
sello: Forneus
sello_numero: 30
origen: RUNEFORGE_V2_CORE
tipo: AI_Intel
up: "[[Runeforge/MOCs/MOC-AI_Intel]]"
tags: [Runegea, AI, Forneus, ntfy, docker, fix, privado]
fecha_forja: 2026-09-28
puertos_core: [3100, 11434, 3198, 8085]
---

> [!RUNE] Sello #30 Forneus
> Forjado desde anillo huérfano -> [[Runeforge/MOCs/MOC-AI_Intel]]

# FIX DOCKER + NTFY PRIVADO

**Problema:** Docker Engine 29.7.2 instalado pero npipe //./pipe/dockerDesktopLinuxEngine no respondía - Docker Desktop apagado
**Solución:** Start-Runeforge-Docker-Ntfy.ps1 levanta Docker Desktop, espera 90s, fallback a ntfy.exe via PM2 si sigue down

**Estado final:**
- ntfy-config/server.yml deny-all listo
- runeforge-ntfy en Docker o PM2 en 8085
- Tailscale serve 8085
- Test push a runeforge-estatus OK

**Comando app móvil:** Añadir servidor http://100.111.32.10:8085 + topic runeforge-estatus