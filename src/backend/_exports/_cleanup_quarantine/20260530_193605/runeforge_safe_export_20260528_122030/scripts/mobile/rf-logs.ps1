param([int]$Lines=40)
$ErrorActionPreference="SilentlyContinue"
Write-Host "[RF_LOGS last=$Lines]" -ForegroundColor Cyan
pm2 logs runeforge --lines $Lines --nostream
pm2 logs runeforge-v2 --lines $Lines --nostream
