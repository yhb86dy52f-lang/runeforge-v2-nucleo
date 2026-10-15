import os, tempfile, time
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from faster_whisper import WhisperModel

MODEL_SIZE = "large-v3-turbo"
DEVICE     = "cuda"
COMPUTE    = "int8_float16"
LANG       = "es"
BEAM_SIZE  = 1

print(f"[WHISPER] Cargando {MODEL_SIZE} en {DEVICE} ({COMPUTE})...")
t0 = time.time()
model = WhisperModel(MODEL_SIZE, device=DEVICE, compute_type=COMPUTE)
print(f"[WHISPER] Modelo cargado en {time.time()-t0:.1f}s")

app = FastAPI(title="Whisper Backend")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

@app.post("/api/transcribe")
async def transcribe(audio: UploadFile = File(...)):
    try:
        with tempfile.NamedTemporaryFile(delete=False, suffix=".webm") as tmp:
            content = await audio.read()
            tmp.write(content)
            tmp_path = tmp.name
        t1 = time.time()
        segments, info = model.transcribe(
            tmp_path,
            language=LANG if LANG != "auto" else None,
            beam_size=BEAM_SIZE,
            vad_filter=True,
            vad_parameters=dict(min_silence_duration_ms=500),
            condition_on_previous_text=False,
            without_timestamps=True,
            no_speech_threshold=0.8,
            log_prob_threshold=-1.0,
            temperature=0.0,
        )
        text = " ".join(seg.text.strip() for seg in segments).strip()
        elapsed = time.time() - t1
        os.unlink(tmp_path)
        print(f"[TRANSCRIBE] {elapsed:.2f}s | {len(content)/1024:.0f}KB | {text[:80]!r}")
        return {"text": text, "language": info.language, "duration": info.duration}
    except Exception as e:
        print(f"[ERROR] {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/health")
async def health():
    return {"status": "ok", "model": MODEL_SIZE, "device": DEVICE}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8081, log_level="warning")
