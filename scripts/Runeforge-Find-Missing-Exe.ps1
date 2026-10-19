$ErrorActionPreference = "Continue"
$Report = New-Object System.Text.StringBuilder
function Log($msg) { [void]$Report.AppendLine($msg); Write-Host $msg }

$Root = "C:\RUNEFORGE_V2_CORE"

Log "=== BUSCANDO EL EJECUTABLE DE DICTATE STUDIO ==="
# Buscar cualquier .exe que contenga 'dictate' en su nombre, ignorando basura de compilación
$hits = Get-ChildItem $Root -Recurse -Filter "*dictate*.exe" -File -ErrorAction SilentlyContinue | 
    Where-Object { $_.FullName -notmatch '\\node_modules\\' -and $_.FullName -notmatch 'build-script' -and $_.FullName -notmatch 'build_script' }

if ($hits) {
    # Ordenar por fecha de modificación (el más reciente primero)
    $hits = $hits | Sort-Object LastWriteTime -Descending
    foreach ($h in $hits) {
        $mb = [math]::Round($h.Length / 1MB, 2)
        Log ("[OK] Encontrado: {0,-45} ({1} MB)" -f $h.Name, $mb)
        Log ("     Ruta: $($h.FullName)")
    }
    
    $target = $hits | Select-Object -First 1
    Log "`n[Lanzando] El más reciente: $($target.Name)"
    Start-Process $target.FullName
    Log "[OK] Proceso iniciado."
} else {
    Log "[X] No se encontró ningún .exe de DICTATE."
    Log "=== BUSCANDO CUALQUIER EXE RECIENTE (Últimas 2 horas) ==="
    $recent = Get-ChildItem $Root -Recurse -Filter "*.exe" -File -EA SilentlyContinue | 
        Where-Object { $_.LastWriteTime -gt (Get-Date).AddHours(-2) -and $_.FullName -notmatch 'build' }
    if ($recent) {
        foreach ($r in $recent) { Log "Candidato: $($r.FullName) ($($r.LastWriteTime))" }
    } else {
        Log "Ningún .exe modificado en las últimas 2 horas. El build pudo haber fallado al enlazar (link) al final."
    }
}

$txt = $Report.ToString()
Set-Clipboard -Value $txt
Write-Host "`n[OK] Salida copiada al portapapeles." -ForegroundColor Green
