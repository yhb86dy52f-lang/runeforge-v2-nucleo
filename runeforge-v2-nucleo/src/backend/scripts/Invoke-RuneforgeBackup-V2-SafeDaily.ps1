param(
    [ValidateSet("DryRun","Backup")]
    [string]$Mode = "DryRun"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"

Write-Host "[RUNEFORGE_BACKUP_V2_SAFE_DAILY][$ts]"
Write-Host "[MODE] $Mode"

$Source = "C:\RUNEFOGE_PRO\runeforge"
$BackupRoot = "D:\RUNEFORGE_BACKUPS"
$StorageDir = Join-Path $Source "data\storage"

$DestRoot = Join-Path $BackupRoot ("daily\runeforge_safe_daily_" + $stamp)
$ReportDir = Join-Path $BackupRoot "_reports"
$Report = Join-Path $ReportDir ("backup_report_" + $stamp + "_" + $Mode + "_v2_safe_daily.log")
$Manifest = Join-Path $StorageDir ("backup_manifest_" + $stamp + "_" + $Mode + "_v2_safe_daily.json")

New-Item -ItemType Directory -Force -Path $BackupRoot,$ReportDir,$StorageDir,$DestRoot | Out-Null

$jobs = @(
    @{ Name="root_files"; Source=$Source; Dest=$DestRoot; Files=@("*.md","*.txt","*.json","*.cmd","package.json","package-lock.json",".gitignore") },
    @{ Name="app_src"; Source=(Join-Path $Source "app\src"); Dest=(Join-Path $DestRoot "app\src"); Files=@("*.*") },
    @{ Name="app_public"; Source=(Join-Path $Source "app\public"); Dest=(Join-Path $DestRoot "app\public"); Files=@("*.*") },
    @{ Name="app_scripts"; Source=(Join-Path $Source "app\scripts"); Dest=(Join-Path $DestRoot "app\scripts"); Files=@("*.*") },
    @{ Name="app_ops"; Source=(Join-Path $Source "app\ops"); Dest=(Join-Path $DestRoot "app\ops"); Files=@("*.*") },
    @{ Name="scripts"; Source=(Join-Path $Source "scripts"); Dest=(Join-Path $DestRoot "scripts"); Files=@("*.*") },
    @{ Name="docs"; Source=(Join-Path $Source "docs"); Dest=(Join-Path $DestRoot "docs"); Files=@("*.*") },
    @{ Name="data_nodes"; Source=(Join-Path $Source "data\nodes"); Dest=(Join-Path $DestRoot "data\nodes"); Files=@("*.*") },
    @{ Name="data_storage"; Source=(Join-Path $Source "data\storage"); Dest=(Join-Path $DestRoot "data\storage"); Files=@("*.*") },
    @{ Name="data_commander"; Source=(Join-Path $Source "data\commander"); Dest=(Join-Path $DestRoot "data\commander"); Files=@("*.*") }
)

$excludeDirs = @(
    "node_modules",
    ".git",
    ".next",
    "dist",
    "build",
    ".turbo",
    "coverage",
    "tmp",
    "temp",
    ".cache",
    "archive",
    "_archive",
    "runeforge",
    "_downloads",
    "roms",
    "bios",
    "emulators"
)

$excludeFiles = @(
    ".env",
    ".env.*",
    "*.log",
    "*.tmp",
    "*.cache",
    "*.pid"
)

$results = New-Object System.Collections.Generic.List[object]
$exitCodes = New-Object System.Collections.Generic.List[int]

Write-Host "`n[BACKUP_PLAN]"
[pscustomobject]@{
    Version = "2.0-safe-daily"
    Mode = $Mode
    DestinationRoot = $DestRoot
    Report = $Report
    Manifest = $Manifest
    CopyFiles = if($Mode -eq "Backup"){"YES"}else{"NO"}
    Jobs = ($jobs.Name -join ", ")
    ExcludeDirs = ($excludeDirs -join ", ")
    ExcludeFiles = ($excludeFiles -join ", ")
} | Format-List

foreach ($job in $jobs) {
    if (-not (Test-Path -LiteralPath $job.Source)) {
        $results.Add([pscustomobject]@{
            Job = $job.Name
            Source = $job.Source
            Status = "SKIPPED_SOURCE_NOT_FOUND"
            ExitCode = $null
        })
        continue
    }

    New-Item -ItemType Directory -Force -Path $job.Dest | Out-Null

    $args = @(
        $job.Source,
        $job.Dest
    )

    foreach ($filePattern in $job.Files) {
        $args += $filePattern
    }

    $args += @(
        "/E",
        "/COPY:DAT",
        "/DCOPY:DAT",
        "/R:1",
        "/W:1",
        "/XJ",
        "/FFT",
        "/NP",
        "/TEE",
        "/LOG+:$Report"
    )

    if ($Mode -eq "DryRun") {
        $args += "/L"
    }

    foreach ($d in $excludeDirs) {
        $args += "/XD"
        $args += $d
    }

    foreach ($f in $excludeFiles) {
        $args += "/XF"
        $args += $f
    }

    Write-Host "`n[ROBOCOPY_JOB:$($job.Name)]"
    Write-Host ("robocopy " + ($args -join " "))

    & robocopy @args
    $rc = $LASTEXITCODE
    $exitCodes.Add([int]$rc)

    $results.Add([pscustomobject]@{
        Job = $job.Name
        Source = $job.Source
        Dest = $job.Dest
        Status = if($rc -le 7){"OK"}else{"ROBOCOPY_ERROR"}
        ExitCode = $rc
    })
}

$reportRaw = if(Test-Path -LiteralPath $Report){Get-Content -LiteralPath $Report -Raw}else{""}

$actualEnvPlanned = [bool]($reportRaw -match "(?m)^\s*(Nuevo arch|New File|Newer|Older).*(\\|/)?\.env(\s|$)")
$actualNodeModulesPlanned = [bool]($reportRaw -match "(?m)^\s*(Nuevo dir|New Dir).*(\\|/)node_modules(\\|/|\s|$)")
$actualArchivePlanned = [bool]($reportRaw -match "(?m)^\s*(Nuevo dir|New Dir).*(\\|/)(archive|_archive)(\\|/|\s|$)")

$maxCode = if($exitCodes.Count -gt 0){($exitCodes | Measure-Object -Maximum).Maximum}else{0}
$ok = ($maxCode -le 7) -and (-not $actualEnvPlanned) -and (-not $actualNodeModulesPlanned) -and (-not $actualArchivePlanned)

$manifestObj = [ordered]@{
    ts = (Get-Date).ToString("o")
    version = "2.0-safe-daily"
    status = if($ok){"OK"}else{"REVIEW_REQUIRED"}
    mode = $Mode
    destination_root = $DestRoot
    report = $Report
    robocopy_exit_codes = @($exitCodes)
    copied_files = if($Mode -eq "Backup"){$true}else{$false}
    jobs = @($results)
    security_check = [ordered]@{
        actual_env_planned = $actualEnvPlanned
        actual_node_modules_planned = $actualNodeModulesPlanned
        actual_archive_planned = $actualArchivePlanned
    }
    excluded_dirs = $excludeDirs
    excluded_files = $excludeFiles
}

$manifestObj | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $Manifest -Encoding utf8BOM -Force

Write-Host "`n[JOB_RESULTS]"
$results | Format-Table -AutoSize

Write-Host "`n[SECURITY_CHECK_V2]"
[pscustomobject]@{
    ActualEnvPlanned = $actualEnvPlanned
    ActualNodeModulesPlanned = $actualNodeModulesPlanned
    ActualArchivePlanned = $actualArchivePlanned
    CopiedFiles = if($Mode -eq "Backup"){"YES"}else{"NO_DRYRUN"}
    ExpectedEnvPlanned = $false
    ExpectedNodeModulesPlanned = $false
    ExpectedArchivePlanned = $false
} | Format-List

Write-Host "`n[SUMMARY]"
[pscustomobject]@{
    Estado = "RUNEFORGE_BACKUP_V2_SAFE_DAILY_DONE"
    Mode = $Mode
    Result = if($ok){"OK"}else{"REVISAR"}
    MaxRobocopyExitCode = $maxCode
    DestinationRoot = $DestRoot
    Report = $Report
    Manifest = $Manifest
    CopiedFiles = if($Mode -eq "Backup"){"YES"}else{"NO_DRYRUN"}
    Backend = "NO_TOCADO"
    Runeforge = "RESPALDO_SAFE_DAILY_SIMULADO_O_EJECUTADO"
    Siguiente = if($Mode -eq "DryRun"){"Si SECURITY_CHECK_V2 está limpio, correr -Mode Backup"}else{"Validar archivos en D"}
} | Format-List

if (-not $ok) {
    exit 8
}
