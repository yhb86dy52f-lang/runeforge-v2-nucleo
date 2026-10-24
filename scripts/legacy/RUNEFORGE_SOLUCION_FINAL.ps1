# RUNEFORGE SOLUCION FINAL - AUTONOMO
$ErrorActionPreference="SilentlyContinue"
$ProgressPreference="SilentlyContinue"
$Root=if($PSScriptRoot){$PSScriptRoot}else{(Get-Location).Path}
$Log=[System.Text.StringBuilder]::new()
function L($m){$t=Get-Date -Format "HH:mm:ss";$l="[$t] $m";Write-Host $l -ForegroundColor Green;[void]$Log.AppendLine($l)}
L "--- SOLUCION FINAL HG6145F ---"
L "Root: $Root"

# 1. FIX WINDOWS (MTU 1400 ya te dio HEAD OK)
try{
Get-NetAdapter | Where-Object Status -eq "Up" | ForEach-Object{
netsh interface ipv4 set subinterface $_.Name mtu=1400 store=persistent | Out-Null
Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "Large Send Offload V2 (IPv4)" -DisplayValue "Disabled" -EA SilentlyContinue
Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "Large Send Offload V2 (IPv6)" -DisplayValue "Disabled" -EA SilentlyContinue
Disable-NetAdapterLso -Name $_.Name -IPv4 -IPv6 -EA SilentlyContinue
}
Set-DnsClientServerAddress -InterfaceAlias "Wi-Fi" -ServerAddresses @("1.1.1.1","1.0.0.1") -EA SilentlyContinue
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses @("1.1.1.1","1.0.0.1") -EA SilentlyContinue
L "FIX RED OK: MTU 1400 + LSO OFF + DNS 1.1.1.1"
}catch{}

# 2. WARP - intenta instalar, si falla avisa hotspot
$WarpCli="$env:ProgramFiles\Cloudflare\Cloudflare WARP\warp-cli.exe"
if(!(Test-Path $WarpCli)){
L "WARP no instalado - intentando..."
try{ winget install --id Cloudflare.CloudflareWARP -e --silent --accept-package-agreements --accept-source-agreements | Out-Null; L "winget OK"}catch{L "winget bloqueado por Totalplay"}
if(!(Test-Path $WarpCli)){
L ">>> CONECTA HOTSPOT CELULAR 2 MIN Y CORRE: winget install --id Cloudflare.CloudflareWARP -e"
L ">>> Luego: 'C:\Program Files\Cloudflare\Cloudflare WARP\warp-cli.exe' connect"
}
}else{
try{ & $WarpCli connect 2>&1 | Out-Null; L "WARP Connected"}catch{}
}

# 3. MODELO 1.5GB - EL QUE YA TE JALO A 26.5 MB
$ModelDir=Join-Path $Root "whisper.cpp\models"
$ModelPath=Join-Path $ModelDir "ggml-large-v3-turbo.bin"
$QModelPath=Join-Path $Root "models\ggml-large-v3-turbo-q5_0.bin"
New-Item -ItemType Directory -Force -Path $ModelDir | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path $QModelPath) | Out-Null
L "Descargando modelo 1.5GB en 1MB (tarda ~2h en 15Mbps, no cierres)..."
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

if(Test-Path $ModelPath){$s=(Get-Item $ModelPath).Length; L "Modelo: $([math]::Round($s/1MB,1)) MB $(if($s -gt 1500MB){'OK'}else{'INCOMPLETO - deja corriendo mas tiempo'})"}

# 4. CUANTIZAR
$QuantExe=Join-Path $Root "build\bin\Release\whisper-quantize.exe"
if(!(Test-Path $QuantExe)){$QuantExe=Join-Path $Root "whisper.cpp\build\bin\Release\whisper-quantize.exe"}
if((Test-Path $ModelPath) -and (Test-Path $QuantExe) -and ((Get-Item $ModelPath).Length -gt 1500MB)){
L "Cuantizando..."; & $QuantExe $ModelPath $QModelPath q5_0 2>&1 | ForEach-Object{L $_}
}

L "------------------------"
L "STATUS FINAL"
if(Test-Path $ModelPath){L "[MODEL] large: $([math]::Round((Get-Item $ModelPath).Length/1MB,1)) MB"}
if(Test-Path $QModelPath){L "[MODEL] q5_0: $([math]::Round((Get-Item $QModelPath).Length/1MB,1)) MB"}
if(Test-Path $WarpCli){L "[WARP] Instalado"}else{L "[WARP] Pendiente hotspot"}
L "------------------------"
$final=$Log.ToString()
$final | Set-Clipboard
L "[OK] Copiado portapapeles"
Write-Host $final
