# ESTATUS RUNEFORGE v2.4.0 LFS OK - 2026-08-05 02:14:11

## Resumen
- Repo: https://github.com/yhb86dy52f-lang/runeforge-v2-nucleo.git
- Tag: v2.4.0
- Commit: 6c40d51
- Estado: CLONABLE 100% - 1672 objetos - 50.06 MiB pack - 270 LFS

## Fixes aplicados esta noche (v2.3 -> v2.4)
1. **Clone Failed - destination exists**
   - Causa: .git anidado + 10 html duplicados en raiz
   - Fix: rmdir /s /q runeforge-v2-nucleo + mover duplicados a documentacion y propuestas

2. **Filename too long - CCTV_VISOR_BASE...**
   - Causa: Windows LongPaths deshabilitado + git core.longpaths false
   - Fix: reg add LongPathsEnabled 1 + git config --global core.longpaths true

3. **Acceso bloqueado a carpetas protegidas - cmd.exe**
   - Causa: Controlled Folder Access bloqueando cmd, git, GitHubDesktop, Ollama
   - Fix: Add-MpPreference -ControlledFolderAccessAllowedApplications

4. **Refs corruptos practica/mejora**
   - Causa: git lfs migrate --everything con working copy dirty
   - Fix: takeown + icacls + rmdir /s /q + remove *.lock + git remote prune origin

5. **Repo pesado 215MB**
   - Causa: 1971 files con PNG/PDF/MP4/CSV binarios en historial Git
   - Fix v2.4: git lfs track *.png *.jpg *.mp4 *.pdf *.zip *.csv + migrate import
   - Resultado: 50.06 MiB pack + 390.12 MiB LFS (270 files) = 510 MB checkout
   - LFS Upload: 155/155 207MB @ 7.5 MB/s done

## Verificacion
- Clone fresco: TEMP\runeforge-test --depth 1 - 1981 files - 100% OK
- PM2: runeforge-backend 84.8MB online, runeforge-relay 65.8MB online
- Puertos: 3100 / 3198 / 11434 LISTENING
- IPs: 192.168.100.12 (WiFi) / 100.111.32.10 (Tailscale)
- Endpoints: /api/network + /api/ollama/status + /api/chat 200 OK

## Stack
- Backend: Fastify v2.4 - routerOptions fix
- Frontend: PWA + QR dinamico qrcodejs - acceso.html
- LLM: Ollama qwen2.5:1.5b, gemma2:2b, deepseek-coder, nomic-embed-text
- LFS: .gitattributes con 12 patrones

## Siguiente
- v2.5: Dashboard muestra 4 modelos + RAM + 270 LFS status
- Filosofia: Local-First / Soberania Digital / Auto-reparable

Sellado por: CINER - 02:14:11
