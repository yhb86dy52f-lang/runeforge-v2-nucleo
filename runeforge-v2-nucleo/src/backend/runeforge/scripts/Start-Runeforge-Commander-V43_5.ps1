Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$AhkExe = "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
$AhkPath = "C:\RUNEFOGE_PRO\runeforge\scripts\ahk\RUNEFORGE_COMMANDER_V43_5_CLEAN_OPS_FUSION.ahk"

if (-not (Test-Path -LiteralPath $AhkExe)) {
    throw "No existe AutoHotkey: $AhkExe"
}

if (-not (Test-Path -LiteralPath $AhkPath)) {
    throw "No existe panel: $AhkPath"
}

Start-Process -FilePath $AhkExe -ArgumentList ('"{0}"' -f $AhkPath)

Write-Host "[OK] Runeforge Commander V43.5 iniciado." -ForegroundColor Green
Write-Host $AhkPath -ForegroundColor Cyan
