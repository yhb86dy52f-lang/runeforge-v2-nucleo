# RUNEFORGE ROLLBACK ARCHIVE DUPLICATES CLEAN V2
$ManifestPath="C:\RUNEFOGE_PRO\runeforge\data\audits\archive_manifest_20260427_023023\archive_manifest_CLEAN_V2.csv"
$rows=Import-Csv -LiteralPath $ManifestPath
foreach($r in ($rows | Sort-Object Source -Descending)){
    if(-not(Test-Path -LiteralPath $r.Destination)){continue}
    $srcDir=Split-Path $r.Source -Parent
    New-Item -ItemType Directory -Force -Path $srcDir | Out-Null
    Move-Item -LiteralPath $r.Destination -Destination $r.Source -Force
}
Write-Host "[OK] Rollback CLEAN V2 aplicado." -ForegroundColor Yellow
