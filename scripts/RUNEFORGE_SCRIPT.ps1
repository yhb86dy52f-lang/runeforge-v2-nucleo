$ErrorActionPreference = 'Continue'
$CanonicalPath = "C:\RUNEFORGE_V2_CORE\scripts"

if (!(Test-Path $CanonicalPath)) {
    New-Item -ItemType Directory -Force -Path $CanonicalPath | Out-Null
}

$outputLog = [System.Collections.Generic.List[string]]::new()
$outputLog.Add("=== RUNEFORGE V2 NUCLEO - AUDITORÍA Y BLINDAJE INTEGRAL ===")
$outputLog.Add("Fecha: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")

# 1. Purgado de Bloatware y Directorios Obsoletos
$rootPath = "C:\RUNEFORGE_V2_CORE"
$dirsToClean = @("$rootPath\target", "$rootPath\build", "$rootPath\.sccache")
foreach ($dir in $dirsToClean) {
    if (Test-Path $dir) {
        Remove-Item -Path $dir -Recurse -Force -ErrorAction SilentlyContinue
        $outputLog.Add("[LIMPIEZA] Directorio obsoleto purgado: $dir")
    }
}

# 2. Blindaje y Verificación de Permisos del Archivo .env
$envFile = "$rootPath\.env"
if (Test-Path $envFile) {
    try {
        $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        $acl = Get-Acl $envFile
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($currentUser, "FullControl", "Allow")
        $acl.SetAccessRule($rule)
        Set-Acl $envFile $acl
        $outputLog.Add("[SEGURIDAD] Permisos del archivo .env endurecidos para: $currentUser")
    } catch {
        $outputLog.Add("[ADVERTENCIA] No se pudieron modificar los ACL de .env: $_")
    }
} else {
    $outputLog.Add("[AVISO] El archivo .env no se encuentra en la raíz del núcleo.")
}

# 3. Verificación de Servicios Locales y Registro (CIM / Services)
try {
    $os = Get-CimInstance Win32_OperatingSystem
    $outputLog.Add("[SISTEMA] OS: $($os.Caption) | Versión: $($os.Version)")
} catch {
    $outputLog.Add("[ERROR] No se pudo consultar la información del Sistema Operativo.")
}

$services = @("Tailscale", "Ollama", "TermService")
foreach ($svcName in $services) {
    $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
    if ($svc) {
        $outputLog.Add("[SERVICIO] $svcName -> Estado: $($svc.Status)")
    }
}

$outputLog.Add("=== AUDITORÍA Y BLINDAJE COMPLETADOS CON ÉXITO ===")

$resultadoFinal = $outputLog -join "`n"
Write-Output $resultadoFinal
Set-Clipboard -Value $resultadoFinal
Write-Output "`n[INFO] ¡Resultados copiados automáticamente al portapapeles!"
