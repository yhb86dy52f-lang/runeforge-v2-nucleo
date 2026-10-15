param([Parameter(Mandatory=$true)][string]$Name)

$paths = @(
    "C:\RUNEFORGE_V2_CORE\target\release\$Name.exe",
    "C:\RUNEFORGE_V2_CORE\.cargo-target\release\$Name.exe",
    "C:\RUNEFORGE_V2_CORE\apps\$Name\src-tauri\target\release\$Name.exe"
)

$exe = $null
foreach ($p in $paths) { if (Test-Path $p) { $exe = $p; break } }

if (-not $exe) {
    Write-Host "[X] No existe .exe para '$Name'" -ForegroundColor Red
    Write-Host "    Ubicaciones probadas:" -ForegroundColor Yellow
    $paths | ForEach-Object { Write-Host "      $_" -ForegroundColor DarkGray }
    exit 1
}

$mb = [math]::Round((Get-Item $exe).Length/1MB, 2)
Write-Host "[RUNEFORGE] Lanzando $Name ($mb MB)..." -ForegroundColor Cyan
Start-Process $exe