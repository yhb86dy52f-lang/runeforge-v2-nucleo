from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import HTMLResponse
from sqlalchemy.orm import Session
from ..database import get_db
from ..models import Unidad, Beacon, Instalacion
from ..utils.etiqueta import generar_etiqueta_html
router = APIRouter()

@router.get("/etiqueta/{codigo}", response_class=HTMLResponse)
def get_etiqueta(codigo: str, db: Session = Depends(get_db)):
    codigo = codigo.upper()
    res = db.query(Unidad, Beacon, Instalacion).join(Beacon, Beacon.unidad_id == Unidad.id).join(Instalacion, Instalacion.beacon_id == Beacon.id).filter(Unidad.codigo == codigo).first()
    if not res:
        raise HTTPException(status_code=404, detail=f"Unidad {codigo} no encontrada")
    unidad, beacon, instalacion = res
    html = generar_etiqueta_html(unidad_codigo=unidad.codigo, mac=beacon.mac, gps_marca_modelo=beacon.gps_marca_modelo, tipo=beacon.tipo, tecnico=instalacion.tecnico, fecha=instalacion.fecha_instalacion)
    return HTMLResponse(content=html, status_code=200)
