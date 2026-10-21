$ErrorActionPreference = "Continue"
Write-Host "=== REESCRIBIENDO SERVER.PY PARA MÁXIMA CAPTURA ===" -ForegroundColor Cyan

$BackendDir = "C:\RUNEFORGE_V2_CORE\whisper-backend"
$ServerFile = "$BackendDir\server.py"

$lines = @(
    'import os, tempfile, time',
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
    '        print(f"[TRANSCRIBE] {elapsed:.2f}s | {len(content)/1024:.0f}KB | TEXTO: ''{text}''")',
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
Write-Host "[OK] server.py reescrito (VAD apagado, sin filtros)." -ForegroundColor Green

Get-Process python -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

Write-Host "`n[!] ATENCIÓN: Se abrirá una NUEVA VENTANA NEGRA con el Backend." -ForegroundColor Yellow
Write-Host "    No la cierres. Habla por el micrófono de DICTATE Studio." -ForegroundColor Yellow

Start-Process -FilePath "$BackendDir\venv\Scripts\python.exe" -ArgumentList "server.py" -WorkingDirectory $BackendDir
