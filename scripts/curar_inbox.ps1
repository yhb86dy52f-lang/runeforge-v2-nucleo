# curar_inbox.ps1 - Wrapper para curar_inbox.js
$ErrorActionPreference="Stop"
$root = $PSScriptRoot; if(-not $root){ $root = (Get-Location).Path }; if($root -like "*\scripts"){ $root = Split-Path $root -Parent }
Set-Location $root
Write-Host "[CURAR] Iniciando curacion de knowledge\00_INBOX (68 archivos)" -ForegroundColor Cyan
node src\backend\curar_inbox.js
Write-Host "[CURAR] Fin" -ForegroundColor Green
