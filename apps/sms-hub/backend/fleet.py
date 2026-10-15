import sqlite3
from pathlib import Path
from sms_adapter import send_sms


DB = Path(__file__).parent.parent / "data" / "unidades.db"
DB.parent.mkdir(exist_ok=True)

IP_CANON = "94.130.84.182"
PUERTO_CANON = "20785"
APN = "INTERNET.ITELCEL.COM"


def init_db():
    con = sqlite3.connect(DB)
    con.execute("""
        CREATE TABLE IF NOT EXISTS unidades (
            unidad TEXT PRIMARY KEY,
            numero TEXT,
            ip TEXT,
            estatus TEXT,
            ultimo_comando TEXT,
            ultimo_ro TEXT,
            fecha_ultimo TEXT,
            inb TEXT,
            com TEXT,
            gps TEXT
        )
    """)
    con.commit()
    con.close()


def list_units():
    con = sqlite3.connect(DB)
    rows = con.execute(
        "SELECT unidad, numero, estatus, ultimo_comando, fecha_ultimo FROM unidades ORDER BY unidad"
    ).fetchall()
    con.close()
    return [
        {"unidad": r[0], "numero": r[1], "estatus": r[2],
         "ultimo_comando": r[3], "fecha_ultimo": r[4]}
        for r in rows
    ]


def get_unit(ident):
    con = sqlite3.connect(DB)
    row = con.execute(
        "SELECT unidad, numero FROM unidades WHERE unidad=? OR numero LIKE ?",
        (ident, f"%{ident}%")
    ).fetchone()
    con.close()
    return row


def _iter_targets(target=None):
    con = sqlite3.connect(DB)
    if target:
        row = get_unit(target)
        con.close()
        if row:
            yield row
        else:
            yield ("(directo)", target)
    else:
        rows = con.execute("SELECT unidad, numero FROM unidades").fetchall()
        con.close()
        for r in rows:
            yield r


def _send_safe(numero, cmd):
    if not numero or "XXXX" in numero:
        return False
    return send_sms(numero, cmd)


def diagnose_all(target=None):
    results = []
    for unidad, numero in _iter_targets(target):
        r0 = _send_safe(numero, "!R0")
        r5 = _send_safe(numero, "!R5")
        results.append({"unidad": unidad, "numero": numero, "r0": r0, "r5": r5})
    return {"results": results}


def activate_paro(slot, masivo=True, target=None):
    return _paro_command(f"!R3,8,{slot}", masivo, target)


def deactivate_paro(slot, masivo=True, target=None):
    return _paro_command(f"!R3,9,{slot}", masivo, target)


def activate_paro_especial(masivo=True, target=None):
    return _paro_doble("!R3,8,0", "!R3,8,2", masivo, target)


def deactivate_paro_especial(masivo=True, target=None):
    return _paro_doble("!R3,9,0", "!R3,9,2", masivo, target)


def _paro_command(cmd, masivo, target):
    results = []
    tgt = None if masivo else target
    for unidad, numero in _iter_targets(tgt):
        ok = _send_safe(numero, cmd)
        results.append({"unidad": unidad, "numero": numero, "cmd": cmd, "ok": ok})
    return {"command": cmd, "results": results}


def _paro_doble(c1, c2, masivo, target):
    results = []
    tgt = None if masivo else target
    for unidad, numero in _iter_targets(tgt):
        ok1 = _send_safe(numero, c1)
        ok2 = _send_safe(numero, c2)
        results.append({"unidad": unidad, "numero": numero, "c1": c1, "c2": c2, "ok1": ok1, "ok2": ok2})
    return {"command": f"{c1} + {c2}", "results": results}


def import_csv_text(csv_text: str, default_ip=None) -> dict:
    import csv as _csv
    from io import StringIO
    if default_ip is None:
        default_ip = IP_CANON
    reader = _csv.DictReader(StringIO(csv_text))
    con = sqlite3.connect(DB)
    inserted = 0
    skipped = 0
    errors = []
    for row in reader:
        unidad = (row.get("unidad") or "").strip()
        numero = (row.get("numero") or "").strip()
        ip = (row.get("ip") or "").strip() or default_ip
        if not unidad or not numero or "XXXX" in numero:
            skipped += 1
            continue
        try:
            con.execute(
                "INSERT OR REPLACE INTO unidades (unidad, numero, ip) VALUES (?,?,?)",
                (unidad, numero, ip),
            )
            inserted += 1
        except Exception as e:
            errors.append(str(e))
    con.commit()
    con.close()
    return {"inserted": inserted, "skipped": skipped, "errors": errors}


def export_csv_text() -> str:
    from io import StringIO
    import csv as _csv
    con = sqlite3.connect(DB)
    rows = con.execute(
        "SELECT unidad, numero, ip FROM unidades ORDER BY unidad"
    ).fetchall()
    con.close()
    buf = StringIO()
    w = _csv.writer(buf)
    w.writerow(["unidad","numero","ip"])
    for r in rows:
        w.writerow([r[0] or "", r[1] or "", r[2] or ""])
    return buf.getvalue()