<#
.SYNOPSIS
    Runeforge Optimizador V3.1 - Network & Performance
    - Protege el ecosistema de IA (Python, Node, Tauri).
    - Diagnostica y repara problemas de red.
    - Detecta GPU correctamente (ignora pantallas virtuales).
    - Exporta telemetría para el Nexus Dashboard.
#>

#Requires -RunAsAdministrator
[CmdletBinding()]
param(
    [switch]$SkipProcessKill,
    [switch]$SkipCompact,
    [switch]$SkipTempClean,
    [switch]$SkipServices,
    [switch]$Quiet
)

$Host.UI.RawUI.WindowTitle = "Runeforge Optimizer V3.1"
$ResultsDir = "C:\RUNEFORGE_V2_CORE\reports"
$TimeStamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$ReportFile = Join-Path $ResultsDir "Reporte_${TimeStamp}.txt"
$DashboardJson = "C:\RUNEFORGE_V2_CORE\nexus-dashboard\public\system_health.json"
$OutputLines = [System.Collections.Generic.List[string]]::new()

if (-not (Test-Path $ResultsDir)) { New-Item -ItemType Directory -Path $ResultsDir -Force | Out-Null }

function Write-Step ($msg) {
    if (-not $Quiet) { Write-Host "`n[*] $msg" -ForegroundColor Cyan }
    $null = $OutputLines.Add("`n[*] $msg")
}
function Write-Success ($msg) {
    if (-not $Quiet) { Write-Host "    [+] $msg" -ForegroundColor Green }
    $null = $OutputLines.Add("    [+] $msg")
}
function Write-Warn ($msg) {
    if (-not $Quiet) { Write-Host "    [!] $msg" -ForegroundColor Yellow }
    $null = $OutputLines.Add("    [!] $msg")
}
function Write-Fail ($msg) {
    if (-not $Quiet) { Write-Host "    [X] $msg" -ForegroundColor Red }
    $null = $OutputLines.Add("    [X] $msg")
}

$Banner = @"
======================================================
   RUNEFORGE OPTIMIZER V3.1 - NETWORK & PERFORMANCE
   Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
======================================================
"@
if (-not $Quiet) { Write-Host $Banner -ForegroundColor Magenta }
$null = $OutputLines.Add($Banner)

# ==========================================
# FASE 1: ANÁLISIS DE HARDWARE
# ==========================================
Write-Step "FASE 1: Analizando Hardware..."
$OS = Get-CimInstance Win32_OperatingSystem
$CPU = Get-CimInstance Win32_Processor
# CORRECCIÓN: Ignorar pantallas virtuales y priorizar GPUs reales
$GPU = Get-CimInstance Win32_VideoController | Where-Object { $_.Name -match 'NVIDIA|AMD|Radeon' -and $_.Name -notmatch 'Virtual|Basic|Display' } | Select-Object -First 1
if (-not $GPU) { $GPU = Get-CimInstance Win32_VideoController | Where-Object { $_.Name -notmatch 'Microsoft|Virtual|Display' } | Select-Object -First 1 }

$TotalRAM = [math]::Round($OS.TotalVisibleMemorySize / 1MB, 2)
$FreeRAM = [math]::Round($OS.FreePhysicalMemory / 1MB, 2)
$UsedRAM = [math]::Round($TotalRAM - $FreeRAM, 2)
$RAMPercent = [math]::Round(($UsedRAM / $TotalRAM) * 100, 1)

$diskType = "Desconocido"
try {
    $physDisk = Get-CimInstance Win32_DiskDrive | Where-Object { $_.DeviceID -like "*PHYSICALDRIVE*" } | Select-Object -First 1
    if ($physDisk.MediaType -match "SSD|Solid State") { $diskType = "SSD" } else { $diskType = "HDD" }
} catch {}

$HardwareStats = [PSCustomObject]@{
    CPU_Name = $CPU.Name.Trim()
    CPU_Cores = $CPU.NumberOfCores
    CPU_Threads = $CPU.NumberOfLogicalProcessors
    RAM_Total_GB = $TotalRAM
    RAM_Used_GB = $UsedRAM
    RAM_Percent = $RAMPercent
    GPU_Name = if ($GPU) { $GPU.Name } else { "GPU No Detectada" }
    Disk_Type = $diskType
}

Write-Success "CPU: $($HardwareStats.CPU_Name) ($($HardwareStats.CPU_Cores)C/$($HardwareStats.CPU_Threads)T)"
Write-Success "GPU: $($HardwareStats.GPU_Name)"
Write-Success "RAM: $UsedRAM GB / $TotalRAM GB ($RAMPercent% usado)"
Write-Success "Disco: $diskType"

# ==========================================
# FASE 2: AUDITORÍA Y REPARACIÓN DE RED
# ==========================================
Write-Step "FASE 2: Auditoría de Red y Correcciones..."
$NetworkStats = [PSCustomObject]@{
    Adapter_Name = "Ninguno"
    Driver = "Desconocido"
    IPv6_Enabled = $true
    WARP_Running = $false
    Ping_Cloudflare = 0
}

$adapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.Name -match "Wi-Fi|Ethernet" } | Select-Object -First 1
if ($adapter) {
    $NetworkStats.Adapter_Name = $adapter.Name
    $driverData = Get-PnpDeviceProperty -InstanceId $adapter.PnPDeviceID -KeyName 'DEVPKEY_Device_DriverProvider' -ErrorAction SilentlyContinue
    $NetworkStats.Driver = $driverData.Data
    Write-Success "Adaptador Activo: $($adapter.Name) (Driver: $($driverData.Data))"
    
    $ipv6 = Get-NetAdapterBinding -Name $adapter.Name -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue
    $NetworkStats.IPv6_Enabled = $ipv6.Enabled
    if ($ipv6.Enabled) { Write-Warn "IPv6 está HABILITADO. Puede causar conflictos." }
    else { Write-Success "IPv6 está DESHABILITADO (Óptimo)." }

    Disable-NetAdapterPowerManagement -Name $adapter.Name -ErrorAction SilentlyContinue | Out-Null
    Write-Success "Ahorro de energía desactivado en el adaptador."
}

$warp = Get-Process -Name "Cloudflare WARP" -ErrorAction SilentlyContinue
if ($warp) {
    $NetworkStats.WARP_Running = $true
    Write-Warn "Cloudflare WARP está activo. Puede romper descargas locales (SSL)."
}

Write-Step "    Limpiando cachés de red..."
ipconfig /flushdns | Out-Null
arp -d * 2>&1 | Out-Null
nbtstat -R 2>&1 | Out-Null
Write-Success "DNS, ARP y NetBIOS limpiados."

Write-Step "    Probando latencia (Ping a Cloudflare)..."
$pingResult = Test-Connection -ComputerName "1.1.1.1" -Count 4 -ErrorAction SilentlyContinue
if ($pingResult) {
    $avgPing = ($pingResult | Measure-Object -Property ResponseTime -Average).Average
    $NetworkStats.Ping_Cloudflare = [math]::Round($avgPing, 2)
    Write-Success "Latencia promedio: $([math]::Round($avgPing, 2)) ms."
} else {
    Write-Fail "No se pudo hacer ping. Posible caída de red."
}

# ==========================================
# FASE 3: GESTIÓN DE PROCESOS (BLINDADA)
# ==========================================
if (-not $SkipProcessKill) {
    Write-Step "FASE 3: Liberando RAM (Protegiendo RUNEFORGE)..."
    $ProtectedProcesses = @(
        'System', 'Idle', 'Registry', 'Memory Compression',
        'smss', 'csrss', 'wininit', 'services', 'lsass', 'svchost',
        'explorer', 'dwm', 'taskhostw', 'winlogon', 'fontdrvhost',
        'python', 'node', 'npm', 'cmd', 'powershell', 'pwsh', 'conhost',
        'dictate-studio-v2', 'brave', 'tailscale', 'tailscaled', 'MsMpEng', 'NisSrv',
        'NVDisplay.Container', 'nvcontainer', 'nvsphelper64'
    )

    $ProcessesToKill = Get-Process | Where-Object {
        $_.Id -ne $pid -and
        $_.ProcessName -notin $ProtectedProcesses -and
        $_.WorkingSet64 / 1MB -gt 300 -and
        $_.MainWindowTitle -ne ""
    }

    $KilledCount = 0
    $FreedRAM_MB = 0
    foreach ($proc in $ProcessesToKill) {
        $ramMB = [math]::Round($proc.WorkingSet64 / 1MB, 1)
        try {
            $procName = $proc.ProcessName
            $proc | Stop-Process -Force -ErrorAction Stop
            $FreedRAM_MB += $ramMB
            $KilledCount++
            Write-Host "    [>] Terminado: $procName (Liberado: ${ramMB} MB)" -ForegroundColor Gray
        } catch { }
    }
    Write-Success "Procesos terminados: $KilledCount. RAM liberada: $([math]::Round($FreedRAM_MB, 1)) MB"
}

# ==========================================
# FASE 4: COMPACTACIÓN DE MEMORIA
# ==========================================
if (-not $SkipCompact) {
    Write-Step "FASE 4: Compactando memoria RAM..."
    Add-Type -Namespace Win32 -Name Memory -MemberDefinition @"
[DllImport("kernel32.dll", SetLastError = true)]
public static extern bool SetProcessWorkingSetSize(IntPtr proc, int min, int max);
"@
    $ProcessesToCompact = Get-Process | Where-Object {
        $_.Id -ne 0 -and $_.Id -ne 4 -and
        $_.WorkingSet64 / 1MB -gt 150 -and
        $_.ProcessName -notin @('svchost', 'services', 'lsass', 'csrss', 'wininit', 'python', 'node', 'dictate-studio-v2')
    }
    foreach ($p in $ProcessesToCompact) {
        try { [Win32.Memory]::SetProcessWorkingSetSize($p.Handle, -1, -1) | Out-Null } catch {}
    }
    Write-Success "Memoria compactada para $($ProcessesToCompact.Count) procesos."
}

# ==========================================
# FASE 5: LIMPIEZA TEMPORALES
# ==========================================
if (-not $SkipTempClean) {
    Write-Step "FASE 5: Limpieza de archivos basura..."
    $TempPaths = @("$env:TEMP", "$env:WINDIR\Temp")
    $TotalDeletedMB = 0
    foreach ($path in $TempPaths) {
        if (Test-Path $path) {
            $before = (Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
            Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-2) } | Remove-Item -Force -ErrorAction SilentlyContinue
            $after = (Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
            $TotalDeletedMB += [math]::Round(($before - $after) / 1MB, 2)
        }
    }
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    Write-Success "Archivos temporales eliminados: $TotalDeletedMB MB."
}

# ==========================================
# FASE 6: EXPORTAR A DASHBOARD Y REPORTE FINAL
# ==========================================
Write-Step "FASE 6: Generando Reporte Final y Telemetría..."
$Telemetry = [PSCustomObject]@{
    timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
    core = [PSCustomObject]@{
        cpu_percent = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
        ram_percent = $RAMPercent
    }
    network = $NetworkStats
    hardware = $HardwareStats
}

$JsonPath = "C:\RUNEFORGE_V2_CORE\nexus-dashboard\public\system_health.json"
New-Item -ItemType Directory -Force -Path (Split-Path $JsonPath) | Out-Null
$Telemetry | ConvertTo-Json -Depth 4 | Set-Content -Path $JsonPath -Encoding UTF8

$Summary = @"

======================================================
                 RESUMEN FINAL
======================================================
[!] ECOSISTEMA: Whisper, Node y Tauri fueron PROTEGIDOS.
[!] RED: Cachés limpiadas. Latencia: $($NetworkStats.Ping_Cloudflare)ms.
[!] TELEMETRÍA: Exportada a system_health.json para el Dashboard.
------------------------------------------------------
Reporte guardado en: $ReportFile
======================================================
"@

if (-not $Quiet) { Write-Host $Summary -ForegroundColor Cyan }
$null = $OutputLines.Add($Summary)

$FullReport = $OutputLines -join "`n"
$FullReport | Out-File -FilePath $ReportFile -Encoding UTF8 -Force
$FullReport | Set-Clipboard