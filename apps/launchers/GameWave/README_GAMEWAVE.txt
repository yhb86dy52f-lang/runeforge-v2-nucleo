GAMEWAVE PORTS LAUNCHER - COMO SE USA (reel Dd4WF3dRKjy)

Lo que viste en el reel:
- Catálogo unificado de ports: Fable II, Banjo-Kazooie Recompiled, Sonic, Mario 64, Zelda, Gears, Dante's Inferno, Forza Horizon
- Filtros: Windows / Linux / Android / Fuera de GitHub / Favoritos
- Se conecta a gamewave.digital/ports - biblioteca y launcher se actualizan juntos
- Busca actualizaciones solo al ejecutar (no en segundo plano)
- Simplifica instalación de Fable II: antes necesitabas ISO original + manual, ahora automático pidiendo tu copia legal

COMO CORRER:
1. Doble click en: C:\RUNEFORGE_V2_CORE\apps\launchers\GameWave\GithubLauncher.exe
   Requiere .NET 9 Runtime: https://dotnet.microsoft.com/en-us/download/dotnet/9.0

2. Para usar catálogo GameWave:
   - Abre https://gamewave.digital/ports
   - Copia el apps.json de GameWave o usa el que trae por defecto y añade tus repos favoritos
   - Ejemplo apps.json:
     {
       "apps": [
         { "name": "Fable II Recomp", "repository": "FableIIRecomp/FableIIRecomp", "folderName": "FableII", "appIconUrl": null }
       ]
     }

3. Cada port que necesita archivos originales (Fable II, etc) te dirá "Required files" y tú pones tu copia legal. El launcher NUNCA trae ROMs/ISOs.

Tu RUNEFORGE ahora tiene:
- apps/optimizers/Magpie/Magpie.exe (nítido 1228x690)
- apps/optimizers/Open-Frame-gen (Nano 90K, 1.1GB VRAM) - ya parcheado para 1228x690
- apps/optimizers/systunex/SysTuneX.exe (72/100, 3.4GB freed)
- apps/optimizers/Upscayl
- apps/launchers/GameWave/GithubLauncher.exe (base del reel)
- apps/launchers/Ports-Launcher (alternativo Rust)

Todo portable, borras carpeta y desaparece.
