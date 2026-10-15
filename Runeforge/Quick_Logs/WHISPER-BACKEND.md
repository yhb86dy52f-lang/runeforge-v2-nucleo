---
sello: Forneus
sello_numero: 30
origen: docs
tipo: Quick_Logs
up: "[[Runeforge/MOCs/MOC-Quick_Logs]]"
tags: [Runegea, QuickLog]
fecha_forja: 2026-09-28
---

> [!RUNE] Sello #30 Forneus
> Forjado desde anillo huérfano -> [[Runeforge/MOCs/MOC-Quick_Logs]]

# WHISPER BACKEND — RUNEFORGE V2

**Fecha canon:** 2026-09-27
**Estado:** Operativo en produccion

## Stack

- GPU: GTX 1660 SUPER (6 GB, Turing)
- Python: 3.11.9 en `whisper-backend\venv`
- Modelo: `large-v3-turbo` + `faster-whisper>=1.1.0`
- Compute: `int8_float16`, `beam_size=1`
- CUDA 12.9 wheels instalados y copiados a ctranslate2
- Server: FastAPI + uvicorn en 127.0.0.1:8081

## Shim del cliente (DICTATE Studio)

- HTML fuente: `forja\dictate-src\Dictate-Whisper.html`
- Marca: `SHIM_V3_WAV`
- Captura Web Audio API -> PCM int16 -> WAV blob cada 8s
- Envia por `__TAURI__.http.fetch` a `/api/transcribe`
- NO usar MediaRecorder/opus: fragmenta sin header EBML y PyAV falla con AVERROR_INVALIDDATA

## Arranque

- Auto: tarea de Inicio -> `Whisper-Backend.lnk` -> VBS oculto
- Manual: doble clic en `C:\RUNEFORGE_V2_CORE\DICTATE.bat`
- Debug: `whisper-backend\venv\Scripts\Activate.ps1; python server.py`

## Rutas

- Backend: `C:\RUNEFORGE_V2_CORE\whisper-backend\server.py`
- Modelo HF: `%USERPROFILE%\.cache\huggingface\hub`
- EXE app: `C:\RUNEFORGE_V2_CORE\target\release\dictate-studio-v2.exe`

## Parametros activos

| Parametro | Valor | Razon |
|---|---|---|
| BEAM_SIZE | 1 | Greedy. Turbo entrenado para beam=1. 3-5x speedup |
| COMPUTE | int8_float16 | Turing sin tensor cores rinde mejor en int8 |
| without_timestamps | True | Ahorra ~20% |
| vad_filter | True (400ms) | Descarta silencio |
| no_speech_threshold | 0.8 | Rechazo agresivo de ruido |
| log_prob_threshold | -1.0 | Anti-alucinaciones |
| condition_on_previous_text | False | Evita alucinaciones cross-chunk |

## Troubleshooting

| Error | Fix |
|---|---|
| cublas64_12.dll not found | pip install nvidia-cublas-cu12 + copiar DLL a site-packages\ctranslate2 |
| AVERROR_INVALIDDATA | El shim usa webm fragmentado. Debe ser WAV (SHIM_V3_WAV) |
| Invalid model size large-v3-turbo | pip install --upgrade "faster-whisper>=1.1.0" |
| Puerto 8081 ocupado | Get-NetTCPConnection -LocalPort 8081 -State Listen \| Stop-Process -Force |
| Alucinaciones (Gracias!) | no_speech_threshold=0.8 + log_prob_threshold=-1.0 |
