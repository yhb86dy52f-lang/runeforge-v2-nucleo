# RUNEFORGE APPLY ARCHIVE DUPLICATES CLEAN V2
# Requiere revisión manual previa.
$ManifestPath="C:\RUNEFOGE_PRO\runeforge\data\audits\archive_manifest_20260427_023023\archive_manifest_CLEAN_V2.csv"
$rows=Import-Csv -LiteralPath $ManifestPath
foreach($r in $rows){
    if(-not(Test-Path -LiteralPath $r.Source)){continue}
    $destDir=Split-Path $r.Destination -Parent
    New-Item -ItemType Directory -Force -Path $destDir | Out-Null
    Move-Item -LiteralPath $r.Source -Destination $r.Destination -Force
}
Write-Host "[OK] Archivado CLEAN V2 aplicado." -ForegroundColor Green
