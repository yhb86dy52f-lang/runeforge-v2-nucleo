# SIGNING - RUNEFORGE V2

## Identidad
- Proyecto: RUNEFORGE V2 CORE - Dictation + SMS Hub + Whisper
- Organización: Nesthor CV
- Contacto: [tu email para SignPath]

## Build Reproducible
1. Backend Whisper: python apps/dictate-backend/backend/main.py (faster_whisper)
2. Fastify: npm run build (usa sql.js, no sqlite3 nativo)
3. Tauri: cargo build --release en apps/dictate-studio-v2/src-tauri

## Firma
- Solicitud SignPath Foundation: https://signpath.org
- Certificado: Extended Validation via SignPath
- Artefactos a firmar: *.exe, *.msi, *.nsis

## Verificación
- Hash SHA256 del build se publica en release
- Firma verificable con: signtool verify /pa *.exe
