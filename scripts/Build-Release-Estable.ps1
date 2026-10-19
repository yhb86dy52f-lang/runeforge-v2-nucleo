# C:\RUNEFORGE_V2_CORE\scripts\Build-Release-Estable.ps1
# RUNEFORGE V2 CORE - BUILD ESTABLE RELEASE
# Opcion mas estable: cargo build --release (exe optimizado 10-15 MB)
# Usa sccache (43.68% hits) - Tiempo: 60-120s primera vez, luego 10-20s
# Genera exe en target\release y accesos en Escritorio

[CmdletBinding()]
param(
    [string[]]$Apps = @("dictate-studio-v2","dictate-studio","nexus-lab","openwash-real","openwash-real-v2","opt-verify","panel-relevadores","sms-hub-hmi"),
    [switch]$All,
    [switch]$OnlyFirst
)

Set-Location "C:\RUNEFORGE_V2_CORE"
$ErrorActionPreference = "Continue"
$release = "C:\RUNEFORGE_V2_CORE\target\release"
$desktop = [Environment]::GetFolderPath("Desktop")

if ($OnlyFirst) { $Apps = @($Apps[0]) }

Write-Host "=== BUILD ESTABLE RELEASE - RUNEFORGE ===" -ForegroundColor Cyan
Write-Host "Ruta: C:\RUNEFORGE_V2_CORE" -ForegroundColor Gray
Write-Host "Destino: $release" -ForegroundColor Gray
Write-Host "Apps: $($Apps -join ', ')" -ForegroundColor Gray
Write-Host ""
sccache --show-stats
Write-Host ""

$ok = @()
$fail = @()

foreach ($name in $Apps) {
    Write-Host "[BUILD] $name --release" -ForegroundColor Yellow
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    cargo build --release -p $name 2>&1 | ForEach-Object { Write-Host $_ }
    $sw.Stop()
    
    $exe = Join-Path $release "$name.exe"
    if (Test-Path $exe) {
        $mb = [math]::Round((Get-Item $exe).Length / 1MB, 2)
        Write-Host "[OK] $name -> $mb MB en $($sw.Elapsed.TotalSeconds.ToString('0.0'))s" -ForegroundColor Green
        $ok += "$name ($mb MB)"
        
        # Crear acceso directo en Escritorio
        try {
            $shell = New-Object -COM WScript.Shell
            $lnk = Join-Path $desktop "$name.lnk"
            if (Test-Path $lnk) { Remove-Item $lnk -Force }
            $sc = $shell.CreateShortcut($lnk)
            $sc.TargetPath = $exe
            $sc.WorkingDirectory = $release
            $sc.Description = "$name - RUNEFORGE RELEASE"
            $sc.Save()
            Write-Host "  -> Acceso creado: $lnk" -ForegroundColor DarkGray
        } catch {
            Write-Host "  [WARN] No se pudo crear acceso: $_" -ForegroundColor Yellow
        }
    } else {
        Write-Host "[FAIL] $name no genero exe" -ForegroundColor Red
        $fail += $name
    }
    Write-Host ""
}

Write-Host "=== RESUMEN ===" -ForegroundColor Cyan
Write-Host "OK ($($ok.Count)): $($ok -join ', ')" -ForegroundColor Green
if ($fail.Count -gt 0) { 
    Write-Host "FAIL ($($fail.Count)): $($fail -join ', ')" -ForegroundColor Red
    Write-Host "Para esos: cargo build --release -p <nombre> --verbose" -ForegroundColor Yellow
}

Write-Host ""
sccache --show-stats
Write-Host ""
Write-Host "Abriendo carpetas..." -ForegroundColor Gray
if (Test-Path $release) { explorer.exe $release }
explorer.exe $desktop

Write-Host "`nListo. Exe optimizados en target\release + accesos en Escritorio." -ForegroundColor Cyan
Write-Host "Uso: .\scripts\Build-Release-Estable.ps1  |  .\scripts\Build-Release-Estable.ps1 -OnlyFirst  |  .\scripts\Build-Release-Estable.ps1 -Apps @('nexus-lab')" -ForegroundColor DarkGray
