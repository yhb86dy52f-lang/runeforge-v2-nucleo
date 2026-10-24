$ErrorActionPreference = "Continue"
$Report = New-Object System.Text.StringBuilder
function Log($msg) { [void]$Report.AppendLine($msg); Write-Host $msg }

$BackendDir = "C:\RUNEFORGE_V2_CORE\whisper-backend"
$VenvDir = "$BackendDir\venv"
$PythonExe = "$VenvDir\Scripts\python.exe"
$Ct2Dir = "$VenvDir\Lib\site-packages\ctranslate2"

Log "=== EXTRACCIÓN DE DLLs DE CUDA DESDE PYTORCH ==="

# 1. Matar backend
Get-Process python -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

# 2. Buscar las DLLs dentro del entorno virtual
Log "[1] Buscando DLLs de CUDA dentro del venv..."
$dllsToFind = @("cublas64_12.dll", "cublasLt64_12.dll", "cudart64_12.dll", "cudnn64_8.dll", "cudnn_ops_infer64_8.dll", "cudnn64_9.dll", "cudnn_ops_infer64_9.dll")
$foundDlls = @()

foreach ($dll in $dllsToFind) {
    $found = Get-ChildItem -Path $VenvDir -Filter $dll -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) {
        $foundDlls += $found.FullName
        Log "  [OK] Encontrada: $($found.FullName)"
    }
}

# 3. Copiar a ctranslate2
Log "`n[2] Copiando DLLs a la carpeta de ctranslate2..."
if ($foundDlls.Count -gt 0) {
    foreach ($dllPath in $foundDlls) {
        Copy-Item $dllPath $Ct2Dir -Force
    }
    Log "[OK] DLLs copiadas exitosamente."
} else {
    Log "[X] No se encontraron DLLs de CUDA en el venv. PyTorch podría estar incompleto."
}

# 4. Reiniciar y probar
Log "`n[3] Iniciando backend en ventana visible..."
Start-Process -FilePath $PythonExe -ArgumentList "server.py" -WorkingDirectory $BackendDir

Log "[>] Esperando a que el modelo cargue en la GPU..."
$ready = $false
for ($i = 1; $i -le 30; $i++) {
    Start-Sleep -Seconds 1
    try {
        $res = Invoke-RestMethod -Uri "http://127.0.0.1:8081/health" -TimeoutSec 1 -ErrorAction Stop
        if ($res.status -eq "ok") { $ready = $true; break }
    } catch {}
}

if ($ready) {
    Log "[OK] Backend arriba y escuchando."
    
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
    
    if ($curlOut -match '"text":"[^"]+"') {
        Log "`n[ÉXITO] El backend está funcionando PERFECTAMENTE."
        Log "-> Abre DICTATE Studio, apaga y enciende el micrófono."
    } elseif ($curlOut -match '"error"') {
        Log "`n[X] El backend devolvió un error. Revisa la ventana negra de Python."
    }
} else {
    Log "[X] El backend no arrancó en 30 segundos. Revisa la ventana negra de Python."
}

$txt = $Report.ToString()
Set-Clipboard -Value $txt
Write-Host "`n[OK] Salida copiada al portapapeles." -ForegroundColor Green
