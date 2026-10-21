# =====================================================================
# RUNEFORGE_HTML_DEEP_DIVE.ps1
# Audita el interior de los 4 HTML más pesados (React Artifacts).
# Detecta imágenes en Base64, código inline y dependencias.
# =====================================================================

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

$Buf = New-Object System.Collections.Generic.List[string]
function W($m) { $Buf.Add([string]$m) | Out-Null; Write-Host $m }

W "==================================================================="
W " RUNEFORGE · DISECCIÓN DE HTML GIGANTES · $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
W "==================================================================="

$RootDir = "C:\RUNEFORGE_V2_CORE"
$ReportsDir = Join-Path $RootDir "reports"
$LatestJson = Get-ChildItem -Path $ReportsDir -Filter "html_audit_*.json" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if (-not $LatestJson) {
    W "[!] No se encontró reporte base."
    Set-Clipboard -Value ($Buf -join "`r`n")
    exit 1
}

$data = Get-Content -Path $LatestJson.FullName -Raw | ConvertFrom-Json
$targets = $data | Where-Object { $_.MB -gt 0.4 } | Sort-Object MB -Descending

W "`n[FASE 1] Analizando $($targets.Count) archivos pesados (> 0.4 MB)..."
W "----------------------------------------------------------------------------------------------------"

foreach ($target in $targets) {
    $fullPath = Join-Path $RootDir $target.Ruta.Replace(".", "").Trim()
    if (-not (Test-Path $fullPath)) {
        # Corrección por si la ruta relativa tiene puntos o barras invertidas
        $fullPath = Join-Path $RootDir ($target.Ruta -replace '^\.\\', '')
    }
    
    if (Test-Path $fullPath) {
        $content = Get-Content -Path $fullPath -Raw -ErrorAction SilentlyContinue
        
        if ($content) {
            # 1. Contar imágenes en Base64
            $base64Images = ([regex]::Matches($content, 'data:image/[a-zA-Z]*;base64')).Count
            
            # 2. Contar scripts inline (sin src)
            $inlineScripts = ([regex]::Matches($content, '<script(?![^>]*\bsrc=)[^>]*>')).Count
            
            # 3. Contar hojas de estilo inline
            $inlineStyles = ([regex]::Matches($content, '<style[^>]*>')).Count
            
            # 4. Detectar Frameworks (React, Vue, Angular)
            $framework = "Vanilla"
            if ($content -match 'react') { $framework = "React" }
            elseif ($content -match 'vue') { $framework = "Vue" }
            elseif ($content -match 'angular') { $framework = "Angular" }

            W "`n[>] Archivo: $($target.Ruta)"
            W "    Tamaño  : $($target.MB) MB"
            W "    Framework: $framework"
            W "    Imágenes Base64 : $base64Images"
            W "    Scripts Inline  : $inlineScripts"
            W "    Estilos Inline  : $inlineStyles"
            
            if ($base64Images -gt 5) {
                W "    [!] ALERTA: Tiene muchas imágenes incrustadas. Extraerlas a /assets/ reduciría el peso."
            }
            if ($inlineScripts -gt 1) {
                W "    [!] ALERTA: Tiene JS incrustado. Mover a un archivo .js separado mejoraría el caché."
            }
        }
    }
}

W "`n==================================================================="
W " RESUMEN DE OPERACIÓN"
W "==================================================================="
W " Los archivos evaluados son candidatos para división de código."
W " Extraer imágenes (Base64) y scripts inline son las acciones más"
W " efectivas para reducir su peso sin perder funcionalidad."
W "==================================================================="

Set-Clipboard -Value ($Buf -join "`r`n")
Write-Host "`n[OK] Salida copiada al portapapeles (Ctrl+V)."
