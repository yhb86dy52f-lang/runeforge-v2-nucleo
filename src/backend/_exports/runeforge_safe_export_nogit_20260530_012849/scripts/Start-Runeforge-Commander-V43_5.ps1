Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Fecha = "2026-04-24"
$Root = "C:\RUNEFOGE_PRO\runeforge"
$AhkExe = "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
$PanelAhk = "C:\RUNEFOGE_PRO\runeforge\scripts\ahk\RUNEFORGE_COMMANDER_V43_5_CLEAN_OPS_FUSION.ahk"

if (-not (Test-Path -LiteralPath $Root)) {
    throw "No existe raíz Runeforge: $Root"
}

if (-not (Test-Path -LiteralPath $AhkExe)) {
    throw "No existe AutoHotkey: $AhkExe"
}

if (-not (Test-Path -LiteralPath $PanelAhk)) {
    throw "No existe panel V43.5: $PanelAhk"
}

Start-Process -FilePath $AhkExe -ArgumentList ('"{0}"' -f $PanelAhk) -WorkingDirectory $Root

Write-Host "[OK] RUNEFORGE COMMANDER V43.5 iniciado." -ForegroundColor Green
Write-Host "Fecha: $Fecha" -ForegroundColor Cyan
Write-Host "Panel: $PanelAhk" -ForegroundColor Cyan
