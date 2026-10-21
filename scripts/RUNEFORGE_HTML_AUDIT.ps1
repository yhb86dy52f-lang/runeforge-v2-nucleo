# =====================================================================
# RUNEFORGE_HTML_AUDIT.ps1
# Escanea la raíz, extrae los HTML más pesados, analiza su contenido
# (título, cantidad de scripts) y los clasifica.
# =====================================================================

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

$Buf = New-Object System.Collections.Generic.List[string]
function W($m) { $Buf.Add([string]$m) | Out-Null; Write-Host $m }

W "==================================================================="
W " RUNEFORGE · AUDITORÍA DE HTML PESADOS · $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
W "==================================================================="

$RootDir = "C:\RUNEFORGE_V2_CORE"
Set-Location $RootDir

# 1. Buscar todos los .html excluyendo basura
W "`n[FASE 1] Escaneando archivos HTML (excluyendo node_modules, .git, target)..."
$htmlFiles = Get-ChildItem -Path $RootDir -Filter "*.html" -Recurse -File -ErrorAction SilentlyContinue | 
    Where-Object { 
        $_.FullName -notmatch '\\node_modules\\' -and 
        $_.FullName -notmatch '\\\.git\\' -and 
        $_.FullName -notmatch '\\target\\' -and 
        $_.FullName -notmatch '\\venv\\' -and 
        $_.FullName -notmatch '\\build\\' 
    }

W "  [+] Archivos encontrados: $($htmlFiles.Count)"

# 2. Extraer metadatos y clasificar
W "`n[FASE 2] Analizando contenido y clasificando..."
$results = @()

foreach ($file in $htmlFiles) {
    $sizeMB = [math]::Round($file.Length / 1MB, 2)
    
    # Leer solo los primeros 5000 caracteres para evitar colapsar la RAM con archivos gigantes
    $contentSnippet = ""
    try {
        $contentSnippet = Get-Content -Path $file.FullName -TotalCount 100 -ErrorAction SilentlyContinue | Out-String
    } catch {}

    # Extraer Título
    $title = "Sin Título"
    $titleMatch = [regex]::Match($contentSnippet, '(?i)<title>(.*?)</title>')
    if ($titleMatch.Success) {
        $title = $titleMatch.Groups[1].Value.Trim()
    }

    # Contar Scripts y Links (indicio de SPA o Dashboard)
    $scriptCount = ([regex]::Matches($contentSnippet, '(?i)<script')).Count
    $linkCount   = ([regex]::Matches($contentSnippet, '(?i)<link')).Count

    # Clasificación heurística
    $type = "Estático / Docs"
    if ($sizeMB -gt 0.5 -and $scriptCount -gt 5) { $type = "SPA / Tauri Frontend" }
    elseif ($sizeMB -gt 0.1 -and $linkCount -gt 3) { $type = "Dashboard / Panel" }
    elseif ($file.FullName -match "\\dist\\") { $type = "Build Output (Revisar)" }

    $results += [PSCustomObject]@{
        "MB"      = $sizeMB
        "Tipo"    = $type
        "Titulo"  = $title
        "Scripts" = $scriptCount
        "Ruta"    = $file.FullName.Replace($RootDir, ".")
    }
}

# 3. Mostrar Top 20 (los más pesados)
W "`n[FASE 3] TOP 20 HTML MÁS PESADOS:"
$top20 = $results | Sort-Object MB -Descending | Select-Object -First 20

# Formatear tabla para consola
$top20 | Format-Table -AutoSize -Property MB, Tipo, Titulo, Scripts, Ruta | Out-String | Write-Host

# 4. Guardar reporte en JSON
W "`n[FASE 4] Guardando reporte JSON..."
$reportDir = Join-Path $RootDir "reports"
New-Item -ItemType Directory -Force -Path $reportDir | Out-Null
$jsonPath = Join-Path $reportDir "html_audit_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
$results | ConvertTo-Json -Depth 3 | Set-Content -Path $jsonPath -Encoding UTF8
W "  [+] Reporte guardado en: $jsonPath"

W "`n==================================================================="
W " RESUMEN DE OPERACIÓN"
W "==================================================================="
W " 1. Se escanearon $($htmlFiles.Count) archivos HTML en la raíz."
W " 2. Se aislaron los 20 más pesados para análisis."
W " 3. Los candidatos a mejora son los clasificados como 'SPA / Tauri'."
W "==================================================================="

Set-Clipboard -Value ($Buf -join "`r`n")
Write-Host "`n[OK] Salida copiada al portapapeles (Ctrl+V)."
