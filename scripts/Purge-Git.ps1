$ErrorActionPreference = 'Continue'
$capture = New-Object System.Collections.ArrayList
function Log($m){ [void]$capture.Add($m); Write-Host $m }

Log "=== PURGA DE .GIT Y BUSQUEDA RAPIDA ==="
$sw = [System.Diagnostics.Stopwatch]::StartNew()

# 1. Eliminar carpetas .git
$gitPaths = @(
    'C:\RUNEFORGE_V2_CORE\.git',
    'C:\RUNEFORGE_V2_CORE\apps\launcher\GameWave\apps\SuperRetroIdLauncher\.git',
    'C:\RUNEFORGE_V2_CORE\apps\optimizers\Open-Frame-gen\.git',
    'C:\RUNEFORGE_V2_CORE\runforge-v2-nucleo\simulador\.git'
)

Log "`n[1] Eliminando repositorios .git ocultos..."
foreach ($p in $gitPaths) {
    if (Test-Path $p) {
        # Forzar la eliminacion de archivos de solo lectura dentro de .git
        Get-ChildItem -Path $p -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object { $_.Attributes = 'Normal' }
        Remove-Item -Path $p -Recurse -Force -ErrorAction SilentlyContinue
        Log "    [OK] Eliminado: $p"
    } else {
        Log "    [-] No encontrado (ya borrado): $p"
    }
}

# 2. Búsqueda rápida de VMDK (solo en carpetas de usuario y VirtualBox/VMware)
Log "`n[2] Buscando Maquinas Virtuales (VMDK) en carpetas comunes..."
$vmFolders = @("$env:USERPROFILE\Documents", "$env:USERPROFILE\VirtualBox VMs", "C:\Users\Public\Documents")
foreach ($vf in $vmFolders) {
    if (Test-Path $vf) {
        $vms = Get-ChildItem -Path $vf -Filter *.vmdk -Recurse -File -ErrorAction SilentlyContinue
        foreach ($vm in $vms) {
            Log ("    Encontrado: {0} GB -> {1}" -f [math]::Round(($vm.Length/1GB), 2), $vm.FullName)
        }
    }
}

# 3. Archivos multimedia masivos
Log "`n[3] Top 5 archivos MP4/MP3 mas grandes (para mover a otro disco):"
$media = Get-ChildItem -Path "$env:USERPROFILE" -Include *.mp4, *.mp3 -Recurse -File -ErrorAction SilentlyContinue | Sort-Object Length -Descending | Select-Object -First 5
foreach ($m in $media) {
    Log ("    {0} GB -> {1}" -f [math]::Round(($m.Length/1GB), 2), $m.FullName)
}

$sw.Stop()
Log "`n=== FINALIZADO en $([math]::Round($sw.Elapsed.TotalSeconds, 1)) segundos ==="
Log "Espacio libre actual en C: $([math]::Round((Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'").FreeSpace / 1GB, 2)) GB"
$capture | Set-Clipboard
