# =====================================================================
# RUNEFORGE_PUSH_FOREGROUND.ps1
# Ejecuta el push de forma visible para capturar ventanas de login
# y forzar la actualización en GitHub.
# =====================================================================

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

$Buf = New-Object System.Collections.Generic.List[string]
function W($m) { $Buf.Add([string]$m) | Out-Null; Write-Host $m }

W "==================================================================="
W " RUNEFORGE · PUSH EN PRIMER PLANO · $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
W "==================================================================="

$GitRoot = "C:\RUNEFORGE_V2_CORE"
Set-Location $GitRoot

# 1. Matar procesos colgados
W "`n[FASE 1] Limpiando procesos de Git colgados..."
Stop-Process -Name "git" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1
W "[+] Listo."

# 2. Verificar la URL del repositorio
W "`n[FASE 2] Verificando conexión remota..."
$remoteUrl = git remote get-url origin 2>&1
W "  URL de GitHub: $remoteUrl"

# 3. Hacer el Push (En primer plano)
W "`n[FASE 3] Subiendo cambios (Si ves una ventana pidiendo inicio de sesión, por favor acéptala)..."
W "  -> Iniciando push..."
# Ejecutamos sin Job para que GCM muestre la ventana si es necesario
$pushOut = git push origin main 2>&1
$exitCode = $LASTEXITCODE

W "`n[FASE 4] Resultado del Push:"
W $pushOut

if ($exitCode -eq 0) {
    W "`n[+] ¡ÉXITO! Tus cambios están en GitHub."
} else {
    W "`n[!] El push falló o se canceló."
    W "    Si fue por credenciales, intenta ejecutar esto manualmente:"
    W "    git push origin main"
}

W "`n==================================================================="
W " FIN DEL PROCESO"
W "==================================================================="

Set-Clipboard -Value ($Buf -join "`r`n")
Write-Host "`n[OK] Salida copiada al portapapeles (Ctrl+V)."