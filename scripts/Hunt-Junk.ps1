$ErrorActionPreference = 'Continue'
$capture = New-Object System.Collections.ArrayList
function Log($m){ [void]$capture.Add($m); Write-Host $m }

Log "=== CAZA DE ESCOMBROS EN RUNEFORGE ==="
$sw = [System.Diagnostics.Stopwatch]::StartNew()

$targets = @(
    'C:\RUNEFORGE_V2_CORE',
    'C:\RUNEFORGE_BIG_FILES_ARCHIVE',
    'C:\RUNEFORGE_BACKUPS'
)

$patterns = @('node_modules', 'venv', '__pycache__', '.cache', 'temp', 'logs', 'dist', 'build')

foreach ($target in $targets) {
    if (-not (Test-Path $target)) { continue }
    Log "`nEscaneando: $target"
    
    foreach ($pattern in $patterns) {
        $found = Get-ChildItem -Path $target -Filter $pattern -Directory -Recurse -Force -ErrorAction SilentlyContinue
        if ($found) {
            $totalFiles = 0
            $totalSize = 0
            $paths = @()
            
            foreach ($f in $found) {
                $totalFiles += (Get-ChildItem -Path $f.FullName -Recurse -File -Force -ErrorAction SilentlyContinue).Count
                $totalSize += (Get-ChildItem -Path $f.FullName -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                $paths += $f.FullName
            }
            
            if ($totalSize -gt 10MB) {
                Log "  [ALERTA] Encontradas $($found.Count) carpetas '$pattern':"
                Log "     Archivos basura: $totalFiles"
                Log "     Peso total: $([math]::Round(($totalSize / 1MB), 2)) MB"
                $paths | Select-Object -First 3 | ForEach-Object { Log "     -> $_" }
                if ($paths.Count -gt 3) { Log "     -> (y $($paths.Count - 3) mas...)" }
            }
        }
    }
}

$sw.Stop()
Log "`n=== FINALIZADO en $([math]::Round($sw.Elapsed.TotalSeconds, 1)) segundos ==="
$capture | Set-Clipboard
