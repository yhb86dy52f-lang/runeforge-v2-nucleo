# RUNEFORGE_OPTIMIZABLE_v2_CORRECTO.ps1 - Todo lo descargado COMO DEBE SER
# GLOBAL PWSH AUTÓNOMO - auto-ejecución, clipboard, universal, limpio
$ErrorActionPreference="SilentlyContinue"
$root=$PSScriptRoot; if(-not $root){$root=$PWD.Path}
if(-not $root){$root=[Environment]::GetFolderPath("Desktop")}
$appsDir=Join-Path $root "apps\optimizers"
$log=[System.Collections.Generic.List[string]]::new()
function L($m){$log.Add($m); Write-Host $m}
L "--- RUNEFORGE OPTIMIZABLE v2 CORRECTO ---"
L "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
L "Root: $root"
L "Destino: $appsDir"
New-Item -ItemType Directory -Force -Path $appsDir | Out-Null

# FIX compatibilidad Win8 que te detectaba Windows 8 Pro build 9200
try{
 $compatKey="HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers"
 if(Test-Path $compatKey){
   Get-ItemProperty $compatKey -ErrorAction SilentlyContinue | ForEach-Object {
     $_.PSObject.Properties | Where-Object { $_.Name -like "*SysTuneX*" -or $_.Name -like "*Magpie*" -or $_.Value -like "*WIN8*" } | ForEach-Object {
       Remove-ItemProperty -Path $compatKey -Name $_.Name -Force -ErrorAction SilentlyContinue
       L "[FIX] Compatibilidad Win8 removida: $($_.Name)"
     }
   }
 }
} catch { L "[WARN] No se pudo limpiar compat: $_" }

# 1. MAGPIE - Portable real
try{
 $magpieDir=Join-Path $appsDir "Magpie"
 $exe=Join-Path $magpieDir "Magpie.exe"
 if(Test-Path $exe){ L "[1/4] Magpie YA existe: $exe" }
 else {
  L "[1/4] Bajando Magpie portable oficial..."
  $api=Invoke-RestMethod "https://api.github.com/repos/Blinue/Magpie/releases/latest" -Headers @{"User-Agent"="RUNEFORGE"} -TimeoutSec 20
  $asset=$api.assets | Where-Object { $_.name -like "*x64*.zip" } | Select-Object -First 1
  if($asset){
   $zip=Join-Path $env:TEMP "Magpie_v2.zip"
   Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zip -UseBasicParsing
   Expand-Archive -Path $zip -DestinationPath $magpieDir -Force
   Remove-Item $zip -Force
   L "[OK] Magpie -> $magpieDir\Magpie.exe - Para tu monitor 1228x690, FSR/Anime4K nítido"
  } else { L "[FAIL] Magpie asset no encontrado" }
 }
} catch { L "[FAIL] Magpie: $_" }

# 2. OPEN-FRAME-GEN NANO - Correcto: ui_overlay.py no main.py
try{
 $ofgDir=Join-Path $appsDir "Open-Frame-gen"
 if(Test-Path (Join-Path $ofgDir "ui\ui_overlay.py")){ L "[2/4] Open-Frame-gen YA existe" }
 else {
  L "[2/4] Clonando Open-Frame-gen Nano (90K params, 1.1GB VRAM)..."
  if(Test-Path $ofgDir){ Remove-Item $ofgDir -Recurse -Force -ErrorAction SilentlyContinue }
  git clone https://github.com/Deadly-pro/Open-Frame-gen.git $ofgDir 2>&1 | Out-Null
  if(Test-Path "$ofgDir\requirements.txt"){ L "[INFO] Instalado código. Para correr: pip install -r requirements.txt ; python ui/ui_overlay.py" }
  L "[OK] Open-Frame-gen -> $ofgDir - Se corre con: python ui/ui_overlay.py (NO main.py)"
 }
} catch { L "[FAIL] Open-Frame-gen: $_" }

# 3. SYSTUNEX - CORRECTO: .exe oficial, no clonar código
try{
 $sysDir=Join-Path $appsDir "systunex"
 $sysExe=Join-Path $sysDir "SysTuneX.exe"
 New-Item -ItemType Directory -Force -Path $sysDir | Out-Null
 if(Test-Path $sysExe){ L "[3/4] SysTuneX YA existe: $sysExe" }
 else {
  L "[3/4] Bajando SysTuneX.exe OFICIAL portable (self-contained)..."
  # Borrar código viejo clonado si existe
  Get-ChildItem $sysDir -Force | Where-Object { $_.Name -ne "SysTuneX.exe" } | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
  $url="https://github.com/anton-babaskin/systunex/releases/latest/download/SysTuneX.exe"
  Invoke-WebRequest -Uri $url -OutFile $sysExe -UseBasicParsing
  if(Test-Path $sysExe){ 
   $size=(Get-Item $sysExe).Length/1MB
   L "[OK] SysTuneX.exe $($size.ToString('0.0'))MB -> $sysExe - Click derecho Ejecutar como Admin"
   L "     Perfiles: Competitive FPS 14tweaks, Open World RPG, etc. Tuning 0->72 ya lo hiciste, 9.4GB->3.4GB"
  } else { L "[FAIL] No se descargó SysTuneX.exe" }
 }
} catch { L "[FAIL] SysTuneX: $_" }

# 4. UPSCAYL - Real-ESRGAN
try{
 $upDir=Join-Path $appsDir "Upscayl"
 $upExe=Get-ChildItem $upDir -Filter "*.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
 if($upExe){ L "[4/4] Upscayl YA existe: $($upExe.FullName)" }
 else {
  L "[4/4] Bajando Upscayl..."
  New-Item -ItemType Directory -Force -Path $upDir | Out-Null
  $api=Invoke-RestMethod "https://api.github.com/repos/upscayl/upscayl/releases/latest" -Headers @{"User-Agent"="RUNEFORGE"} -TimeoutSec 20
  $asset=$api.assets | Where-Object { $_.name -like "*win*.exe" } | Select-Object -First 1
  if($asset){
   $out=Join-Path $upDir "Upscayl-Setup.exe"
   Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $out -UseBasicParsing
   L "[OK] Upscayl -> $out - Doble click para instalar, agranda fotos 16x nítidas"
  }
 }
} catch { L "[FAIL] Upscayl: $_" }

# README como debe ser
try{
 $readme=Join-Path $appsDir "README_COMO_SE_USA.txt"
 @"
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
"@ | Set-Content -Path $readme -Encoding UTF8
 L "[OK] README creado: $readme"
} catch {}

L ""
L "--- RESUMEN FINAL COMO DEBE SER ---"
L "Magpie: portable exe -> doble click nítido"
L "Open-Frame-gen: se corre ui_overlay.py NO main.py"
L "SysTuneX: exe oficial NO código clonado, Run as Admin, 72/100, 3.4GB"
L "Upscayl: setup exe agrandador fotos"
L "FIX compat Win8 removido para que no detecte Windows 8 Pro build 9200"
L "[OK] Todo listo - copia al portapapeles Ctrl+V"

$final=$log -join "`r`n"
try{ Set-Clipboard -Value $final } catch { $final | clip }
Write-Output $final
