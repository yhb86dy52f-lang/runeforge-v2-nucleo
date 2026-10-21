# =====================================================================
# RUNEFORGE_AUDIT_FINAL_CLEANUP.ps1
# Valida hashes de los masters, erradica duplicados residuales y
# verifica la integridad de las rutas relativas en el nuevo public/.
# =====================================================================

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

$Buf = New-Object System.Collections.Generic.List[string]
function W($m) { $Buf.Add([string]$m) | Out-Null; Write-Host $m }

W "==================================================================="
W " RUNEFORGE · AUDITORÍA Y SANEAMIENTO FINAL · $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
W "==================================================================="

$RootDir = "C:\RUNEFORGE_V2_CORE"

# 1. Erradicar el duplicado de 1.17 MB en firmware
W "`n[FASE 1] Eliminando archivos residuales en firmware..."
$dupFile = Join-Path $RootDir "firmware\grimorio_x5f_completo_x5f_72_x5f_ia (1).html"
if (Test-Path $dupFile) {
    Remove-Item $dupFile -Force
    W "  [+] Eliminado: grimorio... (1).html (1.17 MB liberados)."
} else {
    W "  [=] Archivo duplicado no encontrado o ya eliminado."
}

# 2. Comparar masters en public/
W "`n[FASE 2] Validando masters en public/..."
$masterPath = Join-Path $RootDir "public\index_master.html"
$finalPath  = Join-Path $RootDir "public\index_master_FINAL.html"

if ((Test-Path $masterPath) -and (Test-Path $finalPath)) {
    $hashMaster = (Get-FileHash $masterPath -Algorithm MD5).Hash
    $hashFinal  = (Get-FileHash $finalPath -Algorithm MD5).Hash
    
    if ($hashMaster -eq $hashFinal) {
        W "  [!] Los archivos 'index_master.html' e 'index_master_FINAL.html' son idénticos."
        W "      Conservando 'index_master_FINAL.html' como fuente única de verdad..."
        Remove-Item $masterPath -Force
        W "      [+] Eliminado 'index_master.html'."
    } else {
        W "  [OK] Los archivos difieren. Se requiere revisión manual."
    }
} else {
    W "  [=] Uno o ambos archivos maestros no existen."
}

# 3. Auditar rutas relativas en el HTML final
W "`n[FASE 3] Auditando rutas de scripts/css en index_master_FINAL.html..."
if (Test-Path $finalPath) {
    $htmlContent = Get-Content -Path $finalPath -Raw
    # Buscar referencias locales (src="..." o href="...") que no sean http/https o data:
    $matches = [regex]::Matches($htmlContent, '(?:src|href)=["''](?!http|data|#|javascript)(.*?)["'']')
    
    if ($matches.Count -gt 0) {
        W "  [>] Dependencias locales detectadas:"
        foreach ($m in $matches) {
            $dep = $m.Groups[1].Value
            # Verificar si el archivo existe en el mismo directorio public/
            $depPath = Join-Path (Split-Path $finalPath -Parent) $dep
            if (-not (Test-Path $depPath)) {
                W "      [!] RUTA ROTA: '$dep' no existe en public/."
                W "          (El archivo pudo haberse quedado en firmware/)."
            } else {
                W "      [OK] Recurso encontrado: $dep"
            }
        }
    } else {
        W "  [OK] El HTML es 100% autocontenido. No hay rutas relativas rotas."
    }
} else {
    W "  [!] No se encontró index_master_FINAL.html para auditar."
}

# 4. Verificar Documentación
W "`n[FASE 4] Verificando documentación..."
$mdPath = Join-Path $RootDir "RUNEFORGE_V2_CORE.md"
if (Test-Path $mdPath) {
    $sizeKB = [math]::Round((Get-Item $mdPath).Length / 1KB, 2)
    W "  [OK] Documento maestro presente: RUNEFORGE_V2_CORE.md ($sizeKB KB)."
} else {
    W "  [!] Falta el documento RUNEFORGE_V2_CORE.md."
}

W "`n==================================================================="
W " RESUMEN DE OPERACIÓN"
W "==================================================================="
W " Auditoría completada. Si se detectaron rutas rotas en FASE 3,"
W " los archivos .js/.css correspondientes deben moverse a public/."
W "==================================================================="

Set-Clipboard -Value ($Buf -join "`r`n")
Write-Host "`n[OK] Salida copiada al portapapeles (Ctrl+V)."
