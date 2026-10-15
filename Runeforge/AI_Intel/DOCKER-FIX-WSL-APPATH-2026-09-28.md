---
sello: Forneus
sello_numero: 30
origen: RUNEFORGE_V2_CORE
tipo: AI_Intel
up: "[[Runeforge/MOCs/MOC-AI_Intel]]"
tags: [Runegea, AI, Forneus, Docker, WSL, AppPath, fix]
fecha_forja: 2026-09-28
puertos_core: [3100, 11434, 3198, 8085]
---

> [!RUNE] Sello #30 Forneus
> Forjado desde anillo huérfano -> [[Runeforge/MOCs/MOC-AI_Intel]]

# DOCKER FIX - WSL AppPath registry missing

**Error:** initializing backend: getting WSL CLI image path: cannot find registry value "AppPath"
**Causa:** WSL distros docker-desktop corruptas + registro HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\wsl.exe sin valor AppPath
**Fix aplicado:**
1. wsl --shutdown
2. Crear registro AppPath -> C:\Windows\System32\
3. wsl --unregister docker-desktop y docker-desktop-data
4. Limpiar %AppData%\Docker\settings.json integratedWslDistros=[]
5. Backup %LocalAppData%\Docker\wsl -> .backup
6. wsl --update
7. Reiniciar Docker Desktop y esperar engine
8. Levantar runeforge-ntfy:8085 privado

**Resultado:** Docker Engine OK, ntfy privado gratis en http://localhost:8085/runeforge-estatus