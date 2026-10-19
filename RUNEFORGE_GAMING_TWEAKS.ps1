# =====================================================================
# RUNEFORGE_GAMING_TWEAKS.ps1
# 1. Encuentra TODOS los juegos en ambas librerias Steam (C y G)
# 2. Desactiva Game DVR (recupera rendimiento)
# 3. Activa Game Mode
# 4. Reporta estado final para configurar Lossless Scaling
# =====================================================================

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

$Buf = New-Object System.Collections.Generic.List[string]
function W($m) { $Buf.Add([string]$m) | Out-Null; Write-Host $m }

W "==================================================================="
W " RUNEFORGE · GAMING TWEAKS · $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
W "==================================================================="

# ---------- 1. Enumerar AMBAS librerias Steam ----------
W "`n[1] Juegos instalados en TODAS las librerias Steam"
$libs = @(
    "C:\Program Files (x86)\Steam\steamapps\common",
    "G:\SteamLibrary\steamapps\common"
)
$allGames = @()
foreach ($lib in $libs) {
    if (Test-Path $lib) {
        $games = Get-ChildItem $lib -Directory -ErrorAction SilentlyContinue | Where-Object {
            $_.Name -ne 'Steamworks Shared'
        }
        W "`n    Libreria: $lib"
        W "    Juegos: $($games.Count)"
        foreach ($g in $games) {
            # Buscar ejecutable principal y tamaño
            $exes = Get-ChildItem $g.FullName -Recurse -Filter "*.exe" -ErrorAction SilentlyContinue -Depth 3 |
                    Where-Object { $_.Length -gt 1MB } |
                    Sort-Object Length -Descending |
                    Select-Object -First 1
            $size = 0
            try { $size = (Get-ChildItem $g.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum } catch {}
            $sizeGB = [math]::Round($size / 1GB, 2)
            $exeName = if ($exes) { $exes.Name } else { "(sin exe)" }
            $allGames += [PSCustomObject]@{
                Name  = $g.Name
                Size  = $sizeGB
                Exe   = $exeName
                Path  = $g.FullName
            }
        }
    }
}

W "`n    --- TODOS LOS JUEGOS (ordenados por tamaño) ---"
$allGames | Sort-Object Size -Descending | ForEach-Object {
    W "    [$('{0,7:N2}' -f $_.Size) GB]  $($_.Name)"
    W "              exe: $($_.Exe)"
}
W ""

# ---------- 2. Identificar Shadow of War especificamente ----------
W "`n[2] Búsqueda específica: Middle-earth Shadow of War"
$sow = $allGames | Where-Object { $_.Name -match 'Shadow of War|Middle' }
if ($sow) {
    foreach ($g in $sow) {
        W "    ENCONTRADO: $($g.Name)"
        W "    Ruta: $($g.Path)"
        W "    Exe:  $($g.Exe)"
        W "    Tamaño: $($g.Size) GB"
        # Listar exes candidatos
        W "    Candidatos a exe principal:"
        Get-ChildItem $g.Path -Recurse -Filter "*.exe" -ErrorAction SilentlyContinue -Depth 3 |
            Where-Object { $_.Length -gt 5MB } |
            Sort-Object Length -Descending |
            Select-Object -First 5 |
            ForEach-Object { W "      $([math]::Round($_.Length/1MB,1))MB  $($_.FullName)" }
    }
} else {
    W "    NO encontrado en C: ni G:"
}
W ""

# ---------- 3. Aplicar tweaks Windows ----------
W "`n[3] Tweaks de Windows para juegos"

# Game DVR OFF (recupera FPS)
$dvrKey = "HKCU:\System\GameConfigStore"
Set-ItemProperty -Path $dvrKey -Name "GameDVR_Enabled" -Value 0 -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $dvrKey -Name "GameDVR_FSEBehaviorMode" -Value 2 -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $dvrKey -Name "GameDVR_HonorUserFSEBehaviorMode" -Value 1 -Force -ErrorAction SilentlyContinue
W "    Game DVR: DESACTIVADO"

# Game Bar tips off
$gbKey = "HKCU:\Software\Microsoft\GameBar"
Set-ItemProperty -Path $gbKey -Name "UseNexusForGameBarEnabled" -Value 0 -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $gbKey -Name "ShowStartupPanel" -Value 0 -Force -ErrorAction SilentlyContinue
W "    Game Bar: tips desactivados"

# Game Mode ON
Set-ItemProperty -Path $gbKey -Name "AllowAutoGameMode" -Value 1 -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $gbKey -Name "AutoGameModeEnabled" -Value 1 -Force -ErrorAction SilentlyContinue
W "    Game Mode: HABILITADO"

# Desactivar capturas en segundo plano
$capKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR"
Set-ItemProperty -Path $capKey -Name "AppCaptureEnabled" -Value 0 -Force -ErrorAction SilentlyContinue
W "    Capturas background: DESACTIVADAS"

# Prioridad de juegos en el scheduler
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" -Name "GPU Priority" -Value 8 -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" -Name "Priority" -Value 6 -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" -Name "Scheduling Category" -Value "High" -Force -ErrorAction SilentlyContinue
W "    Prioridad GPU/CPU para juegos: ALTA"

W ""
W "    (Requiere reinicio para aplicar del todo)"
W ""

# ---------- 4. Verificacion ----------
W "`n[4] Verificacion post-tweaks"
$dvr = (Get-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -ErrorAction SilentlyContinue).GameDVR_Enabled
W "    Game DVR_Enabled: $dvr  (0 = desactivado)"
$gm = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AllowAutoGameMode" -ErrorAction SilentlyContinue).AllowAutoGameMode
W "    AllowAutoGameMode: $gm  (1 = activado)"
W ""

# ---------- 5. Ubicacion Lossless Scaling ----------
W "`n[5] Lossless Scaling"
$lsl = "C:\Program Files (x86)\Steam\steamapps\common\Lossless Scaling\LosslessScaling.exe"
if (Test-Path $lsl) {
    W "    OK: $lsl"
    $v = (Get-Item $lsl).VersionInfo.FileVersion
    W "    Version: $v"
}
W ""

# ---------- 6. Resumen para siguiente fase ----------
W "`n==================================================================="
W " RESUMEN PARA CONFIGURAR LOSSLESS SCALING"
W "==================================================================="
W " Monitor principal:  1920x1080"
W " Monitor secundario: 1228x690"
W " GPU: GTX 1660 SUPER (target: 1080p nativo)"
W " CPU: Ryzen 3 3200G (4c/4t)"
W ""
if ($sow) {
    $target = $sow | Select-Object -First 1
    W " Juego objetivo: $($target.Name)"
    W " Ruta: $($target.Path)"
} else {
    W " Juego objetivo: (a definir)"
}
W ""
W " Siguiente paso: configurar Lossless Scaling con valores para 1080p"
W "==================================================================="

Set-Clipboard -Value ($Buf -join "`r`n")
Write-Host "`n[OK] Salida copiada al portapapeles."