$ErrorActionPreference = 'Continue'
$capture = New-Object System.Collections.ArrayList
function Log($m){ [void]$capture.Add($m); Write-Host $m }

Log "=== PURGA DEFINITIVA DE ESCOMBROS (C: Y G:) ==="
$sw = [System.Diagnostics.Stopwatch]::StartNew()

$targets = @(
    'C:\RUNEFORGE_V2_CORE',
    'C:\RUNEFORGE_BACKUPS',
    'G:\Nueva carpeta (3)'
)
$patterns = @('node_modules', 'venv', '__pycache__', 'dist', 'build', '.git')

$totalDeletedFiles = 0
$totalDeletedMB = 0

foreach ($target in $targets) {
    if (-not (Test-Path $target)) { continue }
    Log "`nLimpiando: $target"
    
    foreach ($pattern in $patterns) {
        $found = Get-ChildItem -Path $target -Filter $pattern -Directory -Recurse -Force -ErrorAction SilentlyContinue
        if ($found) {
            $filesCount = 0
            $sizeMB = 0
            
            foreach ($f in $found) {
                # Contar antes de borrar
                $files = Get-ChildItem -Path $f.FullName -Recurse -File -Force -ErrorAction SilentlyContinue
                $filesCount += $files.Count
                $sizeMB += [math]::Round(($files | Measure-Object -Property Length -Sum).Sum / 1MB, 2)
                
                # Borrar (Forzando si hay archivos de solo lectura)
                Remove-Item -Path $f.FullName -Recurse -Force -ErrorAction SilentlyContinue
            }
            
            if ($filesCount -gt 0) {
                Log "  [BORRADO] $($found.Count) carpetas '$pattern' -> $filesCount archivos eliminados ($([math]::Round($sizeMB/1024, 2)) GB)."
                $totalDeletedFiles += $filesCount
                $totalDeletedMB += $sizeMB
            }
        }
    }
}

$sw.Stop()
Log "`n=== RESUMEN DE LIMPIEZA ==="
Log "Archivos basura eliminados en total: $totalDeletedFiles"
Log "Espacio liberado: $([math]::Round($totalDeletedMB/1024, 2)) GB"
Log "Tiempo de limpieza: $([math]::Round($sw.Elapsed.TotalSeconds, 1)) segundos"
Log "`nEspacio libre actual:"
Log "C: $([math]::Round((Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'").FreeSpace / 1GB, 2)) GB"
Log "G: $([math]::Round((Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='G:'").FreeSpace / 1GB, 2)) GB"
$capture | Set-Clipboard
