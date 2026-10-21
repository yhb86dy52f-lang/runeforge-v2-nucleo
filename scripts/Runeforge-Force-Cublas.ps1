$ErrorActionPreference = "Continue"
$Report = New-Object System.Text.StringBuilder
function Log($msg) { [void]$Report.AppendLine($msg); Write-Host $msg }

$BackendDir = "C:\RUNEFORGE_V2_CORE\whisper-backend"
$VenvDir = "$BackendDir\venv"
$PythonExe = "$VenvDir\Scripts\python.exe"
$PipExe = "$VenvDir\Scripts\pip.exe"
$Ct2Dir = "$VenvDir\Lib\site-packages\ctranslate2"

Log "=== FORZANDO DESCARGA DE CUBLAS (IGNORANDO SSL) ==="

# 1. Matar backend
Get-Process python -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

# 2. Descargar cuBLAS ignorando los problemas de SSL de Windows
Log "`n[1/3] Instalando nvidia-cublas-cu12 (bypass SSL)..."
$pipArgs = "install nvidia-cublas-cu12 nvidia-cudnn-cu12 --trusted-host pypi.org --trusted-host files.pythonhosted.org --no-cache-dir"
$pipOut = cmd /c "`"$PipExe`" $pipArgs 2>&1"
$pipOut | Select-Object -Last 4 | ForEach-Object { Log "  $_" }

# 3. Copiar las DLLs descargadas a la carpeta de ctranslate2
Log "`n[2/3] Buscando y copiando DLLs..."
$CublasDir = "$VenvDir\Lib\site-packages\nvidia\cublas\bin"
$CudnnDir  = "$VenvDir\Lib\site-packages\nvidia\cudnn\bin"

if (Test-Path $CublasDir) {
    Copy-Item "$CublasDir\cublas64_12.dll" $Ct2Dir -Force -ErrorAction SilentlyContinue
    Copy-Item "$CublasDir\cublasLt64_12.dll" $Ct2Dir -Force -ErrorAction SilentlyContinue
    Log "  [OK] cublas64_12.dll y cublasLt64_12.dll copiadas."
} else {
    Log "  [X] No se encontró la carpeta de cuBLAS. La descarga falló de nuevo."
}

if (Test-Path $CudnnDir) {
    Get-ChildItem -Path $CudnnDir -Filter "*.dll" | ForEach-Object {
        Copy-Item $_.FullName $Ct2Dir -Force -ErrorAction SilentlyContinue
    }
    Log "  [OK] DLLs de cuDNN copiadas."
}

# 4. Reiniciar y probar
Log "`n[3/3] Iniciando backend y probando audio..."
Start-Process -FilePath $PythonExe -ArgumentList "server.py" -WorkingDirectory $BackendDir

$ready = $false
for ($i = 1; $i -le 20; $i++) {
    Start-Sleep -Seconds 1
    try {
        $res = Invoke-RestMethod -Uri "http://127.0.0.1:8081/health" -TimeoutSec 1 -ErrorAction Stop
        if ($res.status -eq "ok") { $ready = $true; break }
    } catch {}
}

if ($ready) {
    Log "[OK] Backend arriba."
    $TestWav = "$env:TEMP\test_backend.wav"
    Add-Type -AssemblyName System.Speech
    $synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
    $synth.SetOutputToWaveFile($TestWav)
    $synth.Speak("Prueba exitosa. El dictado esta listo.")
    $synth.Dispose()

    $curlOut = curl.exe -s -X POST "http://127.0.0.1:8081/api/transcribe" -F "audio=@$TestWav" 2>&1
    Log "`nRespuesta del servidor:"
    Log $curlOut
    
    if ($curlOut -match '"text":"[^"]+"') {
        Log "`n[ÉXITO] El backend está funcionando PERFECTAMENTE."
    } elseif ($curlOut -match '"error"') {
        Log "`n[X] El backend devolvió un error. Revisa la ventana negra de Python."
    }
} else {
    Log "[X] El backend no arrancó. Revisa la ventana negra de Python."
}

$txt = $Report.ToString()
Set-Clipboard -Value $txt
Write-Host "`n[OK] Salida copiada al portapapeles." -ForegroundColor Green
