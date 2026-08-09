Set-StrictMode -Version Latest
$ErrorActionPreference="Stop"

[Console]::OutputEncoding=[System.Text.UTF8Encoding]::new($false)

$ts=Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$stamp=Get-Date -Format "yyyyMMdd_HHmmss"

$Root="C:\RUNEFOGE_PRO\runeforge"
$ScriptsDir=Join-Path $Root "scripts"
$StorageDir=Join-Path $Root "data\storage"
$LogDir=Join-Path $StorageDir "scheduled"
$RunLog=Join-Path $LogDir ("daily_backup_run_"+$stamp+".log")
$CurrentLog=Join-Path $LogDir "daily_backup_task_current.log"

$BackupScript=Join-Path $ScriptsDir "Invoke-RuneforgeBackup-V2.3-SafeDaily.ps1"
$RotationScript=Join-Path $ScriptsDir "Invoke-RuneforgeBackupRotation-V1.ps1"

New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

Start-Transcript -LiteralPath $RunLog -Force | Out-Null

try {
    Write-Host "[RUNEFORGE_DAILY_BACKUP_V1][$ts]"
    Write-Host "[STEP] Backup V2.3 SafeDaily"

    pwsh -NoLogo -ExecutionPolicy Bypass -File $BackupScript -Mode Backup
    $backupCode=$LASTEXITCODE

    if($backupCode -gt 7){
        throw "Backup falló. ExitCode=$backupCode"
    }

    Write-Host "`n[STEP] Rotation V1 Apply"

    pwsh -NoLogo -ExecutionPolicy Bypass -File $RotationScript -Mode Apply
    $rotationCode=$LASTEXITCODE

    if($rotationCode -ne 0){
        throw "Rotación falló. ExitCode=$rotationCode"
    }

    $summary=[pscustomobject]@{
        ts=(Get-Date).ToString("o")
        status="OK"
        backup_exit_code=$backupCode
        rotation_exit_code=$rotationCode
        run_log=$RunLog
        backend="NO_TOCADO"
        runeforge="BACKUP_DIARIO_PROGRAMADO"
    }

    $summary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $CurrentLog -Encoding utf8BOM -Force

    Write-Host "`n[SUMMARY]"
    $summary | Format-List

} catch {
    $summary=[pscustomobject]@{
        ts=(Get-Date).ToString("o")
        status="ERROR"
        error=$_.Exception.Message
        run_log=$RunLog
        backend="NO_TOCADO"
        runeforge="BACKUP_DIARIO_PROGRAMADO"
    }

    $summary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $CurrentLog -Encoding utf8BOM -Force

    Write-Host "`n[ERROR]"
    $summary | Format-List
    exit 8

} finally {
    Stop-Transcript | Out-Null
}
