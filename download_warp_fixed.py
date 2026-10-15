import requests, os, time
from pathlib import Path

urls = [
    "https://1111-releases.cloudflareclient.com/win/Cloudflare_WARP_Release-x64.msi",
    "https://downloads.cloudflareclient.com/v1/download/win/generic/Cloudflare_WARP_Release-x64.msi",
    "https://pkg.cloudflareclient.com/Cloudflare_WARP_Release-x64.msi"
]

out = Path("C:/RUNEFORGE_V2_CORE/warp.msi")
if out.exists():
    out.unlink()

headers = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
    "Accept": "*/*",
    "Connection": "keep-alive"
}

success = False
for url in urls:
    print(f"\nProbando URL: {url}")
    for attempt in range(3):
        try:
            print(f"Intento {attempt+1}/3 - conectando...")
            # Descarga directa sin Range, por trozos pequeños de 1MB
            with requests.get(url, headers=headers, stream=True, timeout=60) as r:
                print(f"HTTP {r.status_code} - Content-Length: {r.headers.get('Content-Length','?')}")
                if r.status_code != 200:
                    print(f"Fallo HTTP {r.status_code}, probando siguiente URL...")
                    break
                
                total = int(r.headers.get("Content-Length", 0))
                if total:
                    print(f"Tamaño total: {total/1024/1024:.1f} MB")
                
                downloaded = 0
                with open(out, "wb") as f:
                    for chunk in r.iter_content(chunk_size=1024*1024):  # 1MB chunks
                        if chunk:
                            f.write(chunk)
                            downloaded += len(chunk)
                            if downloaded % (10*1024*1024) == 0:
                                print(f"  -> {downloaded/1024/1024:.1f} MB descargados...")
                
                final = out.stat().st_size
                print(f"FINAL: {final/1024/1024:.1f} MB en {out}")
                if final > 50*1024*1024:  # Debe ser >50MB para ser válido
                    print("OK - MSI válido!")
                    success = True
                    break
                else:
                    print(f"Demasiado pequeño ({final} bytes), reintentando...")
                    time.sleep(2)
                    continue
            
            if success:
                break
                
        except Exception as e:
            print(f"Error: {e}")
            time.sleep(3)
            continue
    
    if success:
        break

if not success:
    print("\nFALLO DIRECTO - Probando con hotspot de celular es necesario")
    print("O usa: winget install Cloudflare.WARP")
else:
    print("\nListo para instalar: msiexec /i warp.msi")
