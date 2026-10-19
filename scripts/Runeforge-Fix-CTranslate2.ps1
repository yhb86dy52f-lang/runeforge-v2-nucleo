$ErrorActionPreference = "Continue"
$Report = New-Object System.Text.StringBuilder
function Log($msg) { [void]$Report.AppendLine($msg); Write-Host $msg }

Log "=== REPARANDO ENTORNO DE WHISPER (VISUAL C++ + CTRANSLATE2) ==="

$BackendDir = "C:\RUNEFORGE_V2_CORE\whisper-backend"
$VCRedistUrl = "https://aka.ms/vs/17/release/vc_redist.x64.exe"
$VCRedistPath = "$env:TEMP\vc_redist.x64.exe"

# 1. Descargar e instalar Visual C++ Redistributable
Log "`n[1] Descargando Visual C++ Redistributable..."
try {
    Invoke-WebRequest -Uri $VCRedistUrl -OutFile $VCRedistPath -UseBasicParsing -ErrorAction Stop
    Log "[OK] Descargado."
} catch {
    Log "[X] Error al descargar. Verifica tu conexión a internet."
    $Report.ToString() | Set-Clipboard; return
}

Log "[2] Instalando Visual C++ Redistributable (silencioso)..."
$proc = Start-Process -FilePath $VCRedistPath -ArgumentList "/install", "/quiet", "/norestart" -Wait -PassThru
if ($proc.ExitCode -eq 0 -or $proc.ExitCode -eq 3010) {
    Log "[OK] Visual C++ Redistributable instalado correctamente."
} else {
    Log "[!] El instalador devolvió código: $($proc.ExitCode). Puede que ya estuviera instalado."
}

# 2. Reinstalar ctranslate2 y faster-whisper para asegurar compatibilidad
Log "`n[3] Reinstalando ctranslate2 y faster-whisper..."
Push-Location $BackendDir
$pipOutput = & ".\venv\Scripts\pip.exe" install --force-reinstall --no-cache-dir ctranslate2 faster-whisper 2>&1
Pop-Location

$pipOutput | Select-Object -Last 5 | ForEach-Object { Log "  $_" }

# 3. Verificar que el problema se ha resuelto
Log "`n[4] Verificando importación de ctranslate2..."
Push-Location $BackendDir
$testImport = & ".\venv\Scripts\python.exe" -c "import ctranslate2; print('OK')" 2>&1
Pop-Location

if ($testImport -match "OK") {
    Log "[OK] ctranslate2 se importa correctamente."
    Log "`n[ÉXITO] El backend debería arrancar ahora. El script se detendrá aquí."
} else {
    Log "[X] La importación sigue fallando. Error:"
    Log "  $testImport"
}

$txt = $Report.ToString()
Set-Clipboard -Value $txt
Write-Host "`n[OK] Salida copiada al portapapeles." -ForegroundColor Green
