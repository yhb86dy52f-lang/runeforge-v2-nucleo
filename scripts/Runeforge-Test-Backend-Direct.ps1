$ErrorActionPreference = "Continue"
$Report = New-Object System.Text.StringBuilder
function Log($msg) { [void]$Report.AppendLine($msg); Write-Host $msg }

$TestWav = "$env:TEMP\test_transcribe.wav"
$Url = "http://127.0.0.1:8081/api/transcribe"

Log "=== PRUEBA DIRECTA AL BACKEND (SALTANDO LA APP) ==="

# 1. Generar audio de prueba con la voz de Windows
Log "[1] Generando archivo de audio (.wav) con voz de Windows..."
Add-Type -AssemblyName System.Speech
$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
$synth.SetOutputToWaveFile($TestWav)
$synth.Speak("Hola, esto es una prueba directa al backend. Si puedes leer esto, la transcripcion funciona.")
$synth.Dispose()
Log "[OK] Audio generado en: $TestWav"

# 2. Enviar al backend usando curl.exe (más robusto para multipart/form-data)
Log "`n[2] Enviando audio al backend en $Url..."
Log "    (Esperando respuesta del modelo large-v3-turbo...)"

$curlOutput = curl.exe -s -X POST $Url -F "audio=@$TestWav" 2>&1

# 3. Analizar respuesta
Log "`n[3] Respuesta cruda del servidor:"
Log $curlOutput

if ($curlOutput -match '"text"') {
    Log "`n[ÉXITO] El backend SÍ está transcribiendo. El problema está en la comunicación de la App (Tauri/Shim)."
} elseif ($curlOutput -match '"error"') {
    Log "`n[X] El backend devolvió un error interno. Revisa la ventana negra de Python."
} else {
    Log "`n[X] El backend no respondió o devolvió algo inesperado. ¿Está la ventana negra de Python abierta?"
}

$txt = $Report.ToString()
Set-Clipboard -Value $txt
Write-Host "`n[OK] Salida copiada al portapapeles." -ForegroundColor Green
