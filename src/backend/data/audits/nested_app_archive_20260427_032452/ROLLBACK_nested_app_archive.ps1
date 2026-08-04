# RUNEFORGE ROLLBACK NESTED APP ARCHIVE
# Generado: 2026-04-27 03:24:53

$ArchiveTarget="C:\RUNEFOGE_PRO\runeforge\archive\nested_app_legacy_20260427_032452\app"
$NestedApp="C:\RUNEFOGE_PRO\runeforge\runeforge\app"

if(-not(Test-Path -LiteralPath $ArchiveTarget)){
    throw "No existe archivo archivado: $ArchiveTarget"
}

$parent=Split-Path $NestedApp -Parent
New-Item -ItemType Directory -Force -Path $parent | Out-Null
Move-Item -LiteralPath $ArchiveTarget -Destination $NestedApp -Force

Write-Host "[OK] Rollback nested app aplicado." -ForegroundColor Yellow
