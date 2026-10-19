RUNEFORGE OPTIMIZABLE - COMO SE USAN LOS PROGRAMAS (COMO DEBE SER)

1. Magpie\Magpie.exe
   Doble click. Selecciona ventana del juego, FSR o Anime4K, ALT+TAB. Se ve más nítido en tu 1228x690. No da FPS extra, da nitidez. Portable.

2. Open-Frame-gen\ -> python ui/ui_overlay.py
   NO main.py. Es:
   cd C:\RUNEFORGE_V2_CORE\apps\optimizers\Open-Frame-gen
   pip install -r requirements.txt
   python ui/ui_overlay.py
   Te pone YouTube 30fps -> 60/120fps suave, 1.1GB VRAM en tu 1660 SUPER.

3. systunex\SysTuneX.exe
   Click derecho -> Ejecutar como administrador. Es portable single-file, no necesita .NET.
   Dashboard: Tuning score 0->72, Memory 9.4GB->3.4GB ya lo hiciste.
   Profiles -> Competitive FPS -> Apply profile (14 tweaks 7 services, 79% applied) = mínimo input lag para CS2/Valorant.
   Game mode switch = apaga servicios y libera RAM, reversible sin reiniciar.
   Monitor -> Frame counter sin inyectar al juego (no banea anti-cheat), Ctrl+Shift+M ventanita.

4. Upscayl\Upscayl-Setup.exe
   Installer. Para fotos chicas -> grandes 16x nítidas con Real-ESRGAN Vulkan.

Todo en apps\optimizers\ - borras carpeta y desaparece excepto Upscayl que sí instala.
Backend: pm2 start ecosystem.config.js --only runeforge-backend
Ollama: qwen2.5:1.5b 986MB ya ONLINE
