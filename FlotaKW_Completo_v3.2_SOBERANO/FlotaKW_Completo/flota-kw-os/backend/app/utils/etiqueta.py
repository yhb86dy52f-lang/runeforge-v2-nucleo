import qrcode
import base64
from io import BytesIO
from datetime import datetime

def generate_qr_base64(data: str) -> str:
    qr = qrcode.QRCode(version=1, error_correction=qrcode.constants.ERROR_CORRECT_M, box_size=6, border=2)
    qr.add_data(data)
    qr.make(fit=True)
    img = qr.make_image(fill_color="black", back_color="white")
    buf = BytesIO()
    img.save(buf, format="PNG")
    b64 = base64.b64encode(buf.getvalue()).decode()
    return f"data:image/png;base64,{b64}"

def generar_etiqueta_html(unidad_codigo: str, mac: str, gps_marca_modelo: str, tipo: str, tecnico: str, fecha: datetime) -> str:
    qr_data = f"{unidad_codigo}|{mac}|{gps_marca_modelo}|{tecnico}"
    qr_b64 = generate_qr_base64(qr_data)
    fecha_str = fecha.strftime("%d/%m/%Y %H:%M") if isinstance(fecha, datetime) else str(fecha)
    html = f"""<!DOCTYPE html>
<html lang="es"><head><meta charset="UTF-8"><title>Etiqueta {unidad_codigo}</title>
<style>
@media print {{ @page {{ margin: 0; }} body {{ margin: 0; }} }}
body {{ font-family: 'Courier New', monospace; background: white; display: flex; justify-content: center; align-items: center; min-height: 100vh; margin: 0; }}
.etiqueta {{ width: 380px; border: 6px solid black; background: white; padding: 14px; color: black; }}
.header {{ text-align: center; border-bottom: 3px solid black; padding-bottom: 8px; margin-bottom: 10px; }}
.header h1 {{ margin: 0; font-size: 20px; letter-spacing: 2px; }}
.header small {{ font-size: 11px; }}
.row {{ display: flex; justify-content: space-between; margin: 6px 0; font-size: 13px; }}
.row .val {{ font-weight: bold; font-size: 14px; }}
.qr-box {{ text-align: center; margin: 12px 0 6px 0; border: 2px dashed black; padding: 8px; }}
.qr-box img {{ width: 140px; height: 140px; }}
.footer {{ text-align: center; font-size: 10px; margin-top: 10px; border-top: 2px solid black; padding-top: 6px; }}
.tipo-badge {{ display: inline-block; border: 2px solid black; padding: 2px 6px; font-weight: bold; font-size: 11px; }}
</style></head><body>
<div class="etiqueta">
<div class="header"><h1>FlotaKW_CT</h1><small>SISTEMA OPERATIVO DE LOGISTICA PESADA</small></div>
<div class="row"><b>CODIGO:</b> <span class="val">{unidad_codigo}</span></div>
<div class="row"><b>BEACON MAC:</b> <span class="val">{mac}</span></div>
<div class="row"><b>GPS:</b> <span class="val">{gps_marca_modelo}</span> <span class="tipo-badge">{tipo}</span></div>
<div class="row"><b>TECNICO:</b> <span class="val">{tecnico}</span></div>
<div class="row"><b>FECHA:</b> <span class="val">{fecha_str}</span></div>
<div class="qr-box"><img src="{qr_b64}" alt="QR"/><div style="font-size:10px; margin-top:4px;">{qr_data}</div></div>
<div class="footer">ONTOLOGIA OPERATIVA v3.0 | TRAZABILIDAD INMUTABLE | {fecha_str}</div>
</div><script>window.onload=()=>setTimeout(()=>window.print(),300)</script></body></html>"""
    return html
