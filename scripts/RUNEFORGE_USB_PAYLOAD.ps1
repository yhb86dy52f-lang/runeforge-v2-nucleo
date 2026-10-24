# ============================================
# RUNEFORGE - USB PAYLOAD CREATOR
# ============================================
$ErrorActionPreference = 'Continue'
$capture = New-Object System.Collections.ArrayList

function Log {
    param([string]$m)
    Write-Host $m
    [void]$capture.Add($m)
}

Log "==============================================="
Log " RUNEFORGE - USB PAYLOAD CREATOR"
Log "==============================================="

# 1. Verificar la unidad USB
$usbDrive = "F:\"
if (-not (Test-Path $usbDrive)) {
    Log "[-] La unidad $usbDrive no está conectada o no existe."
    Log "[!] Conecta la memoria SMART_USB y vuelve a ejecutar."
    $capture | Set-Clipboard
    return
}

$apkFolder = Join-Path $usbDrive "RUNEFORGE_APKS"
if (-not (Test-Path $apkFolder)) {
    New-Item -ItemType Directory -Path $apkFolder | Out-Null
}
Log "[+] Carpeta creada: $apkFolder"

# 2. Descargar APKs desde GitHub (Fuentes confiables de código abierto)
$downloads = @(
    @{
        Name = "FLauncher (Launcher Libre)";
        Url = "https://github.com/elfhosted/FLauncher/releases/latest/download/app-release.apk";
        File = "FLauncher.apk"
    },
    @{
        Name = "SmartTube (YouTube Sin Anuncios)";
        Url = "https://github.com/yuliskov/SmartTube/releases/latest/download/smarttube_21.00.apk";
        File = "SmartTube.apk"
    }
)

foreach ($item in $downloads) {
    $dest = Join-Path $apkFolder $item.File
    Log "[*] Descargando $($item.Name)..."
    try {
        Invoke-WebRequest -Uri $item.Url -OutFile $dest -UseBasicParsing
        Log "    [+] Guardado en: $dest"
    } catch {
        Log "    [-] Error al descargar $($item.Name). Link puede haber cambiado."
    }
}

# 3. Instrucciones finales
Log "==============================================="
Log " PAYLOAD COMPLETADO"
Log "==============================================="
Log "Siguiente paso:"
Log "1. Desconecta la USB de la PC y conéctala a la SMART TV."
Log "2. En la TV, abre el Administrador de Archivos (o instala uno si no tiene)."
Log "3. Ve a la carpeta RUNEFORGE_APKS."
Log "4. Instala FLauncher.apk y SmartTube.apk."
Log ""

$capture | Set-Clipboard
Log "[OK] Reporte copiado al portapapeles (Ctrl+V)."