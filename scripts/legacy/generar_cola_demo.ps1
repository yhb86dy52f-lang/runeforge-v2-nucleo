param(
    [string]$Telefono = "+5210000000000",
    [string]$OutPath = "G:\TELEMETRIA\PROYECTO ATAJOS\config\cola_sms.generated.json"
)

$comandos = @("!R0","!R5","!RR","!RA")

$obj = [ordered]@{
    activo = $true
    telefono = $Telefono
    indice_actual = 0
    comandos = $comandos
    ultimo_enviado = $comandos[0]
    ultimo_recibido = ""
    modo_validacion = "mismo_remitente"
}

$obj | ConvertTo-Json -Depth 5 | Set-Content -Path $OutPath -Encoding UTF8
Write-Host "Cola generada: $OutPath"
