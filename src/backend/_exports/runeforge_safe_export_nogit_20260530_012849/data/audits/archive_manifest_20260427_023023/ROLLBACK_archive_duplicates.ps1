# RUNEFORGE ROLLBACK ARCHIVE DUPLICATES
# Generado: 2026-04-27 02:30:35
# Acción: devolver archivos movidos según manifest.

$ManifestPath="C:\RUNEFOGE_PRO\runeforge\data\audits\archive_manifest_20260427_023023\archive_manifest.csv"
$rows=Import-Csv -LiteralPath $ManifestPath
foreach($r in ($rows | Sort-Object Source -Descending)){
    if(-not (Test-Path -LiteralPath $r.Destination)){ continue }
    $srcDir=Split-Path $r.Source -Parent
    New-Item -ItemType Directory -Force -Path $srcDir | Out-Null
    Move-Item -LiteralPath $r.Destination -Destination $r.Source -Force
}
Write-Host "[OK] Rollback aplicado desde manifest: $ManifestPath" -ForegroundColor Yellow
