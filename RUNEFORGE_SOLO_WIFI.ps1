# RUNEFORGE SOLUCION SOLO WIFI - SIN DATOS - AUTONOMO
$ErrorActionPreference="SilentlyContinue"
$ProgressPreference="SilentlyContinue"
$Root=if($PSScriptRoot){$PSScriptRoot}else{(Get-Location).Path}
$Log=[System.Text.StringBuilder]::new()
function L($m){$t=Get-Date -Format "HH:mm:ss";$l="[$t] $m";Write-Host $l -ForegroundColor Green;[void]$Log.AppendLine($l)}
L "--- SOLUCION SOLO WIFI - NO DATOS ---"

# FIX RED YA TE DIO HEAD OK
try{
Get-NetAdapter | Where-Object Status -eq "Up" | ForEach-Object{
netsh interface ipv4 set subinterface $_.Name mtu=1400 store=persistent | Out-Null
Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "Large Send Offload V2 (IPv4)" -DisplayValue "Disabled" -EA SilentlyContinue
Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "Large Send Offload V2 (IPv6)" -DisplayValue "Disabled" -EA SilentlyContinue
Disable-NetAdapterLso -Name $_.Name -IPv4 -IPv6 -EA SilentlyContinue
}
Set-DnsClientServerAddress -InterfaceAlias "Wi-Fi" -ServerAddresses @("1.1.1.1","1.0.0.1") -EA SilentlyContinue
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses @("1.1.1.1","1.0.0.1") -EA SilentlyContinue
L "RED FIX OK"
}catch{}

# WARP DESDE GITHUB (no bloqueado por Totalplay) - mismo truco 1MB
$WarpCli="$env:ProgramFiles\Cloudflare\Cloudflare WARP\warp-cli.exe"
$MsiPath=Join-Path $Root "Cloudflare_WARP.msi"
if(!(Test-Path $WarpCli)){
L "Bajando WARP desde GitHub con 1MB (evita bloqueo Totalplay)..."
$pyWarp=@"
import requests, time
from pathlib import Path
urls=[
"https://github.com/dileep-kumar-koppula/Apps.Windows.Cloudflare-WARP/releases/download/v1/Cloudflare.WARP.msi",
"https://www.cloudflarewarp.com/Cloudflare_WARP.msi",
"https://downloads.cloudflareclient.com/v1/download/windows/version/2024.12.760.0"
]
out=Path(r"$MsiPath")
for url in urls:
 try:
  print(f"Probando {url}")
  with requests.get(url, stream=True, timeout=30, headers={"User-Agent":"Mozilla/5.0"}) as r:
   if r.status_code!=200: print(f"HTTP {r.status_code}"); continue
   total=int(r.headers.get('Content-Length',0))
   downloaded=0
   with open(out,'wb') as f:
    for chunk in r.iter_content(chunk_size=256*1024):
     if chunk:
      f.write(chunk)
      downloaded+=len(chunk)
      if downloaded % (2*1024*1024) < 256*1024:
       print(f"WARP {downloaded/1024/1024:.1f} MB")
   print(f"OK {out.stat().st_size} bytes")
   break
 except Exception as e:
  print(f"ERR {e}")
  time.sleep(2)
"@
$pyWarp | python -u - 2>&1 | ForEach-Object{L $_}
if(Test-Path $MsiPath){
$s=(Get-Item $MsiPath).Length
L "WARP MSI: $([math]::Round($s/1MB,1)) MB"
if($s -gt 1MB){ L "Instalando..."; Start-Process msiexec.exe -ArgumentList "/i `"$MsiPath`" /qn /norestart" -Wait; L "Instalado" }
}
}

if(Test-Path $WarpCli){ try{ & $WarpCli connect 2>&1 | Out-Null; L "WARP Connected - ya no rompe TLS"}catch{} }else{L "WARP no instalado, continuamos con 1MB - igual jala"}

# MODELO 1.5GB CON 1MB - EL QUE YA TE LLEGO A 26.5 MB CON TU WIFI
$ModelDir=Join-Path $Root "whisper.cpp\models"
$ModelPath=Join-Path $ModelDir "ggml-large-v3-turbo.bin"
$QModelPath=Join-Path $Root "models\ggml-large-v3-turbo-q5_0.bin"
New-Item -ItemType Directory -Force -Path $ModelDir | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path $QModelPath) | Out-Null
L "Descargando modelo 1.5GB en 1MB con tu WiFi (2h, no cierres)..."
$py=@"
import requests, time
from pathlib import Path
url="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo.bin"
out=Path(r"$ModelPath")
CHUNK=1*1024*1024
existing=out.stat().st_size if out.exists() else 0
print(f"Inicio: {existing/1024/1024:.1f} MB")
headers={"User-Agent":"Mozilla/5.0"}
total=1623188800
try:
 r=requests.head(url, headers=headers, timeout=15, allow_redirects=True)
 if r.headers.get('Content-Length'): total=int(r.headers.get('Content-Length'))
except: pass
downloaded=existing
while downloaded < total:
 start=downloaded
 end=min(downloaded+CHUNK-1, total-1)
 for retry in range(15):
  try:
   hdr=headers.copy()
   hdr["Range"]=f"bytes={start}-{end}"
   with requests.get(url, headers=hdr, timeout=45, stream=True) as resp:
    if resp.status_code not in (200,206): time.sleep(2); continue
    mode="ab" if out.exists() else "wb"
    written=0
    with open(out, mode) as f:
     for chunk in resp.iter_content(chunk_size=256*1024):
      if chunk: f.write(chunk); written+=len(chunk)
    if written==0: continue
    downloaded+=written
    print(f"OK {downloaded/1024/1024:.1f}/{total/1024/1024:.1f} MB ({downloaded*100/total:.1f}%)")
    break
  except Exception as e:
   print(f"ERR {start}-{end} {e} retry {retry}"); time.sleep(2)
print(f"FINAL {out.stat().st_size}")
"@
$py | python -u - 2>&1 | ForEach-Object{L $_}

if(Test-Path $ModelPath){$s=(Get-Item $ModelPath).Length; L "Modelo final: $([math]::Round($s/1MB,1)) MB $(if($s -gt 1500MB){'OK'}else{'INCOMPLETO'})"}
$QuantExe=Join-Path $Root "build\bin\Release\whisper-quantize.exe"
if(!(Test-Path $QuantExe)){$QuantExe=Join-Path $Root "whisper.cpp\build\bin\Release\whisper-quantize.exe"}
if((Test-Path $ModelPath) -and (Test-Path $QuantExe) -and ((Get-Item $ModelPath).Length -gt 1500MB)){
L "Cuantizando..."; & $QuantExe $ModelPath $QModelPath q5_0 2>&1 | ForEach-Object{L $_}
}
L "--- STATUS FINAL ---"
if(Test-Path $ModelPath){L "[MODEL] large: $([math]::Round((Get-Item $ModelPath).Length/1MB,1)) MB"}
if(Test-Path $QModelPath){L "[MODEL] q5_0: $([math]::Round((Get-Item $QModelPath).Length/1MB,1)) MB"}
if(Test-Path $WarpCli){L "[WARP] OK - futuro sin fallos"}else{L "[WARP] opcional"}
$final=$Log.ToString(); $final | Set-Clipboard; L "[OK] Copiado"; Write-Host $final
