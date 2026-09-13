$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Join-Path $scriptDir ".."
Set-Location $root

$backupDir = "C:\RUNEFORGE_BACKUPS\bitacoras"
if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Force -Path $backupDir | Out-Null }

$date = Get-Date -Format "yyyyMMdd"
$backupFile = Join-Path $backupDir "bitacoras_$date.csv"

if (Test-Path "data\runeforge.db") {
    # Usar sqlite3.exe de scripts/bin si existe, o el del sistema
    $sqlite = Get-Command sqlite3 -ErrorAction SilentlyContinue
    if (-not $sqlite) {
        $sqlite = Get-ChildItem -Path "scripts\bin\sqlite3.exe" -ErrorAction SilentlyContinue
        if ($sqlite) { $sqlite = $sqlite.FullName }
    }
    if ($sqlite) {
        & $sqlite data\runeforge.db ".headers on" ".mode csv" ".output $backupFile" "SELECT * FROM bitacoras_v2;" ".quit"
        Write-Host "Backup guardado en $backupFile" -ForegroundColor Green
    } else {
        Write-Host "sqlite3 no encontrado, no se pudo hacer backup." -ForegroundColor Yellow
    }
} else {
    Write-Host "No se encontró runeforge.db" -ForegroundColor Yellow
}
