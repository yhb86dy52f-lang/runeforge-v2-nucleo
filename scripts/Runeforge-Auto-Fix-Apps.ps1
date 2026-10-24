$ErrorActionPreference = "Continue"
$Report = New-Object System.Text.StringBuilder
function Log($msg) { [void]$Report.AppendLine($msg); Write-Host $msg }

Log "=== FIX AUTOMÁTICO PARA DICTATE Y OPEN-FRAME-GEN ==="

# 1. ARREGLAR BACKEND DE WHISPER (DICTATE)
Log "`n[1] Iniciando backend Whisper (DICTATE)..."
$whisperDir = "C:\RUNEFORGE_V2_CORE\whisper-backend"
$whisperExe = "$whisperDir\venv\Scripts\python.exe"
if (Test-Path $whisperExe) {
    $process = Get-Process python -EA SilentlyContinue | Where-Object { $_.Path -eq $whisperExe }
    if (-not $process) {
        Start-Process -FilePath $whisperExe -ArgumentList "server.py" -WorkingDirectory $whisperDir -WindowStyle Hidden
        Log "[OK] Backend Whisper iniciado en segundo plano (puerto 8081)."
    } else {
        Log "[--] El backend Whisper ya está corriendo."
    }
} else {
    Log "[X] No se encontró el ejecutable de Python en whisper-backend."
}

# 2. PARCHEAR OPEN-FRAME-GEN
Log "`n[2] Parcheando Open-Frame-gen (ui_overlay.py)..."
$uiPath = "C:\RUNEFORGE_V2_CORE\apps\optimizers\Open-Frame-gen\ui\ui_overlay.py"
if (Test-Path $uiPath) {
    $lines = Get-Content $uiPath
    
    # 2.1 Arreglar caché de DXCam
    $importIdx = -1
    for ($i=0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^import dxcam') { $importIdx = $i; break }
    }
    if ($importIdx -ne -1 -and ($lines[$importIdx+1] -notmatch 'cameras.clear')) {
        $lines = $lines[0..$importIdx] + "dxcam._factory.cameras.clear()" + $lines[($importIdx+1)..($lines.Count-1)]
        Log "  [OK] Inyectado dxcam._factory.cameras.clear()"
    }

    # 2.2 Arreglar TypeError de memoryview
    $fixedMemory = $false
    for ($i=0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match 'QImage\(([^,]+),') {
            $arg = $matches[1].Trim()
            if ($arg -notmatch '\.tobytes\(\)|^bytes\(') {
                $lines[$i] = $lines[$i] -replace [regex]::Escape("QImage($arg"), "QImage(bytes($arg.tobytes())"
                $fixedMemory = $true
                Log "  [OK] Parcheado QImage en línea $($i+1) para aceptar bytes."
            }
        }
    }
    if (-not $fixedMemory) { Log "  [--] No se requirió parche en QImage (o ya estaba parcheado)." }

    # Guardar cambios
    Set-Content -Path $uiPath -Value $lines -Encoding UTF8
    Log "[OK] Archivo ui_overlay.py actualizado."
} else {
    Log "[X] No se encontró ui_overlay.py."
}

$txt = $Report.ToString()
Set-Clipboard -Value $txt
Write-Host "`n[OK] Salida copiada al portapapeles." -ForegroundColor Green
