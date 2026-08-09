param(
    [ValidateSet("DryRun","Apply")]
    [string]$Mode = "DryRun",

    [int]$DailyKeep = 7,

    [int]$WeeklyKeep = 4
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

[Console]::OutputEncoding=[System.Text.UTF8Encoding]::new($false)

$ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"

Write-Host "[RUNEFORGE_BACKUP_ROTATION_V1][$ts]"
Write-Host "[MODE] $Mode"

$Root = "C:\RUNEFOGE_PRO\runeforge"
$DailyRoot = "D:\RUNEFORGE_BACKUPS\daily"
$WeeklyRoot = "G:\RUNEFORGE_ARCHIVE\weekly"
$StorageDir = Join-Path $Root "data\storage"
$RotationDir = Join-Path $StorageDir "rotation"

New-Item -ItemType Directory -Force -Path $RotationDir | Out-Null

$Report = Join-Path $RotationDir ("rotation_report_" + $stamp + "_" + $Mode + ".json")
$Current = Join-Path $RotationDir "rotation_current.json"

if (-not (Test-Path -LiteralPath $DailyRoot)) {
    throw "No existe DailyRoot: $DailyRoot"
}

if (-not (Test-Path -LiteralPath $WeeklyRoot)) {
    throw "No existe WeeklyRoot: $WeeklyRoot"
}

function Get-RotationPlan {
    param(
        [string]$RootPath,
        [string]$Kind,
        [int]$Keep,
        [string[]]$RequiredSeals
    )

    $dirs = @(Get-ChildItem -LiteralPath $RootPath -Directory -Filter "runeforge_safe_daily_*" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending)
    $keepList = @($dirs | Select-Object -First $Keep)
    $candidateList = @($dirs | Select-Object -Skip $Keep)

    $items = @()

    foreach ($dir in $keepList) {
        $items += [pscustomobject]@{
            Kind = $Kind
            Action = "KEEP"
            Name = $dir.Name
            FullName = $dir.FullName
            LastWriteTime = $dir.LastWriteTime.ToString("o")
            HasRequiredSeal = $true
            Reason = "Dentro del límite de retención"
        }
    }

    foreach ($dir in $candidateList) {
        $sealFound = $false
        $sealPath = ""

        foreach ($seal in $RequiredSeals) {
            $candidateSeal = Join-Path $dir.FullName $seal
            if (Test-Path -LiteralPath $candidateSeal) {
                $sealFound = $true
                $sealPath = $candidateSeal
                break
            }
        }

        $action = "DELETE_CANDIDATE"
        $reason = "Fuera del límite de retención y con sello válido"

        if (-not $sealFound) {
            $action = "SKIP_UNSEALED"
            $reason = "Fuera del límite, pero sin sello. No se borra por seguridad."
        }

        $items += [pscustomobject]@{
            Kind = $Kind
            Action = $action
            Name = $dir.Name
            FullName = $dir.FullName
            LastWriteTime = $dir.LastWriteTime.ToString("o")
            HasRequiredSeal = $sealFound
            SealPath = $sealPath
            Reason = $reason
        }
    }

    return $items
}

$dailyPlan = @(Get-RotationPlan -RootPath $DailyRoot -Kind "DAILY" -Keep $DailyKeep -RequiredSeals @("_RUNEFORGE_BACKUP_SEAL.json"))
$weeklyPlan = @(Get-RotationPlan -RootPath $WeeklyRoot -Kind "WEEKLY" -Keep $WeeklyKeep -RequiredSeals @("_RUNEFORGE_COLD_COPY_SEAL.json","_RUNEFORGE_BACKUP_SEAL.json"))

$plan = @($dailyPlan + $weeklyPlan)

$deleteCandidates = @($plan | Where-Object { $_.Action -eq "DELETE_CANDIDATE" })
$skipUnsealed = @($plan | Where-Object { $_.Action -eq "SKIP_UNSEALED" })

$deleted = @()
$deleteErrors = @()

if ($Mode -eq "Apply") {
    foreach ($item in $deleteCandidates) {
        try {
            Remove-Item -LiteralPath $item.FullName -Recurse -Force -ErrorAction Stop
            $deleted += [pscustomobject]@{
                Kind = $item.Kind
                Name = $item.Name
                FullName = $item.FullName
                Status = "DELETED"
            }
        } catch {
            $deleteErrors += [pscustomobject]@{
                Kind = $item.Kind
                Name = $item.Name
                FullName = $item.FullName
                Status = "ERROR"
                Error = $_.Exception.Message
            }
        }
    }
}

$deletedText = "NO_DRYRUN"
if ($Mode -eq "Apply") {
    $deletedText = "YES_APPLY"
}

$resultText = "OK"
if ($deleteErrors.Count -gt 0) {
    $resultText = "REVISAR"
}

Write-Host "`n[ROTATION_PLAN]"
$plan | Select-Object Kind,Action,Name,HasRequiredSeal,Reason | Format-Table -AutoSize

Write-Host "`n[DELETE_CANDIDATES]"
if ($deleteCandidates.Count -gt 0) {
    $deleteCandidates | Select-Object Kind,Name,FullName,Reason | Format-Table -AutoSize
} else {
    Write-Host "[OK] No hay carpetas candidatas para borrar." -ForegroundColor Green
}

Write-Host "`n[SKIP_UNSEALED]"
if ($skipUnsealed.Count -gt 0) {
    $skipUnsealed | Select-Object Kind,Name,FullName,Reason | Format-Table -AutoSize
} else {
    Write-Host "[OK] No hay carpetas fuera de retención sin sello." -ForegroundColor Green
}

$reportObj = [pscustomobject]@{
    ts = (Get-Date).ToString("o")
    version = "1.0"
    mode = $Mode
    result = $resultText
    daily_root = $DailyRoot
    daily_keep = $DailyKeep
    weekly_root = $WeeklyRoot
    weekly_keep = $WeeklyKeep
    total_items = $plan.Count
    delete_candidates = $deleteCandidates.Count
    skipped_unsealed = $skipUnsealed.Count
    deleted_count = $deleted.Count
    delete_error_count = $deleteErrors.Count
    deleted = @($deleted)
    delete_errors = @($deleteErrors)
    plan = @($plan)
    backend = "NO_TOCADO"
    runeforge = "ROTACION_BACKUP"
}

$reportObj | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $Report -Encoding utf8BOM -Force
$reportObj | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $Current -Encoding utf8BOM -Force

Write-Host "`n[REPORT]"
Get-Content -LiteralPath $Report -Raw

Write-Host "`n[SUMMARY]"
[pscustomObject]@{
    Estado = "BACKUP_ROTATION_V1_DONE"
    Mode = $Mode
    Result = $resultText
    DailyRoot = $DailyRoot
    DailyKeep = $DailyKeep
    WeeklyRoot = $WeeklyRoot
    WeeklyKeep = $WeeklyKeep
    DeleteCandidates = $deleteCandidates.Count
    SkippedUnsealed = $skipUnsealed.Count
    Deleted = $deletedText
    DeletedCount = $deleted.Count
    DeleteErrors = $deleteErrors.Count
    Report = $Report
    Current = $Current
    Backend = "NO_TOCADO"
    Runeforge = "ROTACION_BACKUP"
    Siguiente = "Crear tarea programada diaria de backup si este DryRun queda OK"
} | Format-List

if ($deleteErrors.Count -gt 0) {
    exit 8
}
