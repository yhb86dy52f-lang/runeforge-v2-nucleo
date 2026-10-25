# ==============================================================================
# SCRIPT INTERNO: AUDITORÍA DE RUTAS DEL PANEL
# ==============================================================================
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$capture = New-Object System.Collections.ArrayList

function Log {
    param([string]$Message, [string]$Color = "Gray")
    Write-Host $Message -ForegroundColor $Color
    $null = $capture.Add($Message)
}

Log "╔══════════════════════════════════════════════════════╗" "Cyan"
Log "║   AUDITORÍA FORENSE DE RUTAS - MASTER PANEL V6       ║" "Cyan"
Log "╚══════════════════════════════════════════════════════╝" "Cyan"
Log ""

$targets = @(
    # --- MASTERS ---
    @{ Name = "Dashboard (UI)"; Path = "C:\RUNEFORGE_V2_CORE\public\index_master.html"; Type = "File" },
    @{ Name = "Radar BLE (UI)"; Path = "C:\RUNEFORGE_V2_CORE\firmware\scannerpro_cyber_visualizer\scannerpro_cyber_visualizer.html"; Type = "File" },
    @{ Name = "GPS/Sonar (UI)"; Path = "C:\RUNEFORGE_V2_CORE\firmware\fusionada_x5f_sonar_x5f_instalaciones_x5f_sepcolgps.html"; Type = "File" },
    
    # --- IA / CONTEXTO ---
    @{ Name = "Memoria IA"; Path = "C:\RUNEFORGE_V2_CORE\core_data\memorias\memoria_operativa.txt"; Type = "File" },
    @{ Name = "Prompt Master"; Path = "C:\RUNEFORGE_V2_CORE\core_data\prompts\prompt_maestro.txt"; Type = "File" },
    @{ Name = "Dir Prompts"; Path = "C:\RUNEFORGE_V2_CORE\core_data\prompts"; Type = "Dir" },
    
    # --- SISTEMA / CORE (Batch + PS1) ---
    @{ Name = "ARRANCAR (.bat)"; Path = "C:\RUNEFORGE_V2_CORE\scripts\RUNEFORGE.bat"; Fallback = "C:\RUNEFORGE_V2_CORE\scripts\RUNEFORGE_BOOT.ps1"; Type = "File" },
    @{ Name = "PARAR (.bat)"; Path = "C:\RUNEFORGE_V2_CORE\scripts\STOP.bat"; Fallback = "C:\RUNEFORGE_V2_CORE\scripts\STOP.ps1"; Type = "File" },
    @{ Name = "AUDITAR (.bat)"; Path = "C:\RUNEFORGE_V2_CORE\scripts\AUDIT.bat"; Fallback = "C:\RUNEFORGE_V2_CORE\scripts\AUDIT.ps1"; Type = "File" },
    @{ Name = "RESET RAM (.bat)"; Path = "C:\RUNEFORGE_V2_CORE\scripts\RESET.bat"; Fallback = "C:\RUNEFORGE_V2_CORE\scripts\Optimizador-Runeforge.ps1"; Type = "File" },

    # --- CÓDIGO / FRAMEWORKS ---
    @{ Name = "Root Core"; Path = "C:\RUNEFORGE_V2_CORE"; Type = "Dir" },
    @{ Name = "Dir Scripts"; Path = "C:\RUNEFORGE_V2_CORE\scripts"; Type = "Dir" },
    
    # --- ACCESOS DIRECTOS ---
    @{ Name = "Dir Firmware"; Path = "C:\RUNEFORGE_V2_CORE\firmware"; Type = "Dir" },
    @{ Name = "Dir Forja"; Path = "C:\RUNEFORGE_V2_CORE\forja"; Type = "Dir" }
)

$missingCount = 0
$fallbackCount = 0
$okCount = 0

foreach ($t in $targets) {
    if (Test-Path $t.Path) {
        Log "  [OK] $($t.Name)" "Green"
        Log "       -> $($t.Path)" "DarkGray"
        $okCount++
    } else {
        if ($t.ContainsKey("Fallback") -and (Test-Path $t.Fallback)) {
            Log "  [WARN] $($t.Name) - Falta .bat, pero existe Fallback .ps1" "Yellow"
            Log "       -> $($t.Path)" "DarkGray"
            Log "       -> Usando: $($t.Fallback)" "DarkGray"
            $fallbackCount++
        } else {
            Log "  [X] MISSING: $($t.Name)" "Red"
            Log "       -> $($t.Path)" "DarkGray"
            $missingCount++
        }
    }
}

Log ""
Log "========================================" "Cyan"
Log " RESUMEN DE AUDITORÍA" "Cyan"
Log "========================================" "Cyan"
Log "  Elementos OK:       $okCount" "Green"
Log "  Elementos Fallback: $fallbackCount" "Yellow"
Log "  Elementos Faltantes:$missingCount" "Red"
Log ""

if ($missingCount -gt 0) {
    Log "[!] ATENCIÓN: Hay rutas rotas. Revisa el reporte y corrige los archivos HTML o ajusta las rutas en el Panel AHK." "Red"
} else {
    Log "[OK] Todas las rutas están funcionales. El panel AHK operará sin errores." "Green"
}

$capture | Set-Clipboard