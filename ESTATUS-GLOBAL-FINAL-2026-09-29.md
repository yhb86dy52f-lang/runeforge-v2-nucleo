---
sello: Forneus
sello_numero: 30
origen: RUNEFORGE_V2_CORE
tipo: AI_Intel
up: "[[Runeforge/MOCs/MOC-AI_Intel]]"
tags: [Runegea, AI, Forneus, ESTATUS-GLOBAL, Docker, CERO-TOTAL, ntfy, privado, gratis, cierre]
fecha_forja: 2026-09-29
nodos_totales: 97
nodos_esperados: 97
scripts_ps1: 42
puertos_core: [3100, 11434, 3198, 8085]
docker_engine: True
ntfy_container: 2125ec6781b3
ntfy_up: Up 12 minutes
tailnet: runeforge.tail12b297.ts.net
---

> [!RUNE] Sello #30 Forneus - Forjado desde anillo huérfano -> [[Runeforge/MOCs/MOC-AI_Intel]]
> Cierre de hoy 2026-09-29

# ESTATUS GLOBAL FINAL - 2026-09-29 - CIERRE DE HOY

## Resumen CERO TOTAL

**Docker Desktop:**
- Borrado total: %AppData%\Docker, %LocalAppData%\Docker, Program Files\Docker, ProgramData\DockerDesktop, .docker, ntfy-config/cache
- Registro corrupto: HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\wsl.exe AppPath recreado C:\Windows\System32\
- WSL: wsl --shutdown + --unregister docker-desktop + docker-desktop-data + --update
- Reinstalado: Docker Desktop Installer.exe --quiet --accept-license --backend=wsl-2 per-user
- Engine: UP en 10s - Container 2125ec6781b3 Up 12 minutes
- Dashboard: PERSONAL v4.93.0, RAM 2.89 GB, CPU 0.00%, Disk 1.60 GB used - Containers 1, ntfy verde

**ntfy privado gratis - Opción gratis y privada:**
- Imagen: binwiederhier/ntfy:latest
- Container: runeforge-ntfy 2125ec6781b3 Up 12 minutes 0.0.0.0:8085->80/tcp [::]:8085->80/tcp
- Config: C:\RUNEFORGE_V2_CORE\ntfy-config\server.yml
- Modo inicial ABIERTO por tailnet: base-url http://localhost:8085, behind-proxy true, sin auth - Publish OK id=IaiGtxz6Z9Jp, curl id=6QW8DlMUPl97
- Modo final PRIVADO con auth: auth-file /etc/ntfy/auth.db, auth-default-access deny-all - Usuario runeforge / Runeforge2026! - rw a runeforge-* y runegea-*
- Tests AUTH: id=G7x6qf7GvZ0r AUTH OK, id=3zmOI7qItrxb test OK
- Tailscale: 100.111.32.10:8085 + tailscale serve --bg 8085 -> https://runeforge.tail12b297.ts.net
- App: Server http://100.111.32.10:8085 con auth runeforge:Runeforge2026! -> topic runeforge-estatus
- 403 inicial: code 40301 forbidden -> Fix con Fix-Ntfy-Auth-403.ps1 -ModoAbierto y luego modo auth

**Puertos Core:**
- 3100 backend: pending
- 11434 ollama: pending
- 3198 headscale: pending
- 8085 ntfy privado: True - UP - 2125ec6781b3

**Nodos:**
- MD en Runeforge: 97
- Scripts PS1 en scripts/: 42+
- Esperados: 97

**Artefactos de hoy:**
- Uninstall-Docker-Completo-Cero.ps1 - CERO TOTAL con bug DisplayName PropertyNotFoundException
- Uninstall-Docker-Completo-Cero-FIXED.ps1 - Fix PSObject.Properties.Name contains DisplayName + Unique
- Fix-Ntfy-Auth-403.ps1 - Fix 403 forbidden con -ModoAbierto y modo auth - ambos OK
- docker-compose.yml - Solo ntfy, fix path C:\src\backend not found
- docker-compose.runeforge-ntfy.yml - Stack runeforge-net
- Get-Runeforge-Estatus-Final-2026-09-29.ps1 - Validador final con Test-Path + Where-Object

**Validación:**
- docker ps: 2125ec6781b3 binwiederhier/ntfy ntfy serve Up 12 minutes 8085:80 runeforge-ntfy
- curl -d sin auth 403 -> fix ModoAbierto 200 OK {"id":"6QW8DlMUPl97"}
- curl -u runeforge:Runeforge2026! 200 OK {"id":"3zmOI7qItrxb"}

**Cierre:**
- Docker CERO TOTAL OK
- ntfy privado gratis OK - opción gratis y privada funcionando
- Auth OK
- Listo para mañana: docker-compose completo backend 3100 + ollama 11434 + ntfy 8085

---
Sello Forneus #30 - Forjado 2026-09-29 - RUNEFORGE_V2_CORE - Cierre de hoy
