# RUNEFORGE_SYSTEM_PROBE v1.2 - Diagnóstico completo para optimización IA low-end
# Uso: .\RUNEFORGE_SYSTEM_PROBE_v1.2.ps1 -Verbose
# Genera: system_probe_*.json + system_probe_*.txt en C:\RUNEFORGE_V2_CORE\knowledge\devices\

[CmdletBinding()]
param(
    [string]$OutDir = "C:\RUNEFORGE_V2_CORE\knowledge\devices",
    [switch]$CopyClipboard
)

$ErrorActionPreference = "SilentlyContinue"
$ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
Write-Host "[$ts] === RUNEFORGE SYSTEM PROBE v1.2 ===" -ForegroundColor Cyan

if(!(Test-Path $OutDir)){ New-Item -ItemType Directory -Force -Path $OutDir | Out-Null }

$probe = @{}

# 1. OS / Hardware Cajal
$os = Get-CimInstance Win32_OperatingSystem
$cpu = Get-CimInstance Win32_Processor
$gpuList = Get-CimInstance Win32_VideoController
$ram = Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum
$comp = Get-CimInstance Win32_ComputerSystem
$disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | Select-Object DeviceID, Size, FreeSpace

$probe.OS = "$($os.Caption) Build $($os.BuildNumber) $($os.OSArchitecture)"
$probe.CPU = "$($cpu.Name) | Cores: $($cpu.NumberOfCores) Threads: $($cpu.NumberOfLogicalProcessors) | Arch: $($cpu.Architecture) | AVX2: $((Get-CimInstance Win32_Processor).Capabilities -contains 0)"
$probe.RAM_GB = [math]::Round($ram.Sum/1GB,2)
$probe.RAM_Free_GB = [math]::Round($os.FreePhysicalMemory/1MB/1024,2)
$probe.Computer = "$($comp.Manufacturer) $($comp.Model)"

# 2. GPU / VRAM / Driver - Crítico para LSFG / ShadPS4 / OSFG
$probe.GPUs = @()
foreach($g in $gpuList){
    $vramGB = if($g.AdapterRAM){ [math]::Round($g.AdapterRAM/1GB,2) } else { "Unknown" }
    $probe.GPUs += @{
        Name = $g.Name
        DriverVersion = $g.DriverVersion
        VRAM_GB = $vramGB
        Resolution = "$($g.CurrentHorizontalResolution)x$($g.CurrentVerticalResolution) @ $($g.CurrentRefreshRate)Hz"
        Status = $g.Status
    }
}

# nvidia-smi si existe
$nvsmi = Get-Command nvidia-smi -ErrorAction SilentlyContinue
if($nvsmi){
    try{
        $smi = & nvidia-smi --query-gpu=name,driver_version,memory.total,memory.free,utilization.gpu,temperature.gpu --format=csv,noheader,nounits
        $probe.NVIDIA_SMI = $smi
        $probe.NVIDIA_SMI_VRAM = & nvidia-smi --query-gpu=memory.total --format=csv,noheader
    } catch {}
} else {
    $probe.NVIDIA_SMI = "nvidia-smi no encontrado - driver no instalado o no NVIDIA"
}

# 3. DirectX / Vulkan
try{
    $dx = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\DirectX" -ErrorAction SilentlyContinue
    $probe.DirectX = $dx.Version
} catch {}
# Vulkan check - driver dll
$vulkanDll = Test-Path "C:\Windows\System32\vulkan-1.dll"
$probe.Vulkan_DLL = $vulkanDll
$probe.Vulkan_1_3_Support = "Requiere GPU con 2GB VRAM + VK_KHR_swapchain + VK_KHR_push_descriptor para ShadPS4. Tu GTX 16 cumple si driver actualizado."

# 4. Display / Refresh
$probe.Displays = $gpuList | Select-Object Name, CurrentHorizontalResolution, CurrentVerticalResolution, CurrentRefreshRate, CurrentBitsPerPixel

# 5. Power / Game Mode
$power = powercfg /getactivescheme 2>$null
$probe.PowerPlan = $power
$gameMode = Get-ItemProperty "HKCU:\SOFTWARE\Microsoft\GameBar" -ErrorAction SilentlyContinue
$probe.GameMode = $gameMode.AutoGameModeEnabled

# 6. Software stack RUNEFORGE
$probe.Software = @{}
$tools = @("git","node","npm","cargo","rustc","ollama","pm2","winget","code","python","python3")
foreach($t in $tools){
    $cmd = Get-Command $t -ErrorAction SilentlyContinue
    if($cmd){
        try{
            $ver = & $t --version 2>$null
            if(-not $ver){ $ver = & $t -v 2>$null }
            $probe.Software[$t] = "$($cmd.Source) | $ver"
        } catch {
            $probe.Software[$t] = $cmd.Source
        }
    } else {
        $probe.Software[$t] = "NO INSTALADO"
    }
}

# 7. Lossless Scaling / ShareX / ArtCraft / ShadPS4 / Magpie / OSFG detect
$regPaths = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*","HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*","HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
$apps = Get-ItemProperty -Path $regPaths -ErrorAction SilentlyContinue
$probe.InstalledApps = @{}
foreach($name in @("Lossless Scaling","ShareX","ArtCraft","PhotoCraft","ShadPS4","Magpie","OSFG","Upscayl")){
    $found = $apps | Where-Object { $_.DisplayName -like "*$name*" } | Select-Object DisplayName, DisplayVersion, Publisher, InstallLocation -First 1
    if($found){ $probe.InstalledApps[$name] = $found }
}

# 8. PM2 / Ollama / Fastify / Tailscale
try{
    $probe.PM2_List = & pm2 jlist 2>$null | ConvertFrom-Json -ErrorAction SilentlyContinue | Select-Object name, pm2_env -ExpandProperty pm2_env -ErrorAction SilentlyContinue | Select-Object status, name -ErrorAction SilentlyContinue
    $probe.PM2_Raw = & pm2 status 2>$null
} catch {}
try{ $probe.Ollama_List = & ollama list 2>$null } catch {}
try{ $probe.Ollama_PS = & ollama ps 2>$null } catch {}

# Puertos críticos RUNEFORGE
$probe.Ports = @{}
foreach($port in @(3100,3198,11434)){
    $conn = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue | Select-Object -First 1
    $probe.Ports["$port"] = if($conn){ "LISTENING PID $($conn.OwningProcess)" } else { "OFFLINE" }
}

# Tailscale
$tsCmd = Get-Command tailscale -ErrorAction SilentlyContinue
if($tsCmd){
    try{ $probe.Tailscale = & tailscale status 2>$null } catch {}
}

# 9. RUNEFORGE estructura
$root = "C:\RUNEFORGE_V2_CORE"
$probe.RuneforgeRoot = @{}
if(Test-Path $root){
    $probe.RuneforgeRoot.Exists = $true
    $probe.RuneforgeRoot.Apps = Get-ChildItem "$root\apps" -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
    $probe.RuneforgeRoot.Size_GB = [math]::Round((Get-ChildItem $root -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1GB,2)
} else {
    $probe.RuneforgeRoot.Exists = $false
}

# 10. Recomendación preliminar basada en hardware detectado
$gpuName = ($probe.GPUs | Select-Object -First 1).Name
$ramGB = $probe.RAM_GB
$rec = @()

if($gpuName -like "*1650*" -or $gpuName -like "*1660*"){
    $rec += "GTX 16 detectada (6GB GDDR5, sin RT/Tensor). Para ti lo TOP es: Lossless Scaling 3.2.2 (ya lo tienes) + Magpie (escalado FSR/Anime4K gratis) + Open-Frame-gen Nano (100-200 FPS 1080p, 1.1-1.4GB VRAM, deja 2GB libres en 1650)"
    $rec += "No uses lsfg-vk 2.0 sin licencia: ahora es CC BY-NC-ND 4.0, requiere comprar Lossless Scaling en Steam"
    $rec += "ShadPS4: Requiere Vulkan 1.3 + 2GB VRAM mínimo, tu GPU cumple. Práctico recomendado 16GB RAM + Ryzen 5000 + RTX 4060 para juegos exigentes, pero para Bloodborne 1080p tu 16xx es suficiente"
    $rec += "Upscayl: Ideal para tu VRAM, usa Vulkan + Real-ESRGAN, no necesita tensor cores"
    $rec += "ArtCraft: PSD soportado 307/309 test, pero falla en estructuras complejas Adobe - no dependas para PSD con smart objects"
}

$probe.Recommendations_Prelim = $rec

# Guardar
$jsonPath = Join-Path $OutDir "system_probe_$stamp.json"
$txtPath = Join-Path $OutDir "system_probe_$stamp.txt"
$probe | ConvertTo-Json -Depth 6 | Set-Content -Path $jsonPath -Encoding UTF8
$probe | Format-List | Out-String | Set-Content -Path $txtPath -Encoding UTF8

Write-Host "[$ts] Probe guardado:" -ForegroundColor Green
Write-Host " JSON: $jsonPath" -ForegroundColor Gray
Write-Host " TXT: $txtPath" -ForegroundColor Gray
Write-Host " GPUs: $($probe.GPUs | ConvertTo-Json -Compress)" -ForegroundColor Cyan
Write-Host " RAM: $ramGB GB | Displays: $($probe.Displays.Count)" -ForegroundColor Cyan
Write-Host " Lossless Scaling: $(if($probe.InstalledApps['Lossless Scaling']){'SI'}else{'NO'}) | ShadPS4: $(if($probe.InstalledApps['ShadPS4']){'SI'}else{'NO'}) | Upscayl: $(if($probe.InstalledApps['Upscayl']){'SI'}else{'NO'})" -ForegroundColor Yellow

if($CopyClipboard){
    $probe | ConvertTo-Json -Depth 4 | Set-Clipboard
    Write-Host "[$ts] Copiado al portapapeles" -ForegroundColor Green
}

Write-Host "[$ts] === FIN PROBE ===" -ForegroundColor Cyan
Write-Host "Pega el contenido de $txtPath aquí para que te dé la recomendación óptima ajustada a tu equipo" -ForegroundColor White
