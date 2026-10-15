---
sello: Forneus
sello_numero: 30
origen: RUNEFORGE_V2_CORE
tipo: AI_Intel
up: "[[Runeforge/MOCs/MOC-AI_Intel]]"
tags: [Runegea, AI, Forneus, ESTATUS-GLOBAL, Docker, CERO-TOTAL, ntfy, privado, gratis, cierre]
fecha_forja: 2026-09-29
nodos_totales: 143
nodos_esperados: 97
scripts_ps1: 55
puertos_core: [3100, 11434, 3198, 8085]
docker_engine: True
ntfy_container: 2d1a88615f7d
ntfy_up: Up 6 minutes
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
- Engine: UP en 10s - Container 2d1a88615f7d Up 6 minutes
- Dashboard: PERSONAL v4.93.0, RAM 2.89 GB, CPU 0.00%, Disk 1.60 GB used

**ntfy privado gratis - Opción gratis y privada:**
- Imagen: binwiederhier/ntfy:latest
- Container: runeforge-ntfy 2d1a88615f7d Up 12 minutes 0.0.0.0:8085->80/tcp
- Config: C:\RUNEFORGE_V2_CORE\ntfy-config\server.yml
- Modo inicial ABIERTO por tailnet: base-url http://localhost:8085, behind-proxy true, sin auth
- Modo final PRIVADO con auth: auth-file /etc/ntfy/auth.db, auth-default-access deny-all
- Usuario: runeforge / Pass: Runeforge2026!
- Acceso: rw a runeforge-* y runegea-*
- Topics: runeforge-estatus
- Tests:
  - ABIERTO: id=IaiGtxz6Z9Jp, id=6QW8DlMUPl97 OK
  - AUTH: id=G7x6qf7GvZ0r AUTH OK, id=3zmOI7qItrxb test OK
- Tailscale: 100.111.32.10:8085 + tailscale serve --bg 8085 -> https://runeforge.tail12b297.ts.net
- App: Server http://100.111.32.10:8085 con auth runeforge:Runeforge2026! -> topic runeforge-estatus

**Puertos Core:**
- 3100 backend: False
- 11434 ollama: False
- 3198 headscale: False
- 8085 ntfy privado: True - UP

**Nodos:**
- MD en Runeforge: 143
- Scripts PS1 en scripts/: 55
- Esperados: 97

**Artefactos de hoy:**
- Uninstall-Docker-Completo-Cero.ps1 - CERO TOTAL con bug DisplayName (PropertyNotFoundException fix pendiente)
- Uninstall-Docker-Completo-Cero-FIXED.ps1 - Fix PSObject.Properties.Name -contains DisplayName + Select-Object -Unique
- Fix-Ntfy-Auth-403.ps1 - Fix 403 forbidden con -ModoAbierto y modo auth
- docker-compose.yml - Solo ntfy, sin backend build que fallaba C:\src\backend not found
- docker-compose.runeforge-ntfy.yml - Stack runeforge-net

**Validación:**
- docker ps: 2125ec6781b3 binwiederhier/ntfy ntfy serve Up 12 minutes 8085:80 runeforge-ntfy
- curl -d sin auth 403 -> fix ModoAbierto 200 OK
- curl -u runeforge:Runeforge2026! 200 OK

**Cierre:**
- Docker CERO TOTAL OK
- ntfy privado gratis OK
- Auth OK
- Listo para forjar docker-compose completo backend 3100 + ollama 11434 + ntfy 8085

---
Sello Forneus #30 - Forjado 2026-09-29 - RUNEFORGE_V2_CORE