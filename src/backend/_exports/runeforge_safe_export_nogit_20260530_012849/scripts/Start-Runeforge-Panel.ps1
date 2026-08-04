param(
    [ValidateSet("Full","Quick")]
    [string]$Mode = "Full"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Fecha = "2026-04-24"
$Root = "C:\RUNEFOGE_PRO\runeforge"
$AhkExe = "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
$FullPanel = "C:\RUNEFOGE_PRO\runeforge\scripts\ahk\RUNEFORGE_COMMANDER_V43_5_CLEAN_OPS_FUSION.ahk"
$QuickPanel = "C:\RUNEFOGE_PRO\runeforge\scripts\ahk\RUNEFORGE_COMMANDER_V43_6_QUICK_DOCK.ahk"

if (-not (Test-Path -LiteralPath $Root)) {
    throw "No existe raíz Runeforge: $Root"
}

if (-not (Test-Path -LiteralPath $AhkExe)) {
    throw "No existe AutoHotkey: $AhkExe"
}

$PanelAhk = if ($Mode -eq "Quick") { $QuickPanel } else { $FullPanel }

if (-not (Test-Path -LiteralPath $PanelAhk)) {
    throw "No existe panel solicitado: $PanelAhk"
}

Start-Process -FilePath $AhkExe -ArgumentList ('"{0}"' -f $PanelAhk) -WorkingDirectory $Root

Write-Host "[OK] RUNEFORGE PANEL iniciado." -ForegroundColor Green
Write-Host "Fecha: $Fecha" -ForegroundColor Cyan
Write-Host "Modo:  $Mode" -ForegroundColor Cyan
Write-Host "Panel: $PanelAhk" -ForegroundColor Cyan
