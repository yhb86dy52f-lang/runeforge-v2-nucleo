# 🏛️ RUNEFORGE V2.6.2 — MANIFIESTO DE ARQUITECTURA

## Filosofía del Sistema
- **Local-First:** Cero dependencias de la nube para la operación táctica.
- **Privacidad Radical:** Los datos no salen del dispositivo.
- **Cero Bloat:** Uso de Vanilla JS, Canvas nativo y limpieza forense de archivos.
- **Estética Cyber-Mística:** Dark mode, acentos neón (#39FF14) y Glassmorphism.

## Reglas Canónicas Inquebrantables
1. **Copia Total (Clipboard):** Todo script (`BOOT`, `STOP`, `AUDIT`) debe capturar su salida en consola (Transcript) y copiarla automáticamente al portapapeles al finalizar.
2. **Prompt ANSI:** El perfil de PowerShell usa códigos de escape ANSI (VT100) para el prompt, NUNCA `Write-Host` (para evitar bucles de renderizado).
3. **Protección de Procesos:** El botón de apagado (STOP) debe usar `taskkill /F /T` y filtrar por `CommandLine`, sin matar procesos ajenos al ecosistema.
4. **Rutas Canónicas:** Todo script `.ps1`, `.ahk` y `.bat` vive en `C:\RUNEFORGE_V2_CORE\scripts`.

## Ecosistema Modular Actual
1. **Command Center (AHK v2):** Panel de control con estética Cyberpunk para orquestar todo.
2. **Perfil pwsh:** Prompt de 2 líneas con fecha/hora, validación de entorno y variables de Rust/Node inyectadas.
3. **Scripts Core:** 
   - `RUNEFORGE_BOOT.ps1` (Arranque de 6 servicios).
   - `STOP.ps1` (Apagón Nuclear de servicios y red).
   - `AUDIT.ps1` (Auditoría Forense de puertos y procesos).