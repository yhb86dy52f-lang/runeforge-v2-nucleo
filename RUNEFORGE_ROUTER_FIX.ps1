# RUNEFORGE ROUTER FIX HG6145F - AUTONOMO
$ErrorActionPreference="SilentlyContinue"
$ProgressPreference="SilentlyContinue"
$Root=if($PSScriptRoot){$PSScriptRoot}else{(Get-Location).Path}
$Log=[System.Text.StringBuilder]::new()
function L($m){$t=Get-Date -Format "HH:mm:ss";$l="[$t] $m";Write-Host $l -ForegroundColor Green;[void]$Log.AppendLine($l)}
L "--- FIX HG6145F RP4379 Totalplay ---"
L "Router: HG6145F GPON FHITBA9A3E60 HWTC 32% RAM"

# 1. FIX WINDOWS PARA COMPENSAR BUG HG6145F
try{
# MTU 1400 para evitar fragmentacion que rompe TLS
Get-NetAdapter | Where-Object Status -eq "Up" | ForEach-Object{
 L "Adaptador $($_.Name) -> MTU 1400 + LSO OFF + DNS 1.1.1.1"
 netsh interface ipv4 set subinterface $_.Name mtu=1400 store=persistent | Out-Null
 Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "Large Send Offload V2 (IPv4)" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
 Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "Large Send Offload V2 (IPv6)" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
 Disable-NetAdapterLso -Name $_.Name -IPv4 -IPv6 -ErrorAction SilentlyContinue
 # Jumbo Packet off
 Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "Jumbo Packet" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
}
# DNS Cloudflare para bypass proxy Totalplay
Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -notlike "vEthernet*"} | ForEach-Object{
 Set-DnsClientServerAddress -InterfaceAlias $_.InterfaceAlias -ServerAddresses @("1.1.1.1","1.0.0.1") -ErrorAction SilentlyContinue
 L "DNS $($_.InterfaceAlias) -> 1.1.1.1"
}
# Desactivar IPv6 temporal (HG6145F tiene bug IPv6)
Set-NetAdapterBinding -Name "*" -ComponentID ms_tcpip6 -Enabled $false -ErrorAction SilentlyContinue
L "IPv6 desactivado temporal para prueba"
}catch{L "ERR red: $_"}

# 2. TEST TLS
L "Testeando TLS grande..."
try{
 $r=Invoke-WebRequest https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo.bin -Method Head -TimeoutSec 10
 L "HEAD OK: $($r.Headers['Content-Length']) bytes"
}catch{L "HEAD FAIL (normal con Totalplay): $_"}

# 3. INSTRUCCIONES HG6145F (manual, no se puede por script)
L "------------------------"
L "FIX MANUAL EN http://192.168.1.254 (admin / contrasena en etiqueta)"
L "1. Network -> WAN -> tu conexion INTERNET -> MTU 1400 (no 1492/1500)"
L "2. Network -> WAN -> DNS manual 1.1.1.1 / 1.0.0.1 (quita el de Totalplay)"
L "3. Security -> ALG -> desactiva SIP ALG, RTSP ALG"
L "4. Application -> UPnP -> desactivado"
L "5. Management -> TR069 -> desactiva si puedes (es el que hace DPI)"
L "6. REINICIA ONT: Management -> Reboot"
L "------------------------"
L "FIX DEFINITIVO: Pon HG6145F en BRIDGE y usa tu propio router"
L "Network -> WAN -> Mode Bridge -> VLAN 0? (Totalplay usa VLAN 0 en algunos)"
L "Luego tu router hace PPPoE con usuario: noauth y pass noauth o tus credenciales"
L "O mas facil: WARP con hotspot 2min y se acaba"
L "------------------------"

L "--- STATUS ---"
try{$a=Get-NetAdapter | Where-Object Status -eq "Up" | Select-Object -First 1; $m=netsh interface ipv4 show subinterface | Select-String $a.Name; L "MTU actual: $m"}catch{}
try{$d=Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object {$_.ServerAddresses -contains "1.1.1.1"}; L "DNS 1.1.1.1 activo en $($d.InterfaceAlias)"}catch{L "DNS no aplicado"}
L "------------------------"
$final=$Log.ToString()
$final | Set-Clipboard
L "[OK] Copiado al portapapeles"
Write-Host $final
