$ErrorActionPreference = 'Continue'
$capture = New-Object System.Collections.ArrayList
function Log($m){ [void]$capture.Add($m); Write-Host $m }

$csv = "C:\RUNEFORGE_BIG_FILES_ARCHIVE\DISK C.csv"
if (-not (Test-Path $csv)) { Log "ERROR: CSV no encontrado"; return }

Log "Leyendo CSV de 274 MB (esto puede tardar 1 o 2 minutos)..."
$data = Import-Csv -Path $csv

Log "`n=== TOP 15 CARPETAS MÁS PESADAS ==="
$folders = $data | Where-Object { $_.Nombre -match '^C:\\[^\\]+' -and $_.'Tamaño Lógico' -gt 0 } | ForEach-Object {
    $parts = $_.Nombre -split '\\'
    $folder = if ($parts.Count -ge 2) { "$($parts[0])\$($parts[1])" } else { $parts[0] }
    [PSCustomObject]@{ Name = $folder; Size = [long]$_.'Tamaño Lógico' }
}
$folders | Group-Object Name | ForEach-Object {
    [PSCustomObject]@{ Carpeta = $_.Name; GB = [math]::Round((($_.Group | Measure-Object Size -Sum).Sum / 1GB), 2) }
} | Sort-Object GB -Descending | Select-Object -First 15 | ForEach-Object {
    Log ("{0,-35} {1} GB" -f $_.Carpeta, $_.GB)
}

Log "`n=== TOP 15 EXTENSIONES MÁS PESADAS ==="
$exts = $data | Where-Object { $_.'Tamaño Lógico' -gt 0 } | ForEach-Object {
    $ext = [System.IO.Path]::GetExtension($_.Nombre).ToLower()
    if ([string]::IsNullOrWhiteSpace($ext)) { $ext = "(sin extension)" }
    [PSCustomObject]@{ Extension = $ext; Size = [long]$_.'Tamaño Lógico' }
}
$exts | Group-Object Extension | ForEach-Object {
    [PSCustomObject]@{ Extension = $_.Name; GB = [math]::Round((($_.Group | Measure-Object Size -Sum).Sum / 1GB), 2) }
} | Sort-Object GB -Descending | Select-Object -First 15 | ForEach-Object {
    Log ("{0,-35} {1} GB" -f $_.Extension, $_.GB)
}

Log "`n=== FIN DEL ANALISIS ==="
$capture | Set-Clipboard
