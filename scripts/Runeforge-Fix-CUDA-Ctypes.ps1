$ErrorActionPreference = "Continue"
$Report = New-Object System.Text.StringBuilder
function Log($msg) { [void]$Report.AppendLine($msg); Write-Host $msg }

$BackendDir = "C:\RUNEFORGE_V2_CORE\whisper-backend"
$ServerFile = "$BackendDir\server.py"
$PythonExe = "$BackendDir\venv\Scripts\python.exe"

Log "=== REESCRIBIENDO SERVER.PY CON CTYPES PRE-LOAD ==="

$lines = @(
    'import os, tempfile, time, site, glob, ctypes',
    '',
    '# --- PRE-CARGA FORZADA DE DLLs EN MEMORIA ---',
    'site_packages = site.getsitepackages()[0]',
    'search_patterns = [',
    '    os.path.join(site_packages, "nvidia", "**", "cublas64_12.dll"),',
    '    os.path.join(site_packages, "nvidia", "**", "cublasLt64_12.dll"),',
    '    os.path.join(site_packages, "nvidia", "**", "cudart64_12.dll"),',
    '    os.path.join(site_packages, "torch", "lib", "cublas64_12.dll"),',
    '    os.path.join(site_packages, "torch", "lib", "cublasLt64_12.dll")',
    ']',
    '',
    'loaded_dlls = []',
    'for pattern in search_patterns:',
    '    for dll in glob.glob(pattern, recursive=True):',
    '        try:',
    '            ctypes.CDLL(dll, mode=ctypes.RTLD_GLOBAL)',
    '            loaded_dlls.append(dll)',
    '            break # Si carga la primera, no buscamos mas',
    '        except Exception:',
    '            pass',
    'print(f"[INIT] DLLs pre-cargadas: {len(loaded_dlls)}")',
    'for d in loaded_dlls: print(f"  - {d}")',
    '',
    'from fastapi import FastAPI, File, UploadFile',
    'from fastapi.middleware.cors import CORSMiddleware',
    'from faster_whisper import WhisperModel',
    '',
    'MODEL_SIZE = "large-v3-turbo"',
    'DEVICE     = "cuda"',
    'COMPUTE    = "int8_float16"',
    'LANG       = "es"',
    '',
    'print(f"[WHISPER] Cargando {MODEL_SIZE} en {DEVICE}...")',
    't0 = time.time()',
    'model = WhisperModel(MODEL_SIZE, device=DEVICE, compute_type=COMPUTE)',
    'print(f"[WHISPER] Modelo cargado en {time.time()-t0:.1f}s")',
    '',
    'app = FastAPI()',
    'app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])',
    '',
    '@app.post("/api/transcribe")',
    'async def transcribe(audio: UploadFile = File(...)):',
    '    try:',
    '        with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as tmp:',
    '            content = await audio.read()',
    '            tmp.write(content)',
    '            tmp_path = tmp.name',
    '',
    '        t1 = time.time()',
    '        segments, info = model.transcribe(',
    '            tmp_path,',
    '            language=LANG,',
    '            beam_size=1,',
    '            vad_filter=False,',
    '            no_speech_threshold=1.0,',
    '            temperature=0.0,',
    '        )',
    '        text = " ".join(seg.text.strip() for seg in segments).strip()',
    '        elapsed = time.time() - t1',
    '        ',
    '        print(f"[TRANSCRIBE] {elapsed:.2f}s | TEXTO: ''{text}''")',
    '        os.unlink(tmp_path)',
    '        return {"text": text, "language": info.language}',
    '    except Exception as e:',
    '        print(f"[ERROR] {e}")',
    '        return {"text": "", "error": str(e)}',
    '',
    '@app.get("/health")',
    'async def health():',
    '    return {"status": "ok", "model": MODEL_SIZE, "device": DEVICE}',
    '',
    'if __name__ == "__main__":',
    '    import uvicorn',
    '    uvicorn.run(app, host="127.0.0.1", port=8081, log_level="warning")'
)

$newServer = $lines -join "`r`n"
[IO.File]::WriteAllText($ServerFile, $newServer, [System.Text.UTF8Encoding]::new($false))
Log "[OK] server.py reescrito con pre-carga de ctypes."

Get-Process python -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

Log "`n[>] Iniciando backend en ventana visible..."
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
