
"""
haystack_decoder.py - Decoder RUNEFORGE COLLAB v1.0
Deriva EIDs pasados/futuros a partir de SK secreta, valida reportes MQTT del ScannerPRO
Compatible con prototipo ESP32 TAG (AES-128 ECB, epoch 300s)

Uso:
  python haystack_decoder.py --sk 123456789ABCDEF01122334455667788 --epoch-now --scan-log mqtt.json
"""

import argparse, json, time
from Crypto.Cipher import AES

EPOCH_SECONDS = 300

def gen_eid(sk_bytes, epoch, device_id="RF-01"):
    inp = bytearray(16)
    inp[0] = (epoch >> 24) & 0xFF
    inp[1] = (epoch >> 16) & 0xFF
    inp[2] = (epoch >> 8) & 0xFF
    inp[3] = epoch & 0xFF
    inp[4:8] = device_id.encode()[:4]
    cipher = AES.new(sk_bytes, AES.MODE_ECB)
    full = cipher.encrypt(bytes(inp))
    return full[:8]

def gen_eid_hex(sk_hex, epoch):
    sk = bytes.fromhex(sk_hex)
    eid = gen_eid(sk, epoch)
    return eid.hex().upper()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="RUNEFORGE EID decoder")
    parser.add_argument("--sk", required=True, help="16-byte SK hex, ej: 123456789ABCDEF01122334455667788")
    parser.add_argument("--epoch", type=int, default=None, help="epoch number, default now/300")
    parser.add_argument("--window", type=int, default=10, help="ventana +/- epochs para validar drift")
    args = parser.parse_args()

    epoch_now = args.epoch or int(time.time() // EPOCH_SECONDS)
    print(f"[+] SK {args.sk} EPOCH_NOW {epoch_now} ({time.ctime(epoch_now*EPOCH_SECONDS)})")
    
    sk_bytes = bytes.fromhex(args.sk)
    for delta in range(-args.window, args.window+1):
        e = epoch_now + delta
        eid = gen_eid(sk_bytes, e)
        print(f"  epoch {e} {delta:+d} -> EID {eid.hex().upper()}  ts {time.ctime(e*EPOCH_SECONDS)}")

    print("\n[+] Para validar reporte MQTT del ScannerPRO:")
    print("    Si Scanner reporta eid AABBCCDD... y está en esta lista, es tu TAG. Solo tú con SK puedes generarla.")
    print("[+] E2E: La ubicación GPS del finder nunca sale del ESP32 en claro si cifras con clave del owner (siguiente fase: ECIES P-224)")
