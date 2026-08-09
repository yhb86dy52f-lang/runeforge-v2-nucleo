Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$AhkPath = "C:\RUNEFOGE_PRO\runeforge\scripts\ahk\RUNEFORGE_COMMANDER_V42_EXPORT_BRIDGE.ahk"
$AhkExe = "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"

if (-not (Test-Path -LiteralPath $AhkPath)) {
    throw "No existe panel AHK: $AhkPath"
}

if (-not (Test-Path -LiteralPath $AhkExe)) {
    throw "No existe AutoHotkey: $AhkExe"
}

Start-Process -FilePath $AhkExe -ArgumentList ""$AhkPath""
Write-Host "[OK] Runeforge Commander V42 iniciado: $AhkPath" -ForegroundColor Green
