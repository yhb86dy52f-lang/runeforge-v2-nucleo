$port = 3100
$htmlPath = "C:\RUNEFORGE_V2_CORE\acceso_iphone.html"

$netAdapterTypes = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' -and $_.InterfaceDescription -notlike '*Virtual*' -and $_.InterfaceDescription -notlike '*WSL*' -and $_.InterfaceDescription -notlike '*Hyper-V*' }
$netIPs = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -ne '127.0.0.1' -and $_.IPAddress -notlike '169.254.*' }

$wifiIp = ($netIPs | Where-Object { $_.InterfaceIndex -in $netAdapterTypes.InterfaceIndex -and ($_.IPAddress -like '192.168.*' -or $_.IPAddress -like '10.0.*') }).IPAddress | Select-Object -First 1
if (-not $wifiIp) { $wifiIp = ($netIPs | Where-Object { $_.IPAddress -like '192.168.*' }).IPAddress | Select-Object -First 1 }
$tailscaleIp = ($netIPs | Where-Object { $_.IPAddress -like '100.*' }).IPAddress | Select-Object -First 1

$urls = @()
if ($wifiIp) { $urls += @{ Tipo = "Wi-Fi Local (Misma red de casa)"; Url = "http://${wifiIp}:${port}/forge" } }
if ($tailscaleIp) { $urls += @{ Tipo = "Tailscale VPN (Datos móviles / Fuera)"; Url = "http://${tailscaleIp}:${port}/forge" } }

$htmlContent = @"
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Runeforge - Acceso iPhone</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="p-6 flex flex-col items-center justify-center min-h-screen bg-[#0D0211] text-[#E2D6EE]">
    <div class="max-w-md w-full bg-[#15051C] p-6 rounded-2xl border border-[#39FF14]/30 text-center">
        <h1 class="text-2xl font-bold text-[#39FF14] mb-2">⚡ Runeforge AI - iPhone</h1>
        <p class="text-sm text-gray-400 mb-6">Escanea el código QR con la cámara de tu iPhone para entrar.</p>
        <div class="space-y-6">
"@

foreach ($u in $urls) {
    $encodedUrl = [System.Web.HttpUtility]::UrlEncode($u.Url)
    $qrImgUrl = "https://api.qrserver.com/v1/create-qr-code/?size=220x220&data=${encodedUrl}&color=0D0211&bgcolor=39FF14"
    $htmlContent += @"
            <div class="bg-[#0D0211] p-4 rounded-xl border border-[#BD00FF]/40 flex flex-col items-center">
                <span class="text-xs font-bold text-[#BD00FF] uppercase mb-3">$($u.Tipo)</span>
                <div class="bg-[#39FF14] p-3 rounded-xl shadow-lg">
                    <img src="$qrImgUrl" alt="QR Code" class="w-48 h-48 rounded-lg block" />
                </div>
                <a href="$($u.Url)" target="_blank" class="text-xs text-[#39FF14] underline break-all mt-3 font-mono font-bold">$($u.Url)</a>
            </div>
"@
}

$htmlContent += @"
        </div>
    </div>
</body>
</html>
"@

Add-Type -AssemblyName System.Web
$htmlContent | Out-File -FilePath $htmlPath -Encoding utf8
Start-Process $htmlPath
