from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from datetime import datetime
import uvicorn
import os

from sms_adapter import send_sms, read_inbox
from fleet import (
    list_units, init_db, get_unit,
    diagnose_all, activate_paro, deactivate_paro,
    activate_paro_especial, deactivate_paro_especial,
    import_csv_text, export_csv_text,
)

app = FastAPI(title="FORGE SMS-HUB API", version="1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

init_db()


@app.get("/api/health")
def health():
    return {
        "ok": True,
        "ts": datetime.now().isoformat(),
        "adapter": os.environ.get("SMS_ADAPTER", "auto"),
    }


@app.get("/api/fleet/list")
def api_list():
    return {"units": list_units()}


class DiagRequest(BaseModel):
    target: str | None = None


@app.post("/api/fleet/diag")
def api_diag(req: DiagRequest):
    return diagnose_all(target=req.target)


class ParoRequest(BaseModel):
    action: str
    slot: int
    masivo: bool = True
    target: str | None = None


@app.post("/api/fleet/paro")
def api_paro(req: ParoRequest):
    if req.action == "on":
        return activate_paro(slot=req.slot, masivo=req.masivo, target=req.target)
    if req.action == "off":
        return deactivate_paro(slot=req.slot, masivo=req.masivo, target=req.target)
    raise HTTPException(400, "action must be on|off")


class ParoEspecialRequest(BaseModel):
    action: str
    masivo: bool = True
    target: str | None = None


@app.post("/api/fleet/paro-especial")
def api_paro_especial(req: ParoEspecialRequest):
    if req.action == "on":
        return activate_paro_especial(masivo=req.masivo, target=req.target)
    if req.action == "off":
        return deactivate_paro_especial(masivo=req.masivo, target=req.target)
    raise HTTPException(400, "action must be on|off")


class SmsRequest(BaseModel):
    to: str
    cmd: str


@app.post("/api/sms/send")
def api_send(req: SmsRequest):
    ok = send_sms(req.to, req.cmd)
    if not ok:
        raise HTTPException(500, "SMS send failed")
    return {"ok": True}


@app.get("/api/sms/inbox")
def api_inbox():
    return {"messages": read_inbox()}




from fastapi.responses import PlainTextResponse


class ImportCsvRequest(BaseModel):
    csv: str
    default_ip: str | None = None


@app.post("/api/fleet/import-csv")
def api_import_csv(req: ImportCsvRequest):
    return import_csv_text(req.csv, default_ip=req.default_ip)


@app.get("/api/fleet/export-csv")
def api_export_csv():
    return PlainTextResponse(export_csv_text(), media_type="text/csv")

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8080, log_level="info")
