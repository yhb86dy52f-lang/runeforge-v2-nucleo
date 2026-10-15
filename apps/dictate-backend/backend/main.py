from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from faster_whisper import WhisperModel
import tempfile, os, time, uvicorn

app = FastAPI(title="DICTATE Whisper Backend", version="1.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

MODEL_SIZE = os.environ.get("WHISPER_MODEL", "base")
LANG = os.environ.get("WHISPER_LANG", "es")
DEVICE = os.environ.get("WHISPER_DEVICE", "cpu")
_model = None
_model_ts = None


def get_model():
    global _model, _model_ts
    if _model is None:
        t0 = time.time()
        _model = WhisperModel(MODEL_SIZE, device=DEVICE, compute_type="int8")
        _model_ts = time.time() - t0
    return _model


@app.get("/api/health")
def health():
    loaded = _model is not None
    return {
        "ok": True,
        "model": MODEL_SIZE,
        "device": DEVICE,
        "lang": LANG,
        "loaded": loaded,
        "load_seconds": _model_ts,
    }


@app.post("/api/transcribe")
async def transcribe(audio: UploadFile = File(...)):
    if not audio.filename:
        raise HTTPException(400, "no audio file")
    suffix = os.path.splitext(audio.filename)[1] or ".webm"
    tmp = None
    try:
        with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as f:
            f.write(await audio.read())
            tmp = f.name
        t0 = time.time()
        segments, info = get_model().transcribe(
            tmp,
            language=LANG if LANG else None,
            beam_size=5,
            vad_filter=True,
        )
        text = " ".join(s.text.strip() for s in segments).strip()
        elapsed = time.time() - t0
        return {
            "text": text,
            "lang": info.language,
            "lang_prob": getattr(info, "language_probability", None),
            "duration": info.duration,
            "elapsed": elapsed,
        }
    except Exception as e:
        raise HTTPException(500, str(e))
    finally:
        if tmp and os.path.exists(tmp):
            try: os.unlink(tmp)
            except: pass


if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=8081, log_level="warning")
