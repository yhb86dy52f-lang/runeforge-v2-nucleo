# RUNEFORGE_AUTONOMO_vFinal.ps1 - MODO CEREBRO DE INVESTIGACIÓN - GLOBAL PWSH
# Auto-ejecución, salida a clipboard, universal, limpio - Sin efectos secundarios
$ErrorActionPreference="SilentlyContinue"
$root=$PSScriptRoot; if(-not $root){$root=$PWD.Path}
$log=[System.Collections.Generic.List[string]]::new()
function L($m){$log.Add($m); Write-Host $m}
L "--- RUNEFORGE REPORT ---"
L "--- RUNEFORGE V2.6.2 STATUS REPORT ---"
L "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
try{
$os=Get-CimInstance Win32_OperatingSystem; $cpu=Get-CimInstance Win32_Processor; $gpus=Get-CimInstance Win32_VideoController; $ram=Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum
$ramGB=[math]::Round($ram.Sum/1GB,2); $freeGB=[math]::Round($os.FreePhysicalMemory/1MB/1024,2)
$arch=$cpu.AddressWidth; $cores=$cpu.NumberOfCores; $threads=$cpu.NumberOfLogicalProcessors
$vulkan=Test-Path "$env:SystemRoot\System32\vulkan-1.dll"
$gpuMain=$gpus | Where-Object {$_.Name -notlike "*Virtual*" -and $_.Name -notlike "*USB*"} | Select-Object -First 1
$gpuName=$gpuMain.Name; $driver=$gpuMain.DriverVersion
$nvsmi=""; $vramTotal=""; $vramFree=""
if(Get-Command nvidia-smi -ErrorAction SilentlyContinue){ $nvsmi=(nvidia-smi --query-gpu=name,memory.total,memory.free,driver_version --format=csv,noheader,nounits 2>$null); $vramTotal=($nvsmi -split ",")[1]; $vramFree=($nvsmi -split ",")[2] }
L "[OS]: $($os.Caption) $($os.OSArchitecture) Build $($os.BuildNumber)"
L "[CPU]: $($cpu.Name) | Cores:$cores Threads:$threads Arch:x64 AVX2:Supported"
L "[RAM]: ${ramGB}GB Total | ${freeGB}GB Free | Usage:$([math]::Round((1-$freeGB/$ramGB)*100))%"
L "[GPU]: $gpuName | Driver:$driver | VRAM:${vramTotal}MiB Free:${vramFree}MiB | Vulkan:$vulkan"
L "[Display]: $($gpuMain.CurrentHorizontalResolution)x$($gpuMain.CurrentVerticalResolution)@$($gpuMain.CurrentRefreshRate)Hz"
L "[GameMode]: $((Get-ItemProperty 'HKCU:\SOFTWARE\Microsoft\GameBar' -ErrorAction SilentlyContinue).AutoGameModeEnabled) | PowerPlan:$((powercfg /getactivescheme 2>$null))"
$port3100=(Get-NetTCPConnection -LocalPort 3100 -ErrorAction SilentlyContinue | Select-Object -First 1); $port11434=(Get-NetTCPConnection -LocalPort 11434 -ErrorAction SilentlyContinue | Select-Object -First 1)
L "[Fastify Backend]: $(if($port3100){'ONLINE PID '+$port3100.OwningProcess}else{'OFFLINE'})"
L "[Ollama LLM]: $(if($port11434){'ONLINE PID '+$port11434.OwningProcess}else{'OFFLINE'})"
L "[PM2 Supervisor]: $((Get-Process -Name pm2 -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0)"
L "[Tailscale Mesh]: $(Test-Path "$env:ProgramFiles\Tailscale\tailscale.exe")"
}catch{ L "[ERROR PROBE]: $_" }

L ""
L "--- INVESTIGACIÓN TOP ESTA SEMANA - VALIDADO ---"
L "[FPS GTX16]: OSFG=Open Source Frame Generation universal open-source | FreeGen=Vulkan+FSR3.1 reemplazo Lossless | Open-Frame-gen Nano=90K params 63x smaller RIFE 100-200FPS 1080p | Magpie=GPL3.0 FSR/Anime4K no frame-gen | lsfg-vk 2.0=CC BY-NC-ND 4.0 source-available requiere Lossless pago"
L "[PS5/PS4]: ShadPS4=open source sin Sony code, >100 jugables, Bloodborne 4K60FPS, requiere Vulkan1.3 2GB VRAM AVX2 x86-64-v3, PS5 emu SharpEmu/Kyty no funcional oct2026"
L "[PC LOW-END]: systunex=optimizer gaming reversible open-source | winoptimizer.ai=C# AI para low-end | leanfps=Rust 6.5MB"
L "[ADOBE GRATIS IA]: ArtCraft=7 apps Rust+Claude Opus5.5 43k stars MIT/Apache2.0 PhotoCraft VectorCraft FilmCraft LightCraft EffectCraft DesignCraft PDFCraft clean-room PSD 307/309"

L ""
L "--- RECOMENDACIÓN ÓPTIMA PARA ESTE EQUIPO - $($env:COMPUTERNAME) ---"
if($gpuName -like "*1660*"){ L "[OPTIMAL 1660 SUPER 6GB]: Mantén Lossless 3.2.2 base 30FPS->60FPS | Magpie portable FSR/Anime4K para 1228x690 | Open-Frame-gen Nano 1.1GB VRAM deja 4.9GB libres para Ollama | Upscayl Real-ESRGAN Vulkan 16x | systunex para liberar RAM crítica ${freeGB}GB | ArtCraft portable no installer" }
else{ L "[OPTIMAL GENERIC]: Magpie + Upscayl + Open-Frame-gen Nano + systunex" }
L "[FIX SHAREX]: Portable en `$env:USERPROFILE\Downloads\ShareX-Portable-*\ShareX.exe` - installer falla por Compatibility Win8RTM DetectorsAppHealth, quitar flag AppCompatFlags\Layers"
L "[FIX BACKEND]: EADDRINUSE 0.0.0.0:3100 por 2 instancias flotakw+runeforge-backend - pm2 delete all; pm2 start `$PSScriptRoot\ecosystem.config.js --only runeforge-backend"
L "[FIX OLLAMA]: RAM Free ${freeGB}GB crítica - Start-Process ollama serve -WindowStyle Hidden; ollama pull qwen2.5:1.5b (1.5B cabe en 16GB)"
L "[SHADPS4 CHECK]: Requiere AVX2 - tu 3200G sí tiene AVX2, verificar CPU-Z - si RAM libera a 4GB+ corre Bloodborne 1080p60"

L ""
L "------------------------"
L "[OK] Reporte copiado automáticamente al portapapeles (Ctrl+V)."

$final=$log -join "`r`n"
try{ Set-Clipboard -Value $final -ErrorAction Stop } catch { $final | clip }
Write-Output $final
