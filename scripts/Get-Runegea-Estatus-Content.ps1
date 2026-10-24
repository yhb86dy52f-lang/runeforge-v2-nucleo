$files = @(
"C:\RUNEFORGE_V2_CORE\Runeforge\AI_Intel\ESTATUS.md",
"C:\RUNEFORGE_V2_CORE\Runeforge\AI_Intel\RUNEFORGE ESTATUS.md",
"C:\RUNEFORGE_V2_CORE\Runeforge\AI_Intel\ESTATUS_FINAL_VERDE_2026-08-15_14-16-58.md",
"C:\RUNEFORGE_V2_CORE\Runeforge\AI_Intel\ESTATUS_RECURSOS_FINAL_2026-08-15_14-10-40.md"
)
foreach ($f in $files) { if (Test-Path $f) { Write-Host "`n=== $f ===" -F Magenta; Get-Content $f -Raw } }

# --- INICIO PATCH NTFY PRIVADO Forneus #30 ---
$NtfyUrlLocal = "http://localhost:8085/runeforge-estatus"
try {
    $estatusResumen = "RUNEFORGE OK | Backend 3100 | Ollama 4 modelos | PM2 2 procs"
    if (Test-Path "C:\RUNEFORGE_V2_CORE\Runeforge\AI_Intel\ESTATUS.md") {
        $md = Get-Content "C:\RUNEFORGE_V2_CORE\Runeforge\AI_Intel\ESTATUS.md" -Raw -ErrorAction SilentlyContinue
        if ($md) { $estatusResumen = ($md | Select-String -Pattern "\|.*\|").Matches | Select-Object -First 3 | ForEach-Object { $_.Value } | Out-String }
    }
    Invoke-RestMethod -Uri $NtfyUrlLocal -Method POST -Body $estatusResumen -Headers @{"Title"="Runeforge Estatus";"Tags"="gear,white_check_mark";"Priority"="default"} -TimeoutSec 5 -ErrorAction SilentlyContinue | Out-Null
} catch {}
# --- FIN PATCH NTFY PRIVADO ---
