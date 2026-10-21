# ============================================
# RUNEFORGE - USB PAYLOAD CREATOR V3
# ============================================
$ErrorActionPreference = 'Continue'
$capture = New-Object System.Collections.ArrayList

function Log {
    param([string]$m)
    Write-Host $m
    [void]$capture.Add($m)
}

Log "==============================================="
Log " RUNEFORGE - USB PAYLOAD CREATOR V3 (API)"
Log "==============================================="

$usbDrive = "F:\"
if (-not (Test-Path $usbDrive)) {
    Log "[-] La unidad $usbDrive no está conectada."
    $capture | Set-Clipboard
    return
}

$apkFolder = Join-Path $usbDrive "RUNEFORGE_APKS"
New-Item -ItemType Directory -Force -Path $apkFolder | Out-Null

$headers = @{ "User-Agent" = "RUNEFORGE-AUTOMATION" }
$repos = @(
    @{ Name = "FLauncher"; Owner = "elfhosted"; Repo = "FLauncher" },
    @{ Name = "SmartTube"; Owner = "yuliskov"; Repo = "SmartTube" }
)

$successCount = 0

foreach ($item in $repos) {
    $apiUrl = "https://api.github.com/repos/$($item.Owner)/$($item.Repo)/releases/latest"
    Log "[*] Consultando API de GitHub para $($item.Name)..."
    
    try {
        $release = Invoke-RestMethod -Uri $apiUrl -Headers $headers -ErrorAction Stop
        
        # Filtrar el primer .apk que NO sea beta
        $asset = $release.assets | Where-Object { 
            $_.name -like "*.apk" -and $_.name -notlike "*beta*" 
        } | Select-Object -First 1
        
        if (-not $asset) {
            Log "    [-] No se encontró un APK estable en los assets."
            continue
        }

        $dest = Join-Path $apkFolder $asset.name
        Log "    [+] Descargando $($asset.name) ($([math]::Round($asset.size / 1MB, 2)) MB)..."
        
        Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $dest -UseBasicParsing -ErrorAction Stop
        Log "    [+] Guardado exitosamente."
        $successCount++
    } catch {
        Log "    [-] Error al procesar $($item.Name): $_"
    }
}

Log "==============================================="
Log " VERIFICACIÓN FINAL"
Log "==============================================="
if ($successCount -eq 2) {
    Log "[OK] Los 2 APKs fueron descargados y verificados en la USB."
} else {
    Log "[WARN] Solo se descargaron $successCount de 2 APKs."
}

$capture | Set-Clipboard
Log "[OK] Reporte copiado al portapapeles (Ctrl+V)."
