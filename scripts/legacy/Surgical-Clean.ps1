$ErrorActionPreference = 'Continue'
$capture = New-Object System.Collections.ArrayList
function Log($m){ [void]$capture.Add($m); Write-Host $m }

Log "=== CIRUGÍA DE ESPACIO ==="
$sw = [System.Diagnostics.Stopwatch]::StartNew()

# 1. Vaciado de Papelera (libera 5.2 GB)
Log "`n[1] Vaciando Papelera de Reciclaje..."
Clear-RecycleBin -Force -ErrorAction SilentlyContinue
Log "    [OK] Papelera vaciada."

# 2. Limpieza de Logs masivos en RUNEFORGE
Log "`n[2] Buscando y eliminando archivos .log mayores a 100 MB..."
$logs = Get-ChildItem -Path 'C:\RUNEFORGE_V2_CORE' -Filter *.log -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { $_.Length -gt 100MB }
$logSize = 0
foreach ($l in $logs) {
    $logSize += $l.Length
    Remove-Item -Path $l.FullName -Force -ErrorAction SilentlyContinue
}
Log "    [OK] Se eliminaron $($logs.Count) archivos log, liberando $([math]::Round(($logSize / 1GB), 2)) GB."

# 3. Localizar el .git de 44 GB
Log "`n[3] LOCALIZANDO CARPETA .GIT MASIVA:"
$gitFolders = Get-ChildItem -Path 'C:\RUNEFORGE_V2_CORE' -Filter '.git' -Directory -Recurse -Force -ErrorAction SilentlyContinue
if ($gitFolders) {
    foreach ($git in $gitFolders) {
        Log "    ¡ALERTA! Encontrado en: $($git.FullName)"
        Log "    (Si no estás usando Git para control de versiones aquí, puedes borrarla con: Remove-Item -Recurse -Force '$($git.FullName)')"
    }
} else {
    Log "    No se encontró carpeta .git directa en el primer nivel."
}

# 4. Localizar las Máquinas Virtuales (.vmdk)
Log "`n[4] LOCALIZANDO MÁQUINAS VIRTUALES (.vmdk):"
$vmFiles = Get-ChildItem -Path 'C:\' -Filter *.vmdk -Recurse -File -Force -ErrorAction SilentlyContinue
foreach ($vm in $vmFiles) {
    Log ("    {0} GB -> {1}" -f [math]::Round(($vm.Length/1GB), 2), $vm.FullName)
}

# 5. Escanear carpetas de usuario (Downloads, Desktop, Documents)
Log "`n[5] TOP 5 ARCHIVOS MÁS GRANDES EN TUS CARPETAS PERSONALES:"
$userFolders = @("$env:USERPROFILE\Downloads", "$env:USERPROFILE\Desktop", "$env:USERPROFILE\Documents")
foreach ($uf in $userFolders) {
    if (Test-Path $uf) {
        Log "    --- $uf ---"
        Get-ChildItem -Path $uf -File -Force -ErrorAction SilentlyContinue | Sort-Object Length -Descending | Select-Object -First 5 | ForEach-Object {
            if ($_.Length -gt 50MB) { Log ("      {0} GB -> {1}" -f [math]::Round(($_.Length/1GB), 2), $_.Name) }
        }
    }
}

$sw.Stop()
Log "`n=== FINALIZADO en $([math]::Round($sw.Elapsed.TotalSeconds, 1)) segundos ==="
$capture | Set-Clipboard
