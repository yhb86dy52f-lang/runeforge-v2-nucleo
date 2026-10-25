$ErrorActionPreference = 'Continue'
$capture = New-Object System.Collections.ArrayList
function Log($m){ [void]$capture.Add($m); Write-Host $m }

Log "=== INICIANDO MANTENIMIENTO RUNEFORGE ==="
$sw = [System.Diagnostics.Stopwatch]::StartNew()

# 1. Vaciado de Papeleras
Log "[1] Vaciando Papeleras de Reciclaje (C y G)..."
Clear-RecycleBin -DriveLetter C -Force -ErrorAction SilentlyContinue
Clear-RecycleBin -DriveLetter G -Force -ErrorAction SilentlyContinue
Log "    [OK] Papeleras vaciadas."

# 2. Temporales
Log "`n[2] Limpiando carpetas temporales..."
Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
Log "    [OK] Temporales eliminados."

# 3. Logs viejos en RUNEFORGE
Log "`n[3] Eliminando logs mayores a 50 MB en RUNEFORGE..."
$logs = Get-ChildItem -Path 'C:\RUNEFORGE_V2_CORE' -Filter *.log -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { $_.Length -gt 50MB }
foreach ($l in $logs) { Remove-Item -Path $l.FullName -Force -ErrorAction SilentlyContinue }
Log "    [OK] Se eliminaron $($logs.Count) logs masivos."

$sw.Stop()
Log "`n=== MANTENIMIENTO FINALIZADO en $([math]::Round($sw.Elapsed.TotalSeconds, 1)) segundos ==="
Log "Espacio libre actual:"
Log "C: $([math]::Round((Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'").FreeSpace / 1GB, 2)) GB"
Log "G: $([math]::Round((Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='G:'").FreeSpace / 1GB, 2)) GB"
$capture | Set-Clipboard
