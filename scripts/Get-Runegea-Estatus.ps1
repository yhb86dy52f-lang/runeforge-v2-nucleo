# Get-Runegea-Estatus.ps1
$Root = "C:\RUNEFORGE_V2_CORE"
Get-ChildItem -Path $Root -Filter "*ESTATUS*.md" -Recurse -Depth 3 -File -ErrorAction SilentlyContinue | Select-Object FullName, Length
$target = Join-Path $Root "ESTATUS.md"
if (Test-Path $target) { Get-Content $target -Raw }
