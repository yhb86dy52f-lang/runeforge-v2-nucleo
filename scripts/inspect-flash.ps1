$ErrorActionPreference = "Continue"
$flash = "C:\RUNEFORGE_V2_CORE\flash.ps1"

Write-Host "=== Lineas con 'esptool' ===" -ForegroundColor Cyan
Select-String -Path $flash -Pattern "esptool" | ForEach-Object {
    Write-Host "  L$($_.LineNumber): $($_.Line.Trim())"
}

Write-Host ""
Write-Host "=== Lineas con 'Arduino15' o 'packages' ===" -ForegroundColor Cyan
Select-String -Path $flash -Pattern "Arduino15|packages" | ForEach-Object {
    Write-Host "  L$($_.LineNumber): $($_.Line.Trim())"
}

Write-Host ""
Write-Host "=== Lineas con 'firmware' o rutas del proyecto ===" -ForegroundColor Cyan
Select-String -Path $flash -Pattern "firmware|RUNEFORGE_COLLAB" | ForEach-Object {
    Write-Host "  L$($_.LineNumber): $($_.Line.Trim())"
}

Write-Host ""
Write-Host "=== Primeras 40 lineas ===" -ForegroundColor Cyan
Get-Content $flash -TotalCount 40 | ForEach-Object { Write-Host "  $_" }