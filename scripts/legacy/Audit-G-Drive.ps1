$ErrorActionPreference = 'Continue'
$capture = New-Object System.Collections.ArrayList
function Log($m){ [void]$capture.Add($m); Write-Host $m }

Log "=== AUDITORÍA Y SANEAMIENTO DEL DISCO G: ==="
$sw = [System.Diagnostics.Stopwatch]::StartNew()

# 1. Top Juegos en SteamLibrary
Log "`n[1] TOP 15 JUEGOS MÁS PESADOS (G:\SteamLibrary\steamapps\common):"
$steamPath = 'G:\SteamLibrary\steamapps\common'
if (Test-Path $steamPath) {
    Get-ChildItem -Path $steamPath -Directory -Force -ErrorAction SilentlyContinue | ForEach-Object {
        $size = (Get-ChildItem -Path $_.FullName -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        if ($size -gt 1GB) {
            [PSCustomObject]@{ Juego = $_.Name; GB = [math]::Round(($size / 1GB), 2) }
        }
    } | Sort-Object GB -Descending | Select-Object -First 15 | ForEach-Object {
        Log ("    {0,-40} {1} GB" -f $_.Juego, $_.GB)
    }
} else {
    Log "    [AVISO] No se encontró la ruta estándar de Steam en G:"
}

# 2. Archivos comprimidos gigantes (Backups, Zips)
Log "`n[2] ARCHIVOS COMPRIMIDOS MASIVOS (> 1 GB) EN G:"
$zips = Get-ChildItem -Path 'G:\' -Include *.zip, *.rar, *.7z -Recurse -File -Force -ErrorAction SilentlyContinue | Where-Object { $_.Length -gt 1GB }
if ($zips) {
    $totalZip = 0
    foreach ($z in $zips) {
        $gb = [math]::Round(($z.Length / 1GB), 2)
        $totalZip += $gb
        Log ("    {0} GB -> {1}" -f $gb, $z.FullName)
    }
    Log ("    [TOTAL COMPRIMIDOS] {0} GB" -f [math]::Round($totalZip, 2))
} else {
    Log "    No se encontraron comprimidos mayores a 1 GB."
}

$sw.Stop()
Log "`n=== FINALIZADO en $([math]::Round($sw.Elapsed.TotalSeconds, 1)) segundos ==="
$capture | Set-Clipboard
