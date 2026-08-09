param(
    [ValidateSet("DryRun","Backup")]
    [string]$Mode = "DryRun"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"

Write-Host "[RUNEFORGE_BACKUP_V1][$ts]"
Write-Host "[MODE] $Mode"

$Source = "C:\RUNEFOGE_PRO\runeforge"
$BackupRoot = "D:\RUNEFORGE_BACKUPS"
$ArchiveRoot = "G:\RUNEFORGE_ARCHIVE"
$StorageDir = Join-Path $Source "data\storage"

$Dest = Join-Path $BackupRoot ("daily\runeforge_" + $stamp)
$ReportDir = Join-Path $BackupRoot "_reports"
$Report = Join-Path $ReportDir ("backup_report_" + $stamp + "_" + $Mode + ".log")
$Manifest = Join-Path $StorageDir ("backup_manifest_" + $stamp + "_" + $Mode + ".json")

New-Item -ItemType Directory -Force -Path $BackupRoot,$ArchiveRoot,$ReportDir,$StorageDir | Out-Null

if (-not (Test-Path -LiteralPath $Source)) {
    throw "No existe Source: $Source"
}

if (-not (Test-Path -LiteralPath $BackupRoot)) {
    throw "No existe BackupRoot: $BackupRoot"
}

$excludeDirs = @(
    "node_modules",
    ".git",
    ".next",
    "dist",
    "build",
    ".turbo",
    "coverage",
    "tmp",
    "temp"
)

$excludeFiles = @(
    "*.log",
    "*.tmp",
    "*.cache"
)

$robocopyArgs = @(
    $Source,
    $Dest,
    "/E",
    "/COPY:DAT",
    "/DCOPY:DAT",
    "/R:1",
    "/W:1",
    "/XJ",
    "/FFT",
    "/NP",
    "/TEE",
    "/LOG:$Report"
)

if ($Mode -eq "DryRun") {
    $robocopyArgs += "/L"
}

foreach ($d in $excludeDirs) {
    $robocopyArgs += "/XD"
    $robocopyArgs += (Join-Path $Source $d)
}

foreach ($f in $excludeFiles) {
    $robocopyArgs += "/XF"
    $robocopyArgs += $f
}

Write-Host "`n[BACKUP_PLAN]"
[pscustomobject]@{
    Mode = $Mode
    Source = $Source
    Destination = $Dest
    Report = $Report
    Manifest = $Manifest
    CopyFiles = if($Mode -eq "Backup"){"YES"}else{"NO"}
    ExcludeDirs = ($excludeDirs -join ", ")
    ExcludeFiles = ($excludeFiles -join ", ")
} | Format-List

Write-Host "`n[ROBOCOPY_EXEC]"
Write-Host ("robocopy " + ($robocopyArgs -join " "))

& robocopy @robocopyArgs
$rc = $LASTEXITCODE

$ok = $rc -le 7

$manifestObj = [ordered]@{
    ts = (Get-Date).ToString("o")
    status = if($ok){"OK"}else{"ROBOCOPY_ERROR"}
    mode = $Mode
    source = $Source
    destination = $Dest
    report = $Report
    robocopy_exit_code = $rc
    copied_files = if($Mode -eq "Backup"){$true}else{$false}
    backup_root = $BackupRoot
    archive_root = $ArchiveRoot
    excluded_dirs = $excludeDirs
    excluded_files = $excludeFiles
    note = "Robocopy exit codes 0-7 are treated as non-fatal."
}

$manifestObj | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $Manifest -Encoding utf8BOM -Force

Write-Host "`n[REPORT_TAIL]"
if (Test-Path -LiteralPath $Report) {
    Get-Content -LiteralPath $Report -Tail 30
} else {
    Write-Host "[WARN] No se generó reporte robocopy." -ForegroundColor Yellow
}

Write-Host "`n[SUMMARY]"
[pscustomobject]@{
    Estado = "RUNEFORGE_BACKUP_V1_DONE"
    Mode = $Mode
    RobocopyExitCode = $rc
    Result = if($ok){"OK"}else{"REVISAR"}
    Source = $Source
    Destination = $Dest
    Report = $Report
    Manifest = $Manifest
    CopiedFiles = if($Mode -eq "Backup"){"YES"}else{"NO_DRYRUN"}
    Backend = "NO_TOCADO"
    Runeforge = "RESPALDO_SIMULADO_O_EJECUTADO"
    Siguiente = if($Mode -eq "DryRun"){"Validar reporte y luego correr -Mode Backup"}else{"Validar archivos en D"}
} | Format-List

if (-not $ok) {
    exit $rc
}
