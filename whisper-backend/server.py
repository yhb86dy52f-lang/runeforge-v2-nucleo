import os, tempfile, time, site, glob

# --- INYECCIÓN DE DIRECTORIOS DE DLLs (MÉTODO WINDOWS) ---
site_packages = site.getsitepackages()[0]
paths_to_add = []

# Buscar carpetas de NVIDIA instaladas por pip
for p in glob.glob(os.path.join(site_packages, "nvidia", "*", "bin")):
    paths_to_add.append(p)
    
# Buscar librerías de PyTorch
torch_lib = os.path.join(site_packages, "torch", "lib")
if os.path.exists(torch_lib):
    paths_to_add.append(torch_lib)

print(f"[INIT] Agregando {len(paths_to_add)} directorios de DLLs al sistema:")
for p in paths_to_add:
    if os.path.exists(p):
        os.add_dll_directory(p)
        os.environ["PATH"] = p + os.pathsep + os.environ["PATH"]
        print(f"  - {p}")

from fastapi import FastAPI, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from faster_whisper import WhisperModel

MODEL_SIZE = "large-v3-turbo"
DEVICE     = "cuda"
COMPUTE    = "int8_float16"
LANG       = "es"

print(f"[WHISPER] Cargando {MODEL_SIZE} en {DEVICE}...")
t0 = time.time()
model = WhisperModel(MODEL_SIZE, device=DEVICE, compute_type=COMPUTE)
print(f"[WHISPER] Modelo cargado en {time.time()-t0:.1f}s")

app = FastAPI()
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

@app.post("/api/transcribe")
async def transcribe(audio: UploadFile = File(...)):
    try:
        with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as tmp:
            content = await audio.read()
            tmp.write(content)
            tmp_path = tmp.name

        t1 = time.time()
        segments, info = model.transcribe(
            tmp_path,
            language=LANG,
            beam_size=1,
            vad_filter=False,
            no_speech_threshold=1.0,
            temperature=0.0,
        )
        text = " ".join(seg.text.strip() for seg in segments).strip()
        elapsed = time.time() - t1
        
        print(f"[TRANSCRIBE] {elapsed:.2f}s | TEXTO: '{text}'")
        os.unlink(tmp_path)
        return {"text": text, "language": info.language}
    except Exception as e:
        print(f"[ERROR] {e}")
        return {"text": "", "error": str(e)}

@app.get("/health")
async def health():
    return {"status": "ok", "model": MODEL_SIZE, "device": DEVICE}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8081, log_level="warning")