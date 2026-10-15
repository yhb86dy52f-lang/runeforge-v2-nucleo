"""
haystack_decoder_v2.py — Validador RUNEFORGE COLLAB v2.0
Contrato E2E:
    EID = AES-128-ECB(SK, epoch_BE(4) || device_id[:4] || 0x00*8)[:8]

Uso:
    # 1. Ver ventana de EIDs (debug)
    python haystack_decoder_v2.py --sk 123456789ABCDEF01122334455667788 --epoch-now

    # 2. Validar reportes capturados de MQTT
    mosquitto_sub -h 192.168.100.5 -t "scannerpro/#" -v > mqtt.json
    python haystack_decoder_v2.py --sk 123456789ABCDEF01122334455667788 --scan-log mqtt.json
"""
import argparse, json, time, sys
from Crypto.Cipher import AES

EPOCH_SECONDS = 300
DEFAULT_DEVICE_ID = "RF-01"


def gen_eid(sk_bytes: bytes, epoch: int, device_id: str = DEFAULT_DEVICE_ID) -> bytes:
    inp = bytearray(16)
    inp[0] = (epoch >> 24) & 0xFF
    inp[1] = (epoch >> 16) & 0xFF
    inp[2] = (epoch >>  8) & 0xFF
    inp[3] =  epoch        & 0xFF
    inp[4:8] = device_id.encode()[:4]
    cipher = AES.new(sk_bytes, AES.MODE_ECB)
    return cipher.encrypt(bytes(inp))[:8]


def gen_eid_hex(sk_bytes: bytes, epoch: int, device_id: str = DEFAULT_DEVICE_ID) -> str:
    return gen_eid(sk_bytes, epoch, device_id).hex().upper()


def validate_report(report: dict, sk_bytes: bytes, device_id: str, window: int = 5):
    """
    Retorna (ok: bool, delta: int|None, expected_eid: str|None)
    Si el reporte trae 'epoch', valida contra ese epoch ± window.
    Si no trae, valida contra el epoch del host ± window.
    """
    eid_claim = str(report.get("eid", "")).upper()
    if not eid_claim:
        return False, None, None

    epoch = report.get("epoch")
    if epoch is None or int(epoch) == 0:
        base = int(time.time() // EPOCH_SECONDS)
    else:
        base = int(epoch)

    for d in range(-window, window + 1):
        exp = gen_eid_hex(sk_bytes, base + d, device_id)
        if exp == eid_claim:
            return True, d, exp
    return False, None, None


def iter_scan_log(path: str):
    """Acepta JSON-lines, JSON array, o líneas MQTT estilo 'topic {json}'."""
    with open(path, "r", encoding="utf-8") as f:
        buf = f.read().strip()
    if not buf:
        return
    if buf.startswith("["):
        for obj in json.loads(buf):
            if isinstance(obj, dict):
                yield obj
        return
    for line in buf.splitlines():
        line = line.strip()
        if not line:
            continue
        i = line.find("{")
        if i < 0:
            continue
        try:
            yield json.loads(line[i:])
        except json.JSONDecodeError:
            continue


def main():
    ap = argparse.ArgumentParser(description="RUNEFORGE EID validator v2.0")
    ap.add_argument("--sk", required=True,
                    help="16-byte SK hex, ej: 123456789ABCDEF01122334455667788")
    ap.add_argument("--device-id", default=DEFAULT_DEVICE_ID,
                    help=f"Device ID (default {DEFAULT_DEVICE_ID})")
    ap.add_argument("--epoch", type=int, default=None,
                    help="epoch explícito (default: ahora / 300)")
    ap.add_argument("--epoch-now", action="store_true",
                    help="imprime ventana de EIDs alrededor del epoch actual")
    ap.add_argument("--window", type=int, default=5,
                    help="ventana ± epochs (default 5)")
    ap.add_argument("--scan-log", default=None,
                    help="archivo JSON/JSONL con reportes MQTT a validar")
    args = ap.parse_args()

    if len(args.sk) != 32:
        sys.exit(f"[!] SK debe ser 32 hex chars, tengo {len(args.sk)}")
    sk_bytes = bytes.fromhex(args.sk)

    # Modo validación de log
    if args.scan_log:
        ok = fail = 0
        for rep in iter_scan_log(args.scan_log):
            fam = rep.get("family")
            if fam not in (None, "runeforge"):
                continue
            valid, delta, exp = validate_report(
                rep, sk_bytes, args.device_id, args.window)
            tag = "✅ OWN   " if valid else "❌ REJECT"
            if valid: ok += 1
            else:     fail += 1
            print(f"{tag} eid={rep.get('eid','-')} "
                  f"mac={rep.get('mac','-')} "
                  f"epoch={rep.get('epoch','-')} "
                  f"delta={delta} "
                  f"rssi={rep.get('rssi_kalman','-')} "
                  f"finder={rep.get('finder_id','-')}")
        print(f"\n[+] Total: {ok+fail}  OWN={ok}  REJECT={fail}")
        return

    # Modo ventana (--epoch-now)
    epoch_now = args.epoch if args.epoch is not None \
                else int(time.time() // EPOCH_SECONDS)
    print(f"[+] SK {args.sk}  device_id={args.device_id}  "
          f"epoch_now={epoch_now} ({time.ctime(epoch_now * EPOCH_SECONDS)})")
    for d in range(-args.window, args.window + 1):
        e = epoch_now + d
        print(f"  epoch {e} {d:+d} -> EID {gen_eid_hex(sk_bytes, e, args.device_id)}")
    print("\n[+] NOTA: si el Tag usa millis() en vez de NTP, su epoch arranca en 0.")
    print("    Usa --epoch 0 para verificar la primera rotación.")


if __name__ == "__main__":
    main()