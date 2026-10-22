<#
.SYNOPSIS
    Runeforge Optimizador v2.6 - Reporte de servicios corregido + Limitador Brave agresivo
#>

# ============================================================
# PARAMETROS
# ============================================================
[CmdletBinding()]
param(
    [switch]$SkipProcessKill,
    [switch]$KillBraveUpdater,
    [switch]$LimitBrave,
    [switch]$SkipCompact,
    [switch]$SkipTempClean,
    [switch]$SkipWifi,
    [switch]$SkipServices,
    [switch]$SkipMenu,
    [switch]$Quiet
)

# ============================================================
# BLOQUE 0: AUTO-ELEVACION + PREFERIR PWSH
# ============================================================
$ErrorActionPreference = 'Continue'

function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Admin)) {
    if ($env:RUNEFORGE_ELEVATED -eq '1') {
        Write-Host "[!] No se pudo elevar a administrador. Saliendo." -ForegroundColor Red
        if ($Host.Name -eq 'ConsoleHost') { Read-Host "Enter para salir" }
        exit 1
    }
    $exe = (Get-Process -Id $PID).Path
    $argList = @('-NoProfile','-ExecutionPolicy','Bypass','-File', "`"$PSCommandPath`"")
    if ($PSBoundParameters.Count -gt 0) {
        foreach ($k in $PSBoundParameters.Keys) {
            if ($PSBoundParameters[$k] -is [switch]) {
                if ($PSBoundParameters[$k]) { $argList += "-$k" }
            } else {
                $argList += "-$k"; $argList += "`"$($PSBoundParameters[$k])`""
            }
        }
    }
    Write-Host "[..] Solicitando permisos de administrador..." -ForegroundColor Yellow
    $env:RUNEFORGE_ELEVATED = '1'
    Start-Process -FilePath $exe -ArgumentList $argList -Verb RunAs
    exit
}

if ($PSVersionTable.PSEdition -eq 'Desktop' -and $env:RUNEFORGE_UPGRADED -ne '1') {
    $pwshCmd = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($pwshCmd) {
        $argList = @('-NoProfile','-ExecutionPolicy','Bypass','-File', "`"$PSCommandPath`"")
        if ($PSBoundParameters.Count -gt 0) {
            foreach ($k in $PSBoundParameters.Keys) {
                if ($PSBoundParameters[$k] -is [switch]) {
                    if ($PSBoundParameters[$k]) { $argList += "-$k" }
                } else {
                    $argList += "-$k"; $argList += "`"$($PSBoundParameters[$k])`""
                }
            }
        }
        Write-Host "[..] Relanzando con pwsh (PowerShell 7+)..." -ForegroundColor Cyan
        $env:RUNEFORGE_UPGRADED = '1'
        $env:RUNEFORGE_ELEVATED = '1'
        & $pwshCmd.Source @argList
        exit $LASTEXITCODE
    }
}

# ============================================================
# MENU INTERACTIVO
# ============================================================
$hasExplicitParams = $PSBoundParameters.Count -gt 0
if (-not $SkipMenu -and -not $Quiet -and -not $hasExplicitParams) {
    Write-Host ""
    Write-Host "+===============================================+" -ForegroundColor Cyan
    Write-Host "|   RUNEFORGE OPTIMIZADOR v2.6 - MENU           |" -ForegroundColor Cyan
    Write-Host "+===============================================+" -ForegroundColor Cyan
    Write-Host "|   [1] Completo (recomendado)                  |" -ForegroundColor White
    Write-Host "|   [2] Completo + matar Brave Updater          |" -ForegroundColor White
    Write-Host "|   [3] Solo Wi-Fi                              |" -ForegroundColor White
    Write-Host "|   [4] Solo temporales                         |" -ForegroundColor White
    Write-Host "|   [5] Solo Brave Updater (mini)               |" -ForegroundColor White
    Write-Host "|   [6] Solo analisis (sin cambios)             |" -ForegroundColor White
    Write-Host "|   [7] Limitar RAM de Brave (sin cerrarlo)     |" -ForegroundColor Green
    Write-Host "+===============================================+" -ForegroundColor Cyan
    Write-Host ""
    $opt = Read-Host "Selecciona [1-7, Enter=1]"
    if ([string]::IsNullOrWhiteSpace($opt)) { $opt = '1' }
    switch ($opt) {
        '2' { $KillBraveUpdater = $true }
        '3' { $SkipProcessKill=$true; $SkipCompact=$true; $SkipTempClean=$true; $SkipServices=$true }
        '4' { $SkipProcessKill=$true; $SkipCompact=$true; $SkipWifi=$true; $SkipServices=$true }
        '5' { $KillBraveUpdater=$true; $SkipProcessKill=$true; $SkipCompact=$true; $SkipTempClean=$true; $SkipWifi=$true; $SkipServices=$true }
        '6' { $SkipProcessKill=$true; $SkipCompact=$true; $SkipTempClean=$true; $SkipWifi=$true; $SkipServices=$true }
        '7' { $LimitBrave=$true; $KillBraveUpdater=$true; $SkipProcessKill=$true; $SkipCompact=$true; $SkipTempClean=$true; $SkipWifi=$true; $SkipServices=$true }
        default { }
    }
}

# ============================================================
# INICIALIZACION
# ============================================================
$Host.UI.RawUI.WindowTitle = "Runeforge Optimizador v2.6 ($($PSVersionTable.PSEdition))"
$DesktopPath = [Environment]::GetFolderPath('Desktop')
$ResultsDir  = Join-Path $DesktopPath "Runeforge_Optimizacion_Resultados"
$TimeStamp   = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$ReportFile  = Join-Path $ResultsDir "Reporte_${TimeStamp}.txt"
$OutputLines = [System.Collections.Generic.List[string]]::new()

$KilledCount=0; $FreedRAM_MB=0.0; $CompactedCount=0; $FreedByCompactMB=0.0
$TotalDeletedMB=0.0; $StoppedServices=@(); $WiFiOptimized=$false; $WiFiAdapterName="N/A"
$BraveFreedMB=0.0; $BraveSvcKilled=0
$BraveTrimmed=0; $BraveBgKilled=0; $BraveLimitFreed=0.0

if (-not (Test-Path $ResultsDir)) { New-Item -ItemType Directory -Path $ResultsDir -Force | Out-Null }
$m="[OK] Resultados: $ResultsDir"
if (-not $Quiet) { Write-Host $m -ForegroundColor Green }
$null = $OutputLines.Add($m)

$Banner = @"
╔══════════════════════════════════════════════╗
║   RUNEFORGE OPTIMIZADOR DE RENDIMIENTO v2.6  ║
║   Motor: $($PSVersionTable.PSEdition) $($PSVersionTable.PSVersion)                     ║
║   $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')   ║
╚══════════════════════════════════════════════╝
"@
if (-not $Quiet) { Write-Host $Banner -ForegroundColor Cyan }
$null = $OutputLines.Add($Banner)

function Add-ReportLine { param([string]$Line) $null = $OutputLines.Add($Line) }

if ($PSVersionTable.PSEdition -eq 'Core') {
    foreach ($mod in @('NetAdapter','NetTCPIP','CimCmdlets')) {
        if (-not (Get-Module -Name $mod)) {
            try { Import-Module -Name $mod -ErrorAction Stop -WarningAction SilentlyContinue }
            catch { try { Import-Module -Name $mod -UseWindowsPowerShell -ErrorAction Stop -WarningAction SilentlyContinue } catch { } }
        }
    }
}

Add-Type -Namespace Win32 -Name Memory -MemberDefinition @"
[DllImport("kernel32.dll", SetLastError = true)]
public static extern bool SetProcessWorkingSetSize(IntPtr proc, int min, int max);
"@

# ============================================================
# FASE 1: ANALISIS
# ============================================================
if (-not $Quiet) { Write-Host "`n[FASE 1] Analisis profundo..." -ForegroundColor Yellow }
Add-ReportLine "`n========================================"
Add-ReportLine " ANALISIS INICIAL"
Add-ReportLine "========================================"

$OS=Get-CimInstance Win32_OperatingSystem
$CPU=Get-CimInstance Win32_Processor
$GPU=Get-CimInstance Win32_VideoController | Where-Object { $_.Name -notmatch 'Microsoft Basic' } | Select-Object -First 1
$TotalRAM=[math]::Round($OS.TotalVisibleMemorySize/1MB,2)
$FreeRAM=[math]::Round($OS.FreePhysicalMemory/1MB,2)
$UsedRAM=[math]::Round($TotalRAM-$FreeRAM,2)
$RAMPercent=[math]::Round(($UsedRAM/$TotalRAM)*100,1)
$DiskC=Get-PSDrive -Name C
$DiskFreeC=[math]::Round($DiskC.Free/1GB,2)
$DiskTotalC=[math]::Round(($DiskC.Used+$DiskC.Free)/1GB,2)

$diskType="Desconocido"
try {
    $pd=Get-CimInstance Win32_DiskDrive | Where-Object { $_.DeviceID -like "*PHYSICALDRIVE*" } | Select-Object -First 1
    if ($pd.MediaType -match "SSD|Solid State") { $diskType="SSD" } else { $diskType="HDD" }
} catch {}

$info=@"
--- HARDWARE ---
CPU: $($CPU.Name.Trim()) | Núcleos: $($CPU.NumberOfCores) | Hilos: $($CPU.NumberOfLogicalProcessors)
RAM Total: ${TotalRAM} GB | Usada: ${UsedRAM} GB | Libre: ${FreeRAM} GB | Uso: ${RAMPercent}%
GPU: $($GPU.Name)
Disco C:\ Libre: ${DiskFreeC} GB / ${DiskTotalC} GB | Tipo: $diskType
"@
if (-not $Quiet) { Write-Host $info -ForegroundColor White }
Add-ReportLine $info

$TopRAM=Get-Process | Where-Object { $_.WorkingSet64 -gt 10MB } | Sort-Object WorkingSet64 -Descending | Select-Object -First 20 | ForEach-Object {
    $r=[math]::Round($_.WorkingSet64/1MB,1); $c=if($_.CPU){[math]::Round($_.CPU,1)}else{0}
    "  PID $($_.Id) | RAM: ${r} MB | CPU: ${c}s | $($_.ProcessName)"
}
$h="`n--- TOP 20 PROCESOS POR MEMORIA ---"
if (-not $Quiet) { Write-Host $h -ForegroundColor Magenta }
Add-ReportLine $h
$TopRAM | ForEach-Object { if (-not $Quiet) { Write-Host $_ -ForegroundColor Gray }; Add-ReportLine $_ }

# FIX: Reporte exacto de servicios usando Win32_Service para no mezclar procesos del navegador
$TopSvc=Get-CimInstance -ClassName Win32_Service -Filter "State='Running'" -ErrorAction SilentlyContinue | ForEach-Object {
    $p=Get-Process -Id $_.ProcessId -ErrorAction SilentlyContinue
    if ($p) { 
        [PSCustomObject]@{
            Name=$_.Name; 
            Display=$_.DisplayName; 
            WS=$p.WorkingSet64;
            PID=$p.Id
        } 
    }
} | Where-Object { $_.WS -gt 10MB } | Sort-Object WS -Descending | Select-Object -First 10

$h="`n--- TOP 10 SERVICIOS POR MEMORIA ---"
if (-not $Quiet) { Write-Host $h -ForegroundColor Magenta }
Add-ReportLine $h
$TopSvc | ForEach-Object {
    $w=[math]::Round($_.WS/1MB,1); $l="  $($_.Name) ($($_.Display)) - PID $($_.PID) - ${w} MB"
    if (-not $Quiet) { Write-Host $l -ForegroundColor Gray }
    Add-ReportLine $l
}

# ============================================================
# FASE 2: PROCESOS GENERALES
# ============================================================
if (-not $SkipProcessKill) {
    if (-not $Quiet) { Write-Host "`n[FASE 2] Terminando procesos innecesarios..." -ForegroundColor Yellow }
    Add-ReportLine "`n========================================"
    Add-ReportLine " PROCESOS TERMINADOS"
    Add-ReportLine "========================================"

    $Excl=@('System','Idle','Registry','Memory Compression','smss','csrss','wininit','services','lsass','svchost',
        'explorer','dwm','taskhostw','winlogon','fontdrvhost','spoolsv','audiodg','SearchIndexer','SecurityHealthService',
        'MsMpEng','NisSrv','mpdefendercoreservice','pm2','node','powershell','pwsh','conhost','cmd','powershell_ise',
        'RuntimeBroker','ShellExperienceHost','StartMenuExperienceHost','sihost','ctfmon','TextInputHost',
        'SearchApp','SystemSettings','ApplicationFrameHost','dllhost','WmiPrvSE','SgrmBroker','SecurityHealthSystray',
        'brave','tailscale','tailscaled')

    $ToKill=Get-Process | Where-Object {
        $_.Id -ne $PID -and $_.ProcessName -notin $Excl -and
        ($_.WorkingSet64/1MB -gt 150 -or ($_.CPU -gt 10 -and $_.CPU -lt 10000)) -and
        ($_.MainWindowTitle -ne "" -or $_.ProcessName -match "^(chrome|firefox|edge|msedge|opera|vivaldi|steam|discord|spotify|slack|teams|zoom|code|cursor|notepad|calc|vlc|mpc-hc|winrar|7z|photoshop|illustrator|docker|vmware|virtualbox|java|python|npm|git|mongo|postgres|mysql|redis)$")
    } | Sort-Object WorkingSet64 -Descending

    foreach ($proc in $ToKill) {
        $ramMB = [math]::Round($proc.WorkingSet64/1MB,1)
        $procName = $proc.ProcessName
        $procId   = $proc.Id
        try {
            $proc | Stop-Process -Force -ErrorAction Stop
            $FreedRAM_MB += $ramMB
            $KilledCount++
            $msg="  [OK] Terminado: $procName (PID $procId) - Liberado: ${ramMB} MB"
            if (-not $Quiet) { Write-Host $msg -ForegroundColor Green }
            Add-ReportLine $msg
        } catch {
            $msg="  [!] No se pudo: $procName (PID $procId) - $_"
            if (-not $Quiet) { Write-Host $msg -ForegroundColor Red }
            Add-ReportLine $msg
        }
    }
    $s="`n>> Procesos terminados: $KilledCount | RAM liberada: $([math]::Round($FreedRAM_MB,1)) MB"
    if (-not $Quiet) { Write-Host $s -ForegroundColor Cyan }
    Add-ReportLine $s
} else {
    $m=">> Terminacion de procesos generales omitida."
    if (-not $Quiet) { Write-Host $m -ForegroundColor Yellow }
    Add-ReportLine $m
}

# ============================================================
# FASE 2.5: BRAVE UPDATER
# ============================================================
if ($KillBraveUpdater) {
    if (-not $Quiet) { Write-Host "`n[FASE 2.5] Limpiando Brave Update Service..." -ForegroundColor Yellow }
    Add-ReportLine "`n========================================"
    Add-ReportLine " BRAVE UPDATE SERVICE (FIX)"
    Add-ReportLine "========================================"

    $braveSvcs = Get-Service -Name '*brave*' -ErrorAction SilentlyContinue
    foreach ($svc in $braveSvcs) {
        if ($svc.Status -eq 'Running') {
            try {
                Stop-Service -Name $svc.Name -Force -ErrorAction Stop
                Set-Service  -Name $svc.Name -StartupType Manual -ErrorAction SilentlyContinue
                $BraveSvcKilled++
                $msg="  [OK] Servicio detenido: $($svc.Name) ($($svc.DisplayName))"
                if (-not $Quiet) { Write-Host $msg -ForegroundColor Green }
                Add-ReportLine $msg
            } catch {
                $msg="  [!] No se pudo detener $($svc.Name): $_"
                if (-not $Quiet) { Write-Host $msg -ForegroundColor Yellow }
                Add-ReportLine $msg
            }
        }
    }

    $updaters = Get-CimInstance Win32_Process -Filter "Name = 'brave.exe'" -ErrorAction SilentlyContinue | 
        Where-Object { $_.CommandLine -match 'type=utility.*update|type=service|updater' }
        
    foreach ($u in $updaters) {
        try {
            $p = Get-Process -Id $u.ProcessId -ErrorAction SilentlyContinue
            if ($p) {
                $ramMB = [math]::Round($p.WorkingSet64/1MB,1)
                Stop-Process -Id $u.ProcessId -Force -ErrorAction Stop
                $BraveFreedMB += $ramMB
                $msg="  [OK] Proceso Updater terminado (PID $($u.ProcessId)) - Liberado: ${ramMB} MB"
                if (-not $Quiet) { Write-Host $msg -ForegroundColor Green }
                Add-ReportLine $msg
            }
        } catch {
            $msg="  [!] No se pudo terminar Updater PID $($u.ProcessId): $_"
            if (-not $Quiet) { Write-Host $msg -ForegroundColor Yellow }
            Add-ReportLine $msg
        }
    }

    $m=">> Brave Updater: $BraveSvcKilled svc detenidos, $([math]::Round($BraveFreedMB,1)) MB liberados."
    if (-not $Quiet) { Write-Host $m -ForegroundColor Cyan }
    Add-ReportLine $m
}

# ============================================================
# FASE 2.6: LIMITAR BRAVE (CONTROL DE RAM)
# ============================================================
if ($LimitBrave) {
    if (-not $Quiet) { Write-Host "`n[FASE 2.6] Limitando uso de RAM de Brave (sin cerrar ventanas)..." -ForegroundColor Yellow }
    Add-ReportLine "`n========================================"
    Add-ReportLine " LIMITANDO BRAVE"
    Add-ReportLine "========================================"

    $braveProcs = Get-Process -Name 'brave' -ErrorAction SilentlyContinue
    foreach ($bp in $braveProcs) {
        $ramMB = [math]::Round($bp.WorkingSet64/1MB,1)
        
        # Si consume más de 300 MB y NO tiene ventana (proceso de fondo), lo matamos
        if ($ramMB -gt 300 -and [string]::IsNullOrWhiteSpace($bp.MainWindowTitle)) {
            try {
                Stop-Process -Id $bp.Id -Force -ErrorAction Stop
                $BraveBgKilled++
                $BraveLimitFreed += $ramMB
                $msg="  [OK] Proceso de fondo de Brave terminado (PID $($bp.Id)) - ${ramMB} MB"
                if (-not $Quiet) { Write-Host $msg -ForegroundColor Green }
                Add-ReportLine $msg
            } catch {}
        } else {
            # Si es la ventana principal o usa menos, forzamos su compactación
            try {
                if ($bp.Handle -ne [IntPtr]::Zero) {
                    [Win32.Memory]::SetProcessWorkingSetSize($bp.Handle, -1, -1) | Out-Null
                    $BraveTrimmed++
                }
            } catch {}
        }
    }
    
    $m=">> Brave: $BraveTrimmed procesos compactados, $BraveBgKilled procesos en 2do plano cerrados, $([math]::Round($BraveLimitFreed,1)) MB liberados."
    if (-not $Quiet) { Write-Host $m -ForegroundColor Cyan }
    Add-ReportLine $m
}

# ============================================================
# FASE 3: COMPACTACION GENERAL
# ============================================================
if (-not $SkipCompact) {
    if (-not $Quiet) { Write-Host "`n[FASE 3] Compactando memoria general..." -ForegroundColor Yellow }
    Add-ReportLine "`n========================================"
    Add-ReportLine " COMPACTACION GENERAL"
    Add-ReportLine "========================================"
    $b=[math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1KB,2)
    $ToC=Get-Process | Where-Object {
        $_.Id -ne 0 -and $_.Id -ne 4 -and $_.WorkingSet64/1MB -gt 100 -and
        $_.ProcessName -notin @('svchost','services','lsass','csrss','wininit','System','Registry','brave','tailscale','tailscaled')
    }
    foreach ($p in $ToC) {
        try {
            if ($p.Handle -ne [IntPtr]::Zero) {
                [Win32.Memory]::SetProcessWorkingSetSize($p.Handle,-1,-1) | Out-Null
                $CompactedCount++
            }
        } catch {}
    }
    $a=[math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1KB,2)
    $FreedByCompactMB=[math]::Round($a-$b,2)
    $m=">> Compactados: $CompactedCount | RAM liberada: ${FreedByCompactMB} MB | Libre: $([math]::Round($a/1024,2)) GB"
    if (-not $Quiet) { Write-Host $m -ForegroundColor Cyan }
    Add-ReportLine $m
} else {
    $m=">> Compactacion omitida."
    if (-not $Quiet) { Write-Host $m -ForegroundColor Yellow }
    Add-ReportLine $m
}

# ============================================================
# FASE 4: TEMPORALES
# ============================================================
if (-not $SkipTempClean) {
    if (-not $Quiet) { Write-Host "`n[FASE 4] Limpiando temporales..." -ForegroundColor Yellow }
    Add-ReportLine "`n========================================"
    Add-ReportLine " LIMPIEZA DE TEMPORALES"
    Add-ReportLine "========================================"
    $paths=@("$env:TEMP","$env:WINDIR\Temp","$env:LOCALAPPDATA\Temp","$env:LOCALAPPDATA\Microsoft\Windows\INetCache","$env:LOCALAPPDATA\Microsoft\Windows\INetCookies")
    foreach ($tp in $paths) {
        if (Test-Path $tp) {
            try {
                $bs=(Get-ChildItem -Path $tp -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                Get-ChildItem -Path $tp -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-3) } | Remove-Item -Force -ErrorAction SilentlyContinue
                $as=(Get-ChildItem -Path $tp -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                $f=[math]::Round(($bs-$as)/1MB,2)
                $TotalDeletedMB+=$f
                $m="  [OK] $tp -> Liberado: ${f} MB"
                if (-not $Quiet) { Write-Host $m -ForegroundColor Green }
                Add-ReportLine $m
            } catch {
                $m="  [!] Error $tp : $_"
                if (-not $Quiet) { Write-Host $m -ForegroundColor Red }
                Add-ReportLine $m
            }
        }
    }
    try { Clear-RecycleBin -Force -ErrorAction Stop; $m="  [OK] Papelera vaciada" } catch { $m="  [!] Papelera: $_" }
    if (-not $Quiet) { Write-Host $m -ForegroundColor Green }
    Add-ReportLine $m
    try { Clear-DnsClientCache -ErrorAction Stop; $m="  [OK] Cache DNS limpiada" } catch { $m="  [!] DNS: $_" }
    if (-not $Quiet) { Write-Host $m -ForegroundColor Green }
    Add-ReportLine $m
    if ($diskType -eq "HDD") {
        try {
            $pf="$env:WINDIR\Prefetch"
            if (Test-Path $pf) {
                $b2=(Get-ChildItem $pf -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                Get-ChildItem $pf -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
                $a2=(Get-ChildItem $pf -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                $f=[math]::Round(($b2-$a2)/1MB,2); $TotalDeletedMB+=$f
                $m="  [OK] Prefetch (HDD) -> ${f} MB"
                if (-not $Quiet) { Write-Host $m -ForegroundColor Green }
                Add-ReportLine $m
            }
        } catch {}
    }
    try {
        $wu="$env:WINDIR\SoftwareDistribution\Download"
        if (Test-Path $wu) {
            $b2=(Get-ChildItem $wu -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
            Get-ChildItem $wu -Recurse -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
            $a2=(Get-ChildItem $wu -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
            $f=[math]::Round(($b2-$a2)/1MB,2); $TotalDeletedMB+=$f
            $m="  [OK] Cache Windows Update -> ${f} MB"
            if (-not $Quiet) { Write-Host $m -ForegroundColor Green }
            Add-ReportLine $m
        }
    } catch {}
    $m=">> Total temporales: $([math]::Round($TotalDeletedMB,2)) MB"
    if (-not $Quiet) { Write-Host $m -ForegroundColor Cyan }
    Add-ReportLine $m
} else {
    $m=">> Temporales omitidos."
    if (-not $Quiet) { Write-Host $m -ForegroundColor Yellow }
    Add-ReportLine $m
}

# ============================================================
# FASE 5: WIFI
# ============================================================
if (-not $SkipWifi) {
    if (-not $Quiet) { Write-Host "`n[FASE 5] Optimizando Wi-Fi..." -ForegroundColor Yellow }
    Add-ReportLine "`n========================================"
    Add-ReportLine " OPTIMIZACION DE RED WI-FI"
    Add-ReportLine "========================================"
    $wifi=Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'Wi-?Fi|WLAN|Inalámbric' } | Select-Object -First 1
    if ($wifi -and $wifi.Status -eq 'Up') {
        $WiFiOptimized=$true; $WiFiAdapterName=$wifi.Name
        $m="  [OK] Adaptador: $($wifi.Name) ($($wifi.InterfaceDescription))"
        if (-not $Quiet) { Write-Host $m -ForegroundColor Green }
        Add-ReportLine $m
        $ap=@()
        foreach ($pair in @(@{N="Throughput Booster";V="Enabled"},@{N="Roaming Aggressiveness";V="Lowest"},@{N="Preferred Band";V="Prefer 5GHz band"})) {
            try { Set-NetAdapterAdvancedProperty -Name $wifi.Name -DisplayName $pair.N -DisplayValue $pair.V -ErrorAction Stop; $ap+=$pair.N } catch {}
        }
        if ($ap.Count -gt 0) { $m="  [OK] Ajustes: $($ap -join ', ')"; $c="Green" } else { $m="  [!] Driver sin propiedades avanzadas estandar."; $c="Yellow" }
        if (-not $Quiet) { Write-Host $m -ForegroundColor $c }
        Add-ReportLine $m
        try {
            Set-NetAdapterPowerManagement -Name $wifi.Name -WakeOnMagicPacket Disabled -WakeOnPattern Disabled -ErrorAction SilentlyContinue
            powercfg /setacvalueindex SCHEME_CURRENT 19cbb8fa-5279-450e-9fac-8a3d5fedd0c1 12bbebe6-58d6-4636-95bb-3217ef867c1a 0 2>$null | Out-Null
            powercfg /setdcvalueindex SCHEME_CURRENT 19cbb8fa-5279-450e-9fac-8a3d5fedd0c1 12bbebe6-58d6-4636-95bb-3217ef867c1a 0 2>$null | Out-Null
            powercfg /setactive SCHEME_CURRENT 2>$null | Out-Null
            $m="  [OK] Ahorro de energia del adaptador desactivado."
            if (-not $Quiet) { Write-Host $m -ForegroundColor Green }
            Add-ReportLine $m
        } catch {
            $m="  [!] Energia: $_"
            if (-not $Quiet) { Write-Host $m -ForegroundColor Yellow }
            Add-ReportLine $m
        }
        try {
            netsh int tcp set global autotuninglevel=normal 2>$null | Out-Null
            Set-NetAdapterRss -Name $wifi.Name -Enabled $true -ErrorAction SilentlyContinue
            $m="  [OK] TCP/IP optimizado (autotuning=normal, RSS intentado)."
            if (-not $Quiet) { Write-Host $m -ForegroundColor Green }
            Add-ReportLine $m
        } catch {
            $m="  [!] TCP: $_"
            if (-not $Quiet) { Write-Host $m -ForegroundColor Yellow }
            Add-ReportLine $m
        }
        try {
            $ii=netsh wlan show interfaces 2>$null
            $sl=$ii | Select-String -Pattern "^\s*SSID\s*:" | Select-Object -First 1
            if ($sl) {
                $pr=($sl -replace '.*:\s*','').Trim()
                if ($pr) {
                    netsh wlan set profileorder name="$pr" interface="$($wifi.Name)" priority=1 2>$null | Out-Null
                    $m="  [OK] Perfil priorizado: $pr"
                    if (-not $Quiet) { Write-Host $m -ForegroundColor Green }
                    Add-ReportLine $m
                }
            }
        } catch {}
    } else {
        $m="  [!] Sin adaptador Wi-Fi activo."
        if (-not $Quiet) { Write-Host $m -ForegroundColor Yellow }
        Add-ReportLine $m
    }
    $m=if ($WiFiOptimized) { ">> Wi-Fi optimizado en '$WiFiAdapterName'." } else { ">> Wi-Fi omitido." }
    if (-not $Quiet) { Write-Host $m -ForegroundColor Cyan }
    Add-ReportLine $m
} else {
    $m=">> Wi-Fi omitido."
    if (-not $Quiet) { Write-Host $m -ForegroundColor Yellow }
    Add-ReportLine $m
}

# ============================================================
# FASE 6: SERVICIOS
# ============================================================
if (-not $SkipServices) {
    if (-not $Quiet) { Write-Host "`n[FASE 6] Deteniendo servicios..." -ForegroundColor Yellow }
    Add-ReportLine "`n========================================"
    Add-ReportLine " SERVICIOS DETENIDOS"
    Add-ReportLine "========================================"
    $svcs=@('DiagTrack','dmwappushservice','WSearch','MapsBroker','lfsvc','XblGameSave','XboxNetApiSvc','XboxGipSvc','BcastDVRUserService','WMPNetworkSvc')
    if ($diskType -eq "SSD") { $svcs+='SysMain' }
    if ($TotalRAM -gt 8) { $svcs+='FontCache' }
    foreach ($n in $svcs) {
        try {
            $s=Get-Service -Name $n -ErrorAction SilentlyContinue
            if ($s -and $s.Status -eq 'Running') {
                Stop-Service -Name $n -Force -ErrorAction Stop
                Set-Service  -Name $n -StartupType Manual -ErrorAction SilentlyContinue
                $m="  [OK] Detenido: $n ($($s.DisplayName))"
                if (-not $Quiet) { Write-Host $m -ForegroundColor Green }
                Add-ReportLine $m
                $StoppedServices+=$n
            }
        } catch {}
    }
    $m=">> Servicios detenidos: $($StoppedServices.Count)"
    if (-not $Quiet) { Write-Host $m -ForegroundColor Cyan }
    Add-ReportLine $m
} else {
    $m=">> Servicios omitidos."
    if (-not $Quiet) { Write-Host $m -ForegroundColor Yellow }
    Add-ReportLine $m
}

# ============================================================
# FASE 7: DIAGNOSTICO FINAL
# ============================================================
if (-not $Quiet) { Write-Host "`n[FASE 7] Diagnostico final..." -ForegroundColor Yellow }
Add-ReportLine "`n========================================"
Add-ReportLine " DIAGNOSTICO POST-OPTIMIZACION"
Add-ReportLine "========================================"
$OF=Get-CimInstance Win32_OperatingSystem
$FreeRAMFinal=[math]::Round($OF.FreePhysicalMemory/1MB,2)
$TotalRAMFinal=[math]::Round($OF.TotalVisibleMemorySize/1MB,2)
$UsedRAMFinal=[math]::Round($TotalRAMFinal-$FreeRAMFinal,2)
$RAMPercentFinal=[math]::Round(($UsedRAMFinal/$TotalRAMFinal)*100,1)
$RAMGained_GB=[math]::Round($FreeRAMFinal-$FreeRAM,2)
$RAMGained_MB=[math]::Round(($FreeRAMFinal-$FreeRAM)*1024,0)
$post=@"
--- ESTADO FINAL ---
RAM Total: ${TotalRAMFinal} GB | Usada: ${UsedRAMFinal} GB | Libre: ${FreeRAMFinal} GB | Uso: ${RAMPercentFinal}%
RAM liberada neta: ${RAMGained_GB} GB (${RAMGained_MB} MB)
"@
if (-not $Quiet) { Write-Host $post -ForegroundColor White }
Add-ReportLine $post

$Recs=@()
if ($RAMPercent -gt 80) { $Recs+="Alto uso de RAM (>80%). Cierre apps pesadas." }
if ($DiskFreeC -lt 10)  { $Recs+="Poco espacio en C: (<10 GB)." }
if ($TotalRAM -lt 8)    { $Recs+="RAM < 8 GB. Considere actualizar." }
if ($diskType -eq "HDD" -and (Get-Service SysMain -ErrorAction SilentlyContinue).Status -eq 'Running') { $Recs+="SysMain activo en HDD." }
if ($WiFiOptimized)     { $Recs+="Wi-Fi lento: actualice driver y use banda 5 GHz." }
if ($Recs.Count -gt 0) {
    Add-ReportLine "`n========================================"
    Add-ReportLine " RECOMENDACIONES"
    Add-ReportLine "========================================"
    foreach ($r in $Recs) {
        Add-ReportLine "  * $r"
        if (-not $Quiet) { Write-Host "  * $r" -ForegroundColor Yellow }
    }
}

$WSt = if ($WiFiOptimized) { "Optimizado ($WiFiAdapterName)" } else { "Omitido" }
$BSt = if ($KillBraveUpdater) { "$BraveSvcKilled svc, $([math]::Round($BraveFreedMB,1)) MB" } else { "No solicitado" }
$BLim = if ($LimitBrave) { "$BraveBgKilled procesos cerrados, $BraveTrimmed compactados" } else { "No solicitado" }

$R=@"

╔══════════════════════════════════════════════╗
║          RESUMEN DE OPTIMIZACION v2.6        ║
╠══════════════════════════════════════════════╣
║  Motor:                        $($PSVersionTable.PSEdition) $($PSVersionTable.PSVersion)
║  Procesos terminados:          $KilledCount
║  RAM liberada (procesos):      $([math]::Round($FreedRAM_MB,1)) MB
║  RAM liberada (compactacion):  $FreedByCompactMB MB
║  Archivos temporales:          $([math]::Round($TotalDeletedMB,2)) MB
║  Servicios detenidos:          $($StoppedServices.Count)
║  Brave Updater:                $BSt
║  Limitador Brave:              $BLim
║  Wi-Fi:                        $WSt
║  RAM libre ANTES:              ${FreeRAM} GB
║  RAM libre AHORA:              ${FreeRAMFinal} GB
║  MEJORA NETA:                  ${RAMGained_GB} GB (${RAMGained_MB} MB)
╚══════════════════════════════════════════════╝

[!] Brave (navegador) y Tailscale excluidos de la terminacion general.
[!] Procesos de Brave en 2do plano > 300 MB cerrados si se solicitó -LimitBrave.
Reporte guardado en: $ReportFile
"@
if (-not $Quiet) { Write-Host $R -ForegroundColor Cyan }
Add-ReportLine $R

$FullReport=$OutputLines -join "`n"
$FullReport | Out-File -FilePath $ReportFile -Encoding UTF8 -Force
try { $FullReport | Set-Clipboard } catch {}

if (-not $Quiet) {
    Write-Host "`n[OK] Reporte copiado al portapapeles y guardado: $ReportFile" -ForegroundColor Green
    Write-Host "`nPresiona cualquier tecla para salir..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}