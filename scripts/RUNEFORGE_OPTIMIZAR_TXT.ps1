$ErrorActionPreference = 'Continue'$logBuffer = [System.Collections.Generic.List[string]]::new()

function Write-Log {
    param([string]$Message)$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logLine = "[$timestamp]$Message"
    Write-Output $logLine
    $logBuffer.Add($logLine)
}

Write-Log "=== INICIANDO SCRIPT DE CLASIFICACIÓN Y LIMPIEZA DE TXT ==="
$canonicalPath = "C:\RUNEFORGE_V2_CORE\scripts"
Write-Log "Ruta canónica objetivo: $canonicalPath"

# 1. Crear directorio de archivo procesado si no existe
$archivePath = Join-Path$canonicalPath "archive_txt"
if (!(Test-Path $archivePath)) {
    New-Item -Path $archivePath -ItemType Directory -Force | Out-Null
    Write-Log "Creado directorio de archivo: $archivePath"
}

# 2. Buscar, clasificar, ordenar y limpiar archivos TXT en la ruta canónica
Write-Log "Buscando archivos TXT para ordenar y limpiar..."
$txtFiles = Get-ChildItem -Path$canonicalPath -Filter "*.txt" -File -ErrorAction SilentlyContinue

foreach ($file in$txtFiles) {
    try {
        $content = Get-Content -Path$file.FullName -Raw -ErrorAction Stop
        # Limpiar espacios en blanco excesivos y líneas vacías duplicadas
        $cleanedContent = ($content -replace "`r`n`r`n+", "`r`n`r`n").Trim()
        
        $destFile = Join-Path $archivePath $file.Name
        Set-Content -Path $destFile -Value $cleanedContent -Encoding utf8
        Write-Log "Procesado y clasificado: $($file.Name)"
    } catch {
        Write-Log "Error al procesar el archivo $($file.Name): $_"
    }
}

# 3. Validación y verificación final usando CIM
Write-Log "Ejecutando verificación final del almacenamiento..."
$disk = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'"
$freeSpaceGB = [Math]::Round($disk.FreeSpace / 1GB, 2)
$totalSpaceGB = [Math]::Round($disk.Size / 1GB, 2)
Write-Log "Verificación de Disco C: - Espacio Libre: $freeSpaceGB GB de $totalSpaceGB GB totales."

# 4. Capturar salida y copiar al portapapeles
$finalOutput = $logBuffer -join "`n"
Set-Clipboard -Value $finalOutput
Write-Log "=== PROCESO FINALIZADO. REGISTRO COPIADO AL PORTAPAPELES ==="