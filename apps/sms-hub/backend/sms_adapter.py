import subprocess
import os
import json
from datetime import datetime
from pathlib import Path


def _is_termux() -> bool:
    return "com.termux" in os.environ.get("PREFIX", "") or Path("/data/data/com.termux").exists()


ADAPTER = os.environ.get("SMS_ADAPTER", "termux" if _is_termux() else "mock")
LOG_DIR = Path(__file__).parent.parent / "logs"
LOG_DIR.mkdir(exist_ok=True)
SMS_LOG = LOG_DIR / "sms_sent.log"


def _log(ts, to, cmd, adapter, ok, err=""):
    line = f"[{ts}] adapter={adapter} to={to} cmd={cmd!r} ok={ok} {err}"
    with open(SMS_LOG, "a", encoding="utf-8") as f:
        f.write(line + "\n")


def send_sms(numero: str, comando: str, slot: int = 0) -> bool:
    numero = numero.strip()
    ts = datetime.now().isoformat()

    if ADAPTER == "termux":
        try:
            res = subprocess.run(
                ["termux-sms-send", "-n", numero, "-s", str(slot), comando],
                capture_output=True, text=True, timeout=20
            )
            ok = res.returncode == 0
            if not ok and "slot" in (res.stderr or "").lower():
                res = subprocess.run(
                    ["termux-sms-send", "-n", numero, "-s", "1", comando],
                    capture_output=True, text=True, timeout=20
                )
                ok = res.returncode == 0
            _log(ts, numero, comando, "termux", ok)
            return ok
        except Exception as e:
            _log(ts, numero, comando, "termux", False, str(e))
            return False

    _log(ts, numero, comando, "mock", True)
    return True


def read_inbox():
    if ADAPTER != "termux":
        return []
    try:
        res = subprocess.run(
            ["termux-sms-list", "-l", "30", "-t", "inbox"],
            capture_output=True, text=True, timeout=15
        )
        if res.returncode != 0:
            return []
        return json.loads(res.stdout)
    except Exception:
        return []
