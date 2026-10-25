$ErrorActionPreference = "Continue"
$Report = New-Object System.Text.StringBuilder
function Log($msg) { [void]$Report.AppendLine($msg); Write-Host $msg }

$BackendDir = "C:\RUNEFORGE_V2_CORE\whisper-backend"
$VenvDir = "$BackendDir\venv"
$PythonExe = "$VenvDir\Scripts\python.exe"
$PipExe = "$VenvDir\Scripts\pip.exe"
$ServerFile = "$BackendDir\server.py"

Log "=== REPARACIÓN DEFINITIVA DE CUDA (PIP + PATH) ==="

# 1. Reinstalar las librerías de NVIDIA (cublas y cudnn)
Log "`n[1/3] Instalando librerías de NVIDIA (cuBLAS, cuDNN)..."
$pipOut = & $PipExe install nvidia-cublas-cu12 nvidia-cudnn-cu12 2>&1
$pipOut | Select-Object -Last 3 | ForEach-Object { Log "  $_" }

# 2. Reescribir server.py usando os.add_dll_directory (Método oficial de Windows)
Log "`n[2/3] Reescribiendo server.py con os.add_dll_directory..."

$lines = @(
    'import os, tempfile, time, site, glob',
    '',
    '# --- INYECCIÓN DE DIRECTORIOS DE DLLs (MÉTODO WINDOWS) ---',
    'site_packages = site.getsitepackages()[0]',
    'paths_to_add = []',
    '',
    '# Buscar carpetas de NVIDIA instaladas por pip',
    'for p in glob.glob(os.path.join(site_packages, "nvidia", "*", "bin")):',
    '    paths_to_add.append(p)',
    '    ',
    '# Buscar librerías de PyTorch',
    'torch_lib = os.path.join(site_packages, "torch", "lib")',
    'if os.path.exists(torch_lib):',
    '    paths_to_add.append(torch_lib)',
    '',
    'print(f"[INIT] Agregando {len(paths_to_add)} directorios de DLLs al sistema:")',
    'for p in paths_to_add:',
    '    if os.path.exists(p):',
    '        os.add_dll_directory(p)',
    '        os.environ["PATH"] = p + os.pathsep + os.environ["PATH"]',
    '        print(f"  - {p}")',
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
Log "[OK] server.py reescrito con os.add_dll_directory."

# 3. Reiniciar y Probar
Get-Process python -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

Log "`n[3/3] Iniciando backend en ventana visible y probando..."
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
