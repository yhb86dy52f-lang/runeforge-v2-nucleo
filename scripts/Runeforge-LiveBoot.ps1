<#
.SYNOPSIS
    Runeforge LiveBoot v2 — Liberación segura de RAM y limpieza de cachés.
.DESCRIPTION
    Cierra procesos no esenciales (por categoría) y limpia cachés/temporales.
    Por defecto es PREVIEW. Usa -Apply para ejecutar. Soporta -WhatIf nativo.
.PARAMETER Apply
    Ejecuta los cambios realmente.
.PARAMETER Ultra
    Añade: wsl --shutdown, docker system prune, limpieza de Prefetch.
.PARAMETER Category
    Categorías a procesar. Por defecto: All.
.PARAMETER Restore
    Reabre los procesos guardados en el último snapshot.
.PARAMETER ConfigPath
    JSON con Protected/Categories/CachePaths personalizados.
.EXAMPLE
    .\Runeforge-LiveBoot.ps1
    .\Runeforge-LiveBoot.ps1 -Apply -Category Browser,Cloud
    .\Runeforge-LiveBoot.ps1 -Apply -Ultra -Confirm
    .\Runeforge-LiveBoot.ps1 -Restore
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [switch]$Apply,
    [switch]$Ultra,
    [ValidateSet('All','Browser','Cloud','Dev','Media','System')]
    [string[]]$Category = @('All'),
    [switch]$Restore,
    [string]$ConfigPath,
    [switch]$NoColor
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'
$script:StartTime = Get-Date

#region ── Configuración ─────────────────────────────────────────────
$script:Config = @{
    Protected = @(
        'System','Idle','Registry','Memory Compression','csrss','wininit','winlogon',
        'services','lsass','smss','svchost','fontdrvhost','dwm','explorer',
        'pwsh','powershell','WindowsTerminal','conhost','cmd','OpenConsole',
        'SecurityHealthService','MsMpEng','NisSrv','SecurityHealthSystray',
        'audiodg','WUDFHost','ShellExperienceHost','StartMenuExperienceHost',
        'SearchHost','RuntimeBroker','TextInputHost','ctfmon','sihost','taskhostw'
    )
    ProtectAncestors = $true

    Categories = @{
        Browser = @('brave','chrome','msedge','firefox','opera','vivaldi','brave-browser','brave*')
        Cloud   = @('iCloud*','Dropbox','OneDrive','GoogleDrive*','ApplePhotoStreams',
                    'AppleMobileDeviceService','APSDaemon','mDNSResponder','secd')
        Dev     = @('vctip','wslservice','vmms','vmcompute','docker*','node','cargo','rustc')
        Media   = @('Spotify','VLC','PotPlayer*','AppleMusic*','Music.UI')
        System  = @('NVDisplay.Container','CompPkgSrv','UserOOBEBroker','OpenWith',
                    'smartscreen','MpDefenderCoreService','Secure System','mscopilot_proxy',
                    'tailscaled','iCloudCKKS','iCloudHome','iCloudDrive',
                    'iCloudPasswordsExtensionHelper')
    }

    CachePaths = @(
        @{ Name='Cargo registry';  Path="$env:USERPROFILE\.cargo\registry\cache" }
        @{ Name='Thumbnail cache'; Path="$env:LOCALAPPDATA\Microsoft\Windows\Explorer" }
        @{ Name='CrashDumps';      Path="$env:LOCALAPPDATA\CrashDumps" }
        @{ Name='Brave cache';     Path="$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Cache" }
        @{ Name='Windows Update';  Path="$env:WINDIR\SoftwareDistribution\Download" }
        @{ Name='INetCache';       Path="$env:LOCALAPPDATA\Microsoft\Windows\INetCache" }
        @{ Name='Windows Temp';    Path="$env:WINDIR\Temp" }
        @{ Name='User Temp';       Path="$env:TEMP" }
    )

    SnapshotDir = Join-Path $env:LOCALAPPDATA 'Runeforge\Snapshots'
    LogDir      = Join-Path $env:LOCALAPPDATA 'Runeforge\Logs'
}

if ($ConfigPath -and (Test-Path -LiteralPath $ConfigPath)) {
    try {
        $user = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
        foreach ($k in $user.PSObject.Properties.Name) { $script:Config[$k] = $user.$k }
    } catch { Write-Warning "No se pudo cargar config: $_" }
}
#endregion

#region ── Salida ────────────────────────────────────────────────────
function Write-Header($t) {
    if ($NoColor) { Write-Host "`n=== $t ===" }
    else {
        Write-Host "`n$('=' * 62)" -ForegroundColor DarkCyan
        Write-Host "  $t"          -ForegroundColor Cyan
        Write-Host "$('=' * 62)"   -ForegroundColor DarkCyan
    }
}
function Write-OK($t)   { if ($NoColor) { Write-Host $t } else { Write-Host $t -ForegroundColor Green } }
function Write-Warn($t) { if ($NoColor) { Write-Host $t } else { Write-Host $t -ForegroundColor Yellow } }
function Write-Err($t)  { if ($NoColor) { Write-Host $t } else { Write-Host $t -ForegroundColor Red } }
function Write-Info($t) { if ($NoColor) { Write-Host $t } else { Write-Host $t -ForegroundColor Gray } }

function Format-Size([double]$bytes) {
    if ($bytes -ge 1GB) { return ('{0:N2} GB' -f ($bytes / 1GB)) }
    if ($bytes -ge 1MB) { return ('{0:N2} MB' -f ($bytes / 1MB)) }
    if ($bytes -ge 1KB) { return ('{0:N2} KB' -f ($bytes / 1KB)) }
    return ('{0:N0} B' -f $bytes)
}
#endregion

#region ── Protección dinámica de la cadena de procesos ──────────────
function Get-ProtectedPids {
    $set = [System.Collections.Generic.HashSet[int]]::new()
    $names = [System.Collections.Generic.HashSet[string]]::new(
        [string[]]$script:Config.Protected, [StringComparer]::OrdinalIgnoreCase)

    Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | ForEach-Object {
        if ($names.Contains($_.Name)) { [void]$set.Add([int]$_.ProcessId) }
    }

    if ($script:Config.ProtectAncestors) {
        $cur = $PID
        for ($i = 0; $i -lt 12 -and $cur -gt 0; $i++) {
            [void]$set.Add([int]$cur)
            $proc = Get-CimInstance Win32_Process -Filter "ProcessId=$cur" -ErrorAction SilentlyContinue
            if (-not $proc) { break }
            $parent = [int]$proc.ParentProcessId
            if ($parent -le 0 -or $parent -eq $cur) { break }
            $cur = $parent
        }
    }
    return $set
}
#endregion

#region ── RAM ───────────────────────────────────────────────────────
function Get-RamStats {
    $os = Get-CimInstance Win32_OperatingSystem
    $totalMB = $os.TotalVisibleMemorySize / 1KB
    $freeMB  = $os.FreePhysicalMemory / 1KB
    [pscustomobject]@{
        TotalGB = [math]::Round($totalMB / 1KB, 2)
        FreeGB  = [math]::Round($freeMB  / 1KB, 2)
        UsedGB  = [math]::Round(($totalMB - $freeMB) / 1KB, 2)
        UsedPct = [math]::Round((($totalMB - $freeMB) / $totalMB) * 100, 1)
    }
}
#endregion

#region ── Candidatos a cerrar ───────────────────────────────────────
function Get-KillCandidates {
    param([string[]]$Cats)

    $protected = Get-ProtectedPids
    $patterns = @()
    if ($Cats -contains 'All') {
        foreach ($v in $script:Config.Categories.Values) { $patterns += $v }
    } else {
        foreach ($c in $Cats) { if ($script:Config.Categories.ContainsKey($c)) { $patterns += $script:Config.Categories[$c] } }
    }
    $patterns = $patterns | Select-Object -Unique

    Get-Process -ErrorAction SilentlyContinue | Where-Object {
        if ($protected.Contains([int]$_.Id)) { return $false }
        $n = $_.Name
        foreach ($p in $patterns) { if ($n -like $p) { return $true } }
        return $false
    } | Sort-Object -Property WorkingSet64 -Descending
}
#endregion

#region ── Tamaño de cachés ──────────────────────────────────────────
function Get-FolderSize {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return [int64]0 }
    try {
        $sum = (Get-ChildItem -LiteralPath $Path -Recurse -Force -File -ErrorAction SilentlyContinue |
                Measure-Object -Property Length -Sum).Sum
        if ($null -eq $sum) { return [int64]0 }
        return [int64]$sum
    } catch { return [int64]0 }
}

function Get-CacheReport {
    $script:Config.CachePaths | ForEach-Object {
        $size = Get-FolderSize -Path $_.Path
        [pscustomobject]@{
            Name = $_.Name
            Path = $_.Path
            Size = $size
            Exists = (Test-Path -LiteralPath $_.Path)
        }
    } | Sort-Object Size -Descending
}
#endregion

#region ── Snapshot / Restore ────────────────────────────────────────
function Save-Snapshot {
    param([object[]]$Processes)
    if (-not (Test-Path -LiteralPath $script:Config.SnapshotDir)) {
        New-Item -ItemType Directory -Path $script:Config.SnapshotDir -Force | Out-Null
    }
    $file = Join-Path $script:Config.SnapshotDir ("snapshot_{0:yyyyMMdd_HHmmss}.json" -f (Get-Date))
    $entries = foreach ($p in $Processes) {
        $exePath = $null
        try { $exePath = $p.Path } catch { }
        [pscustomobject]@{
            Name = $p.Name
            Id   = $p.Id
            Path = $exePath
            WS   = $p.WorkingSet64
        }
    }
    $data = [pscustomobject]@{
        Timestamp = (Get-Date).ToString('o')
        Processes = $entries
    }
    $data | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $file -Encoding UTF8
    return $file
}

function Restore-LastSnapshot {
    $latest = Get-ChildItem -LiteralPath $script:Config.SnapshotDir -Filter 'snapshot_*.json' -ErrorAction SilentlyContinue |
              Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (-not $latest) { Write-Warn 'No hay snapshots para restaurar.'; return }

    Write-Header "RESTAURANDO: $($latest.Name)"
    $data = Get-Content -LiteralPath $latest.FullName -Raw | ConvertFrom-Json
    $running = (Get-Process -ErrorAction SilentlyContinue).Name

    foreach ($p in $data.Processes) {
        if ($running -contains $p.Name) { Write-Info "  · $($p.Name) ya está corriendo"; continue }
        if (-not $p.Path -or -not (Test-Path -LiteralPath $p.Path)) {
            Write-Warn "  · $($p.Name) sin ruta válida — omitido"; continue
        }
        try {
            Start-Process -FilePath $p.Path -ErrorAction Stop | Out-Null
            Write-OK "  ✓ $($p.Name)"
        } catch { Write-Err "  ✗ $($p.Name): $_" }
    }
}
#endregion

#region ── Núcleo ───────────────────────────────────────────────────
if ($Restore) {
    if (-not $Apply) { Write-Warn 'Modo PREVIEW. Añade -Apply para restaurar de verdad.' }
    if ($Apply) { Restore-LastSnapshot }
    return
}

Write-Header 'ESTADO ACTUAL'
$cpu   = (Get-CimInstance Win32_Processor | Select-Object -First 1)
$ram0  = Get-RamStats
$diskC = Get-PSDrive C
Write-Host ("CPU    : {0}" -f $cpu.Name)
Write-Host ("Núcleos: {0} cores / {1} hilos" -f $cpu.NumberOfCores, $cpu.NumberOfLogicalProcessors)
Write-Host ("RAM    : {0} / {1} GB ({2}% usado)" -f $ram0.UsedGB, $ram0.TotalGB, $ram0.UsedPct)
Write-Host ("Disco C: {0:N2} GB libres" -f ($diskC.Free / 1GB))
Write-Host ("Modo   : {0}" -f $(if ($Apply) { 'APPLY' } else { 'PREVIEW (sin -Apply)' }))

if (-not $Apply) { Write-Warn "`n  → Dry-run. Añade -Apply para ejecutar realmente.`n" }

# ── Candidatos ─────────────────────────────────────────────────────
Write-Header 'PROCESOS CANDIDATOS A CERRAR'
$candidates = @(Get-KillCandidates -Cats $Category)

if ($candidates.Count -eq 0) {
    Write-Info '  (ninguno)'
} else {
    $grouped = $candidates | Group-Object Name | ForEach-Object {
        [pscustomobject]@{
            Name  = $_.Name
            Count = $_.Count
            MB    = [math]::Round((($_.Group | Measure-Object WorkingSet64 -Sum).Sum) / 1MB, 1)
        }
    } | Sort-Object MB -Descending

    $grouped | ForEach-Object { Write-Host ("  {0,-35} {1,3} proc  {2,8:N1} MB" -f $_.Name, $_.Count, $_.MB) }
    $totalMB = ($grouped | Measure-Object MB -Sum).Sum
    Write-Host ''
    Write-Host ("  TOTAL: {0} procesos | {1:N0} MB liberables" -f $candidates.Count, $totalMB)
}

# ── Cachés ─────────────────────────────────────────────────────────
Write-Header 'CACHÉS Y TEMPORALES'
$cache = Get-CacheReport
$cacheTotal = ($cache | Measure-Object Size -Sum).Sum
foreach ($c in $cache) {
    $state = if ($c.Exists) { Format-Size $c.Size } else { '(no existe)' }
    Write-Host ("  {0,-25} {1,>12}" -f $c.Name, $state)
}
Write-Host ''
Write-Host ("  TOTAL RECUPERABLE: {0}" -f (Format-Size $cacheTotal))

# ── Ejecución ──────────────────────────────────────────────────────
$snapshotFile = $null
if ($Apply -and $candidates.Count -gt 0) {
    Write-Header 'CERRANDO PROCESOS'
    $snapshotFile = Save-Snapshot -Processes $candidates
    Write-Info "  Snapshot: $snapshotFile"

    foreach ($p in $candidates) {
        $target = "$($p.Name) (PID $($p.Id))"
        if ($PSCmdlet.ShouldProcess($target, 'Stop-Process')) {
            try {
                Stop-Process -Id $p.Id -Force -ErrorAction Stop
                Write-OK "  ✓ $target"
            } catch {
                Write-Err "  ✗ $target — $($_.Exception.Message)"
            }
        }
    }
}

if ($Apply -and $cacheTotal -gt 0) {
    Write-Header 'LIMPIANDO CACHÉS'
    foreach ($c in $cache) {
        if (-not $c.Exists) { continue }
        if ($PSCmdlet.ShouldProcess($c.Path, "Vaciar ($($c.Name))")) {
            try {
                Get-ChildItem -LiteralPath $c.Path -Recurse -Force -ErrorAction SilentlyContinue |
                    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                Write-OK ("  ✓ {0} — {1}" -f $c.Name, (Format-Size $c.Size))
            } catch {
                Write-Warn ("  ⚠ {0} — parcialmente bloqueado" -f $c.Name)
            }
        }
    }
}

if ($Apply -and $Ultra) {
    Write-Header 'MODO ULTRA'
    if ($PSCmdlet.ShouldProcess('wsl', 'wsl --shutdown')) {
        & wsl --shutdown 2>$null; Write-OK '  ✓ WSL detenido'
    }
    if (Get-Command docker -ErrorAction SilentlyContinue) {
        if ($PSCmdlet.ShouldProcess('docker', 'system prune -af')) {
            & docker system prune -af 2>$null | Out-Null
            Write-OK '  ✓ Docker prune'
        }
    }
    if ($PSCmdlet.ShouldProcess("$env:WINDIR\Prefetch", 'Limpiar Prefetch')) {
        Get-ChildItem "$env:WINDIR\Prefetch\*.pf" -Force -ErrorAction SilentlyContinue |
            Remove-Item -Force -ErrorAction SilentlyContinue
        Write-OK '  ✓ Prefetch limpiado'
    }
}

# ── Estado final ───────────────────────────────────────────────────
if ($Apply) {
    Write-Info "`n  Esperando 2s para estabilizar métricas..."
    Start-Sleep -Seconds 2
}
Write-Header 'ESTADO FINAL'
$ram1  = Get-RamStats
$disk1 = Get-PSDrive C
Write-Host ("RAM libre : {0} GB → {1} GB  ({2:+#.##;-#.##;0} GB)" -f $ram0.FreeGB, $ram1.FreeGB, ($ram1.FreeGB - $ram0.FreeGB))
Write-Host ("RAM usada : {0}% → {1}%" -f $ram0.UsedPct, $ram1.UsedPct)
Write-Host ("Disco C:  {0:N2} GB → {1:N2} GB" -f ($diskC.Free / 1GB), ($disk1.Free / 1GB))

$elapsed = (Get-Date) - $script:StartTime
Write-Host ("`nTiempo total: {0:N1} seg" -f $elapsed.TotalSeconds)

# ── Log ────────────────────────────────────────────────────────────
if (-not (Test-Path -LiteralPath $script:Config.LogDir)) {
    New-Item -ItemType Directory -Path $script:Config.LogDir -Force | Out-Null
}
$logFile = Join-Path $script:Config.LogDir ("runeforge_{0:yyyyMMdd_HHmmss}.log" -f (Get-Date))
@(
    "Runeforge LiveBoot v2 — $(Get-Date -Format 'o')"
    "Modo: $(if ($Apply) { 'APPLY' } else { 'PREVIEW' }) | Ultra=$Ultra | Categorías=$($Category -join ',')"
    "RAM libre: $($ram0.FreeGB) → $($ram1.FreeGB) GB"
    "Disco C libre: $([math]::Round($diskC.Free/1GB,2)) → $([math]::Round($disk1.Free/1GB,2)) GB"
    "Snapshot: $snapshotFile"
) | Set-Content -LiteralPath $logFile -Encoding UTF8

Write-Info "`nLog: $logFile"
if ($snapshotFile) { Write-Info "Snapshot (restaurable con -Restore -Apply): $snapshotFile" }
Write-Host '=== FIN ==='
#endregion

