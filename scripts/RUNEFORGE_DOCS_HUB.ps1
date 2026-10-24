# ============================================
# RUNEFORGE - DOCS DASHBOARD BUILDER
# ============================================
$ErrorActionPreference = 'Continue'
$capture = New-Object System.Collections.ArrayList

function Log {
    param([string]$m, [string]$c = "White")
    Write-Host $m -ForegroundColor $c
    [void]$capture.Add($m)
}

Log "===============================================" "Cyan"
Log " RUNEFORGE - DOCS DASHBOARD BUILDER" "Cyan"
Log "===============================================" "Cyan"

$rootDir = "C:\RUNEFORGE_V2_CORE"
$docsDir = Join-Path $rootDir "docs\RUNEFORGE_EXPLICADO"
$manifestoPath = Join-Path $rootDir "RUNEFORGE_MANIFESTO.md"
$htmlPath = Join-Path $docsDir "index_docs.html"

# 1. Verificar archivos
$files = @($manifestoPath, (Join-Path $docsDir "01_README_PRINCIPIANTE.md"), (Join-Path $docsDir "02_RUTAS_VALIDADAS.md"), (Join-Path $docsDir "03_DATOS_VALIDADOS.json"))
$missing = $files | Where-Object { -not (Test-Path $_) }

if ($missing) {
    Log "[-] Faltan archivos de documentación: $($missing -join ', ')" "Red"
    $capture | Set-Clipboard
    return
}
Log "[+] Todos los archivos fuente detectados." "Green"

# 2. Leer contenido
$manifesto = Get-Content $manifestoPath -Raw
$readme = Get-Content (Join-Path $docsDir "01_README_PRINCIPIANTE.md") -Raw
$rutas = Get-Content (Join-Path $docsDir "02_RUTAS_VALIDADAS.md") -Raw
$datos = Get-Content (Join-Path $docsDir "03_DATOS_VALIDADOS.json") -Raw

# 3. Generar HTML
Log "[*] Generando Dashboard HTML (Cyber-Mystic Theme)..." "Yellow"

$html = @"
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>RUNEFORGE | Documentación Maestra</title>
    <style>
        :root {
            --bg: #0a0b0f; --surface: #0f1117; --border: #1e2130;
            --accent: #00f5c4; --text: #c8cfe0; --dim: #4a5068;
        }
        body { background: var(--bg); color: var(--text); font-family: 'Consolas', monospace; margin: 0; display: flex; height: 100vh; overflow: hidden; }
        #sidebar { width: 250px; background: var(--surface); border-right: 1px solid var(--border); padding: 20px; display: flex; flex-direction: column; gap: 10px; }
        #sidebar h2 { color: var(--accent); font-size: 16px; margin-bottom: 20px; letter-spacing: 2px; }
        .nav-btn { background: none; border: 1px solid var(--border); color: var(--text); padding: 10px; text-align: left; cursor: pointer; font-family: inherit; transition: 0.2s; border-radius: 6px; }
        .nav-btn:hover, .nav-btn.active { background: var(--border); color: #fff; border-color: var(--accent); }
        #content { flex: 1; padding: 40px; overflow-y: auto; }
        .doc-section { display: none; animation: fadeIn 0.3s ease; }
        .doc-section.active { display: block; }
        h1, h2, h3 { color: var(--accent); }
        pre { background: #000; padding: 15px; border-radius: 8px; border: 1px solid var(--border); overflow-x: auto; color: #00f5c4; }
        code { font-family: 'Consolas', monospace; }
        ul, ol { line-height: 1.6; }
        @keyframes fadeIn { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }
    </style>
</head>
<body>

<div id="sidebar">
    <h2>⚡ RUNEFORGE DOCS</h2>
    <button class="nav-btn active" onclick="showDoc('manifesto')">📜 Manifiesto</button>
    <button class="nav-btn" onclick="showDoc('readme')">📖 README (Principiantes)</button>
    <button class="nav-btn" onclick="showDoc('rutas')">📂 Rutas Validadas</button>
    <button class="nav-btn" onclick="showDoc('json')">💾 Datos (JSON)</button>
</div>

<div id="content">
    <div id="manifesto" class="doc-section active">
        <pre>$manifesto</pre>
    </div>
    <div id="readme" class="doc-section">
        <pre>$readme</pre>
    </div>
    <div id="rutas" class="doc-section">
        <pre>$rutas</pre>
    </div>
    <div id="json" class="doc-section">
        <pre>$datos</pre>
    </div>
</div>

<script>
    function showDoc(id) {
        document.querySelectorAll('.doc-section').forEach(el => el.classList.remove('active'));
        document.querySelectorAll('.nav-btn').forEach(el => el.classList.remove('active'));
        document.getElementById(id).classList.add('active');
        event.target.classList.add('active');
    }
</script>

</body>
</html>
"@

# 4. Guardar y abrir
$html | Set-Content -Path $htmlPath -Encoding UTF8 -Force
Log "[+] Dashboard generado en: $htmlPath" "Green"

Log "[*] Abriendo en el navegador..." "Yellow"
Start-Process $htmlPath

Log "===============================================" "Cyan"
Log "[OK] Proceso finalizado." "Cyan"
$capture | Set-Clipboard
Log "[OK] Reporte copiado al portapapeles (Ctrl+V)." "Cyan"
