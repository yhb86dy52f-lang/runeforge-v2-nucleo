param([int]$Port = 3100)
$ErrorActionPreference = 'Stop'
$App = 'C:\RUNEFOGE_PRO\runeforge\app'
$PidFile = 'C:\RUNEFOGE_PRO\runeforge\scripts\backend\backend.pid'
$PortFile = 'C:\RUNEFOGE_PRO\runeforge\scripts\backend\backend.port'
$OutLog = 'C:\RUNEFOGE_PRO\runeforge\app\backend.out.log'
$ErrLog = 'C:\RUNEFOGE_PRO\runeforge\app\backend.err.log'

Set-Location $App

if (-not (Test-Path '.\node_modules')) {
  npm install | Out-Null
}

if (Test-Path $OutLog) { Remove-Item $OutLog -Force -ErrorAction SilentlyContinue }
if (Test-Path $ErrLog) { Remove-Item $ErrLog -Force -ErrorAction SilentlyContinue }

Start-Process -FilePath 'cmd.exe' -ArgumentList '/c','npm run start' -WorkingDirectory $App -RedirectStandardOutput $OutLog -RedirectStandardError $ErrLog -WindowStyle Hidden | Out-Null

Start-Sleep -Seconds 6

$listener = Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $listener) {
  Write-Host 'FALLO_BACKEND_INICIAR'
  Write-Host "OUT=$OutLog"
  Write-Host "ERR=$ErrLog"
  exit 1
}

$listener.OwningProcess | Set-Content $PidFile -Encoding ascii
$Port | Set-Content $PortFile -Encoding ascii

Write-Host 'OK_BACKEND_INICIADO'
Write-Host "PID=$($listener.OwningProcess)"
Write-Host "PORT=$Port"
Write-Host "OUT=$OutLog"
Write-Host "ERR=$ErrLog"
