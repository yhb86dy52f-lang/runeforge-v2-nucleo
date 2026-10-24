param(
    [Parameter(Mandatory=$true)]
    [string]$Telefono,

    [Parameter(Mandatory=$true)]
    [string]$TxtComandosPath,

    [string]$OutPath = "G:\TELEMETRIA\PROYECTO ATAJOS\config\cola_sms.real.json"
)

if (-not (Test-Path $TxtComandosPath)) {
    Write-Error "No existe el archivo de comandos: $TxtComandosPath"
    exit 1
}

$comandos = Get-Content $TxtComandosPath -Encoding UTF8 |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ -ne "" }

if ($comandos.Count -eq 0) {
    Write-Error "La lista de comandos está vacía."
    exit 1
}

$obj = [ordered]@{
    activo = $true
    telefono = $Telefono
    indice_actual = 0
    comandos = $comandos
    ultimo_enviado = $comandos[0]
    ultimo_recibido = ""
    modo_validacion = "mismo_remitente"
}

$obj | ConvertTo-Json -Depth 6 | Set-Content -Path $OutPath -Encoding UTF8

Write-Host "Cola real generada:" -ForegroundColor Green
Write-Host $OutPath -ForegroundColor Cyan