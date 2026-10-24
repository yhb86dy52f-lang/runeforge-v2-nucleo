$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$capture = New-Object System.Collections.ArrayList

function Log {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Cyan
    $null = $capture.Add($Message)
}

Log "╔══════════════════════════════════════════════════════╗"
Log "║   RUNEFORGE NEXUS - AUDITORÍA DE ARCHIVOS .AHK       ║"
Log "║   $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')                          ║"
Log "╚══════════════════════════════════════════════════════╝"
Log ""

# Obtener unidades locales disponibles
$drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -ne $null -and $_.Name -match '^[A-Z]$' }
$ahkFiles = New-Object System.Collections.ArrayList

Log ">> Iniciando escaneo profundo. Esto puede tardar dependiendo de la velocidad de tus HDD/SSD..."
Log ""

foreach ($drive in $drives) {
    $rootPath = "$($drive.Name):\"
    Log "[*] Buscando en unidad: $rootPath"
    
    # Búsqueda recursiva ignorando errores de acceso denegado
    $files = Get-ChildItem -Path $rootPath -Filter "*.ahk" -Recurse -File -ErrorAction SilentlyContinue
    if ($files) {
        foreach ($file in $files) { $null = $ahkFiles.Add($file) }
    }
}

Log ""
Log "========================================"
Log " RESULTADOS DE LA AUDITORÍA"
Log "========================================"

if ($ahkFiles.Count -eq 0) {
    Log "[!] No se encontraron archivos .ahk en el sistema."
} else {
    Log "[OK] Se encontraron $($ahkFiles.Count) archivos AutoHotkey:"
    Log ""
    
    # Ordenar por ruta para mejor lectura
    $sortedFiles = $ahkFiles | Sort-Object FullName
    
    $i = 1
    foreach ($file in $sortedFiles) {
        $sizeKB = [math]::Round($file.Length / 1KB, 2)
        $date = $file.LastWriteTime.ToString("yyyy-MM-dd HH:mm")
        Log ("  {0}. {1}" -f $i, $file.FullName)
        Log ("     -> Tamaño: {0} KB | Modificado: {1}" -f $sizeKB, $date)
        $i++
    }
}

Log ""
Log "[OK] Auditoría completada. Reporte copiado al portapapeles."

# Inyección al portapapeles
$capture | Set-Clipboard