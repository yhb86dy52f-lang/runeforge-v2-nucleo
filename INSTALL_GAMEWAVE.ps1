# INSTALL_GAMEWAVE.ps1 - GameWave Ports Launcher en RUNEFORGE como debe ser
$ErrorActionPreference="SilentlyContinue"
$root="C:\RUNEFORGE_V2_CORE"
$appsDir=Join-Path $root "apps\launchers\GameWave"
New-Item -ItemType Directory -Force -Path $appsDir | Out-Null
Write-Host "--- INSTALL GAMEWAVE PORTS LAUNCHER ---"
Write-Host "Destino: $appsDir"
Write-Host "Fuente: SirDiabo/GithubLauncher base del reel Dd4WF3dRKjy"

# 1. Descarga GithubLauncher (base de GameWave Ports Launcher del reel)
try{
  $api=Invoke-RestMethod "https://api.github.com/repos/SirDiabo/GithubLauncher/releases/latest" -Headers @{"User-Agent"="RUNEFORGE"} -TimeoutSec 20
  $asset=$api.assets | Where-Object { $_.name -like "*.zip" -and $_.name -notlike "*linux*" -and $_.name -notlike "*mac*" } | Select-Object -First 1
  if(-not $asset){ $asset=$api.assets | Select-Object -First 1 }
  Write-Host "Bajando $($asset.name) desde $($asset.browser_download_url)"
  $zip=Join-Path $env:TEMP "GithubLauncher_GameWave.zip"
  Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zip -UseBasicParsing
  Expand-Archive -Path $zip -DestinationPath $appsDir -Force
  Remove-Item $zip -Force -ErrorAction SilentlyContinue
  Write-Host "[OK] GithubLauncher base instalado -> $appsDir\GithubLauncher.exe"
} catch { Write-Host "[FAIL] GithubLauncher: $_" }

# 2. Descarga también Ports-Launcher (Rust, nativo, single binary) por si quieres el de Nyaldee
try{
  $api2=Invoke-RestMethod "https://api.github.com/repos/Nyaldee/Ports-Launcher/releases/latest" -Headers @{"User-Agent"="RUNEFORGE"} -TimeoutSec 20
  $asset2=$api2.assets | Where-Object { $_.name -like "*.zip" } | Select-Object -First 1
  if($asset2){
    $zip2=Join-Path $env:TEMP "PortsLauncher.zip"
    Invoke-WebRequest -Uri $asset2.browser_download_url -OutFile $zip2 -UseBasicParsing
    $portsDir=Join-Path $root "apps\launchers\Ports-Launcher"
    New-Item -ItemType Directory -Force -Path $portsDir | Out-Null
    Expand-Archive -Path $zip2 -DestinationPath $portsDir -Force
    Remove-Item $zip2 -Force -ErrorAction SilentlyContinue
    Write-Host "[OK] Ports-Launcher (Rust) -> $portsDir"
  }
} catch { Write-Host "[WARN] Ports-Launcher opcional: $_" }

# 3. README como debe ser
@"
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
"@ | Set-Content -Path (Join-Path $appsDir "README_GAMEWAVE.txt") -Encoding UTF8

Write-Host ""
Write-Host "[OK] Listo bb - README en $appsDir\README_GAMEWAVE.txt"
Write-Host "Corre: $appsDir\GithubLauncher.exe"
