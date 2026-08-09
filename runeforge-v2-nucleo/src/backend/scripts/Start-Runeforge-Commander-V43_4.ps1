Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$AhkExe = "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
$AhkPath = "C:\RUNEFOGE_PRO\runeforge\scripts\ahk\RUNEFORGE_COMMANDER_V43_4_CLEAN_OPS.ahk"

if (-not (Test-Path -LiteralPath $AhkExe)) {
    throw "No existe AutoHotkey: $AhkExe"
}

if (-not (Test-Path -LiteralPath $AhkPath)) {
    throw "No existe panel: $AhkPath"
}

Start-Process -FilePath $AhkExe -ArgumentList ""$AhkPath""
Write-Host "[OK] Runeforge Commander V43.4 iniciado." -ForegroundColor Green
Write-Host $AhkPath -ForegroundColor Cyan
