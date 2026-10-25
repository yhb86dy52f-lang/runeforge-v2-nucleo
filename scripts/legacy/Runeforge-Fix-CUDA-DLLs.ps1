$ErrorActionPreference = "Continue"
$Report = New-Object System.Text.StringBuilder
function Log($msg) { [void]$Report.AppendLine($msg); Write-Host $msg }

$BackendDir = "C:\RUNEFORGE_V2_CORE\whisper-backend"
$VenvDir = "$BackendDir\venv"
$PythonExe = "$VenvDir\Scripts\python.exe"
$Ct2Dir = "$VenvDir\Lib\site-packages\ctranslate2"
$CublasDir = "$VenvDir\Lib\site-packages\nvidia\cublas\bin"
$CudartDir = "$VenvDir\Lib\site-packages\nvidia\cuda_runtime\bin"

Log "=== RESTAURANDO DLLs DE CUDA ==="

# 1. Matar backend anterior
Get-Process python -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

# 2. Copiar las DLLs a la carpeta de ctranslate2
if (Test-Path $CublasDir) {
    Copy-Item "$CublasDir\cublas64_12.dll" $Ct2Dir -Force -ErrorAction SilentlyContinue
    Copy-Item "$CublasDir\cublasLt64_12.dll" $Ct2Dir -Force -ErrorAction SilentlyContinue
    Log "[OK] DLLs de cuBLAS restauradas."
} else {
    Log "[X] No se encontró la carpeta de cuBLAS de NVIDIA."
}

if (Test-Path $CudartDir) {
    Copy-Item "$CudartDir\cudart64_12.dll" $Ct2Dir -Force -ErrorAction SilentlyContinue
    Log "[OK] DLL de CUDA Runtime restaurada."
}

# 3. Reiniciar backend
Log "`n[>] Iniciando backend oculto..."
Start-Process -FilePath $PythonExe -ArgumentList "server.py" -WorkingDirectory $BackendDir -WindowStyle Hidden

# 4. Esperar a que cargue
Log "[>] Esperando a que el modelo cargue en la GPU..."
$ready = $false
for ($i = 1; $i -le 20; $i++) {
    Start-Sleep -Seconds 1
    try {
        $res = Invoke-RestMethod -Uri "http://127.0.0.1:8081/health" -TimeoutSec 1 -ErrorAction Stop
        if ($res.status -eq "ok") { $ready = $true; break }
    } catch {}
}

if ($ready) {
    Log "[OK] Backend arriba y escuchando."
    
    # 5. Generar y enviar audio de prueba
    Log "`n[>] Generando audio de prueba..."
    $TestWav = "$env:TEMP\test_backend.wav"
    Add-Type -AssemblyName System.Speech
    $synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
    $synth.SetOutputToWaveFile($TestWav)
    $synth.Speak("Prueba exitosa. El dictado esta listo.")
    $synth.Dispose()

    Log "[>] Enviando audio al servidor..."
    $curlOut = curl.exe -s -X POST "http://127.0.0.1:8081/api/transcribe" -F "audio=@$TestWav" 2>&1
    Log "`nRespuesta del servidor:"
    Log $curlOut
    
    if ($curlOut -match '"text"') {
        Log "`n[ÉXITO] El backend está funcionando perfectamente."
        Log "-> Abre DICTATE Studio, apaga y enciende el micrófono."
    }
} else {
    Log "[X] El backend no arrancó a tiempo. Asegúrate de que la ventana negra no tenga errores."
}

$txt = $Report.ToString()
Set-Clipboard -Value $txt
Write-Host "`n[OK] Salida copiada al portapapeles." -ForegroundColor Green
