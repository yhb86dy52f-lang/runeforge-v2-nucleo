# =====================================================================
# RUNEFORGE_AUDIT_TOPOLOGY.ps1
# Escanea la nueva disposición en G:\ y C:\RUNEFORGE_V2_CORE.
# Identifica herramientas (exe), entornos (toml, json, lock) y tamaños.
# =====================================================================

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

$Buf = New-Object System.Collections.Generic.List[string]
function W($m) { $Buf.Add([string]$m) | Out-Null; Write-Host $m }

W "==================================================================="
W " RUNEFORGE · AUDITORÍA DE TOPOLOGÍA Y HERRAMIENTAS · $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
W "==================================================================="

$PathsToScan = @(
    "G:\WhisperCLI",
    "G:\WhisperTools",
    "G:\TGL-LAB",
    "G:\RUNEFORGE",
    "G:\RUNEFORGE_BACKUPS",
    "G:\RUNEFORGE_BIG_FILES_ARCHIVE",
    "G:\RUNEFORGE_V2_CORE",
    "C:\RUNEFORGE_V2_CORE"
)

foreach ($path in $PathsToScan) {
    if (Test-Path $path) {
        $size = 0
        $files = 0
        try {
            $items = Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue
            $files = $items.Count
            $size = ($items | Measure-Object -Property Length -Sum).Sum
        } catch {}
        
        $sizeMB = [math]::Round($size / 1MB, 2)
        
        W "`n[>] ANALIZANDO: $path"
        W "    Tamaño: $sizeMB MB | Archivos: $files"
        
        # Buscar herramientas y configuraciones clave
        $exes = Get-ChildItem -Path $path -Include *.exe, *.bat, *.ps1, *.py, *.rs, *.toml, *.json -File -Recurse -ErrorAction SilentlyContinue | 
                Select-Object -First 10
        
        if ($exes) {
            W "    [+] Muestras de herramientas/configs encontradas:"
            foreach ($exe in $exes) {
                W "        - $($exe.Name)"
            }
        }
    } else {
        W "`n[!] NO ENCONTRADO: $path"
    }
}

W "`n==================================================================="
W " RESUMEN DE OPERACIÓN"
W "==================================================================="
W " Auditoría completada. Con esta información sabemos qué"
W " herramientas y configuraciones sobrevivieron a la depuración."
W "==================================================================="

Set-Clipboard -Value ($Buf -join "`r`n")
Write-Host "`n[OK] Salida copiada al portapapeles (Ctrl+V)."
