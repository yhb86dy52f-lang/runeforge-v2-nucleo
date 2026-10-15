$p = "$env:TEMP\install-r.ps1"
notepad $p
# Pega el script, guarda Ctrl+S, cierra Notepad
powershell -ExecutionPolicy Bypass -NoProfile -File $p