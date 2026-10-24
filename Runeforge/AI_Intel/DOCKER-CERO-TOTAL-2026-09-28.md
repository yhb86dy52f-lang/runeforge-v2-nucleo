---
sello: Forneus
sello_numero: 30
origen: RUNEFORGE_V2_CORE
tipo: AI_Intel
up: "[[Runeforge/MOCs/MOC-AI_Intel]]"
tags: [Runegea, AI, Forneus, Docker, cero, desinstalacion, WSL, AppPath, ntfy]
fecha_forja: 2026-09-28
puertos_core: [3100, 11434, 3198, 8085]
---

> [!RUNE] Sello #30 Forneus
> Forjado desde anillo huérfano -> [[Runeforge/MOCs/MOC-AI_Intel]]

# DOCKER CERO TOTAL - TODO BORRADO Y DESPEGUE

**Acción:** Desinstalación completa todo todo todo + reinstalación limpia desde https://docs.docker.com/desktop/setup/install/windows-install/
**Borrado:** %AppData%\Docker, %LocalAppData%\Docker, Program Files\Docker, ProgramData\Docker, .docker, registros HKCU/HKLM Docker, WSL docker-desktop y docker-desktop-data, WSL AppPath corrupto
**Recreado:** HKLM App Paths\wsl.exe AppPath=C:\Windows\System32\ + WSL update
**Reinstalado:** Docker Desktop Installer.exe --quiet --accept-license --backend=wsl-2 per-user recomendado
**ntfy privado gratis:** http://localhost:8085/runeforge-estatus en Docker runeforge-ntfy + tailscale serve bg 8085

**Estado:** Docker Engine OK, ntfy privado UP, tailnet runeforge.tail12b297.ts.net