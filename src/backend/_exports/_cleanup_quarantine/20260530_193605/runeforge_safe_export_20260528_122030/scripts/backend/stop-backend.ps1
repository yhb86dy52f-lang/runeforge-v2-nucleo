$ErrorActionPreference = 'SilentlyContinue'
$PidFile = 'C:\RUNEFOGE_PRO\runeforge\scripts\backend\backend.pid'

if (-not (Test-Path $PidFile)) {
  Write-Host 'SIN_PID_FILE'
  exit 0
}

$pidValue = Get-Content $PidFile -ErrorAction SilentlyContinue
if ($pidValue -and (Get-Process -Id $pidValue -ErrorAction SilentlyContinue)) {
  Stop-Process -Id $pidValue -Force
  Write-Host "OK_BACKEND_DETENIDO PID=$pidValue"
} else {
  Write-Host 'SIN_PROCESO_ACTIVO'
}

Remove-Item $PidFile -Force -ErrorAction SilentlyContinue
