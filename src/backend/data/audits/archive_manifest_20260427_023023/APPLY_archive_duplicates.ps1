# RUNEFORGE APPLY ARCHIVE DUPLICATES
# Generado: 2026-04-27 02:30:35
# Acción: mover SOLO candidatos del manifest.
# Requiere revisión manual previa.

$ManifestPath="C:\RUNEFOGE_PRO\runeforge\data\audits\archive_manifest_20260427_023023\archive_manifest.csv"
$rows=Import-Csv -LiteralPath $ManifestPath
foreach($r in $rows){
    if(-not (Test-Path -LiteralPath $r.Source)){ continue }
    $destDir=Split-Path $r.Destination -Parent
    New-Item -ItemType Directory -Force -Path $destDir | Out-Null
    Move-Item -LiteralPath $r.Source -Destination $r.Destination -Force
}
Write-Host "[OK] Archivado aplicado desde manifest: $ManifestPath" -ForegroundColor Green
