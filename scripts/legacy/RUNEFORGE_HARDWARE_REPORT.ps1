# =====================================================================
# RUNEFORGE_HARDWARE_REPORT.ps1
# Reporte completo de hardware para configurar Lossless Scaling
# =====================================================================

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

$Buf = New-Object System.Collections.Generic.List[string]
function W($m) { $Buf.Add([string]$m) | Out-Null; Write-Host $m }

W "==================================================================="
W " RUNEFORGE · HARDWARE REPORT · $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
W "==================================================================="

# ---------- 1. CPU ----------
W "`n[1] CPU"
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
W "    Modelo:   $($cpu.Name)"
W "    Nucleos:  $($cpu.NumberOfCores) fisicos / $($cpu.NumberOfLogicalProcessors) logicos"
W "    Frecuencia base:  $($cpu.MaxClockSpeed) MHz"
W ""

# ---------- 2. RAM ----------
W "`n[2] RAM"
$ramTotal = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
$ramFree  = [math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1MB, 2)
W "    Total: $ramTotal GB"
W "    Libre: $ramFree GB"
$ramSticks = @(Get-CimInstance Win32_PhysicalMemory)
foreach ($r in $ramSticks) {
    W "    Slot: $($r.DeviceLocator)  $([math]::Round($r.Capacity/1GB,0))GB  $($r.Speed) MHz"
}
W ""

# ---------- 3. GPU ----------
W "`n[3] GPU (todas)"
$gpus = @(Get-CimInstance Win32_VideoController)
foreach ($g in $gpus) {
    $vramGB = if ($g.AdapterRAM -gt 0) { [math]::Round($g.AdapterRAM/1GB, 2) } else { 'N/A' }
    W "    Nombre:     $($g.Name)"
    W "    VRAM:       $vramGB GB (reportado por WMI, puede ser inexacto)"
    W "    Driver:     $($g.DriverVersion)"
    W "    Fecha drv:  $($g.DriverDate)"
    W "    Resolucion: $($g.CurrentHorizontalResolution)x$($g.CurrentVerticalResolution) @ $($g.CurrentRefreshRate) Hz"
    W "    Estado:     $($g.Status)"
    W ""
}

# ---------- 4. Monitores ----------
W "`n[4] Monitores"
$monitors = @(Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorBasicDisplayParams -ErrorAction SilentlyContinue)
$monitorIds = @(Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorID -ErrorAction SilentlyContinue)
for ($i = 0; $i -lt $monitorIds.Count; $i++) {
    $m = $monitorIds[$i]
    $name = -join ($m.UserFriendlyName | Where-Object { $_ -gt 0 } | ForEach-Object { [char]$_ })
    W "    Monitor $($i+1): $name"
}
W ""

# ---------- 5. Resoluciones activas via .NET ----------
W "`n[5] Resoluciones activas (todas las pantallas)"
Add-Type -AssemblyName System.Windows.Forms
$screens = [System.Windows.Forms.Screen]::AllScreens
foreach ($s in $screens) {
    W "    $($s.DeviceName):"
    W "      Primary:    $($s.Primary)"
    W "      Bounds:     $($s.Bounds.Width)x$($s.Bounds.Height)"
    W "      WorkingArea: $($s.WorkingArea.Width)x$($s.WorkingArea.Height)"
}
W ""

# ---------- 6. Windows ----------
W "`n[6] Windows"
$os = Get-CimInstance Win32_OperatingSystem
W "    Version:  $($os.Caption)"
W "    Build:    $($os.Version) ($($os.BuildNumber))"
W "    Arquitectura: $($os.OSArchitecture)"
W ""

# ---------- 7. Discos ----------
W "`n[7] Discos"
Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
    $free = [math]::Round($_.FreeSpace/1GB, 1)
    $size = [math]::Round($_.Size/1GB, 1)
    W "    $($_.DeviceID)  Libre: $free GB / Total: $size GB"
}
W ""

# ---------- 8. Steam ----------
W "`n[8] Steam"
$steamPaths = @(
    "C:\Program Files (x86)\Steam\steam.exe",
    "C:\Program Files\Steam\steam.exe",
    "D:\Steam\steam.exe",
    "D:\SteamLibrary\steam.exe"
)
foreach ($p in $steamPaths) {
    if (Test-Path $p) { W "    Encontrado: $p" }
}

# Bibliotecas Steam
$libfile = "C:\Program Files (x86)\Steam\steamapps\libraryfolders.vdf"
if (Test-Path $libfile) {
    W "    Librerias:"
    Get-Content $libfile | Select-String -Pattern '"[A-Z]:\\\\' | ForEach-Object {
        W "      $($_.Line.Trim())"
    }
}
W ""

# ---------- 9. Lossless Scaling ubicacion ----------
W "`n[9] Lossless Scaling"
$lslPaths = @(
    "C:\Program Files (x86)\Steam\steamapps\common\Lossless Scaling\LosslessScaling.exe",
    "D:\Steam\steamapps\common\Lossless Scaling\LosslessScaling.exe",
    "D:\SteamLibrary\steamapps\common\Lossless Scaling\LosslessScaling.exe"
)
$lslFound = $false
foreach ($p in $lslPaths) {
    if (Test-Path $p) {
        W "    Encontrado: $p"
        $v = (Get-Item $p).VersionInfo
        W "    Version: $($v.FileVersion)"
        $lslFound = $true
    }
}
if (-not $lslFound) { W "    No encontrado en rutas tipicas" }
W ""

# ---------- 10. Juegos instalados (Steam library) ----------
W "`n[10] Juegos Steam instalados (top 15 por tamano)"
$steamApps = @()
$libDirs = @(
    "C:\Program Files (x86)\Steam\steamapps\common",
    "D:\Steam\steamapps\common",
    "D:\SteamLibrary\steamapps\common"
)
foreach ($d in $libDirs) {
    if (Test-Path $d) {
        Get-ChildItem $d -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            $steamApps += [PSCustomObject]@{
                Name = $_.Name
                Path = $_.FullName
            }
        }
    }
}
$steamApps | Sort-Object Name | Select-Object -First 40 | ForEach-Object { W "    - $($_.Name)" }
W "    Total: $($steamApps.Count) juegos"
W ""

# ---------- 11. Refresh rate real via DXGI ----------
W "`n[11] Refresh rate del monitor"
$refresh = (Get-CimInstance Win32_VideoController | Select-Object -First 1).CurrentRefreshRate
W "    Refresco actual: $refresh Hz"
W ""

# ---------- 12. VBS / HAGS / Game Mode ----------
W "`n[12] Configuracion Windows para juegos"
# HAGS (Hardware-Accelerated GPU Scheduling)
$hags = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -ErrorAction SilentlyContinue
if ($hags) {
    $hagsState = if ($hags.HwSchMode -eq 2) { "HABILITADO" } elseif ($hags.HwSchMode -eq 1) { "DESHABILITADO" } else { "Desconocido ($($hags.HwSchMode))" }
    W "    HAGS (GPU Scheduling): $hagsState"
} else {
    W "    HAGS: no configurado"
}

# Game Mode
$gm = Get-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowAutoGameMode" -ErrorAction SilentlyContinue
if ($gm) {
    $gmState = if ($gm.AllowAutoGameMode -eq 1) { "HABILITADO" } else { "DESHABILITADO" }
    W "    Game Mode: $gmState"
} else {
    W "    Game Mode: no configurado"
}

# Game DVR / Capturas en segundo plano
$dvr = Get-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -ErrorAction SilentlyContinue
if ($dvr) {
    $dvrState = if ($dvr.GameDVR_Enabled -eq 1) { "HABILITADO (consumir recursos)" } else { "DESHABILITADO (recomendado)" }
    W "    Game DVR: $dvrState"
}

W ""
W "==================================================================="
W " FIN"
W "==================================================================="

Set-Clipboard -Value ($Buf -join "`r`n")
Write-Host "`n[OK] Salida copiada al portapapeles."