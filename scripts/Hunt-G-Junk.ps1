$ErrorActionPreference = 'Continue'
$capture = New-Object System.Collections.ArrayList
function Log($m){ [void]$capture.Add($m); Write-Host $m }

Log "=== CAZA DE MILLONES DE ARCHIVOS EN DISCO G: ==="
Log "Esto escaneará G: ignorando la carpeta de Steam para ir rápido..."

$patterns = @('node_modules', 'venv', '__pycache__', '.cache', '.git', 'temp', 'build', 'dist')
$foundDirs = @()

foreach ($pattern in $patterns) {
    Log "`nBuscando carpetas '$pattern'..."
    # Buscar en G:\ excluyendo SteamLibrary
    $dirs = Get-ChildItem -Path 'G:\' -Filter $pattern -Directory -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch 'SteamLibrary' }
    
    foreach ($d in $dirs) {
        $files = Get-ChildItem -Path $d.FullName -Recurse -File -Force -ErrorAction SilentlyContinue
        $count = $files.Count
        $sizeMB = [math]::Round(($files | Measure-Object -Property Length -Sum).Sum / 1MB, 2)
        
        if ($count -gt 0) {
            $foundDirs += [PSCustomObject]@{
                Path = $d.FullName
                Files = $count
                SizeMB = $sizeMB
            }
        }
    }
}

if ($foundDirs.Count -eq 0) {
    Log "`nNo se encontraron carpetas de desarrollo basura en G:."
} else {
    Log "`n=== TOP 15 CARPETAS CON MÁS ARCHIVOS BASURA ==="
    $foundDirs | Sort-Object Files -Descending | Select-Object -First 15 | ForEach-Object {
        Log ("    {0,-50} | {1,-8} archivos | {2} MB" -f $_.Path, $_.Files, $_.SizeMB)
    }
    
    $totalFiles = ($foundDirs | Measure-Object -Property Files -Sum).Sum
    $totalMB = ($foundDirs | Measure-Object -Property SizeMB -Sum).Sum
    Log "`n[RESUMEN] En total hay $totalFiles archivos basura ocupando $([math]::Round($totalMB/1024, 2)) GB."
}

Log "`n=== FINALIZADO ==="
$capture | Set-Clipboard
