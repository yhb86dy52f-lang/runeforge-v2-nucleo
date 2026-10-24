from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from fastapi import HTTPException
from datetime import datetime
import json
from ..models import Unidad, Beacon, Instalacion, Auditoria, Tecnico
from ..schemas import AltaRequest
from ..utils.etiqueta import generar_etiqueta_html
import structlog
logger = structlog.get_logger()

def aplicar_regla_de_oro(codigo: str, gps_input: str | None) -> tuple[str, str]:
    is_r = codigo.upper().endswith("_R")
    if is_r:
        if not gps_input or not gps_input.strip():
            raise HTTPException(status_code=400, detail="Codigo termina en _R: gps_marca_modelo es obligatorio")
        return gps_input.strip().upper(), "VARIABLE"
    else:
        return "CALAMP", "CALAMP"

def alta_atomica(db: Session, req: AltaRequest, trace_id: str):
    codigo = req.codigo.strip().upper()
    mac = req.mac.strip().upper()
    tecnico_nombre = req.tecnico.strip()
    gps_modelo, tipo = aplicar_regla_de_oro(codigo, req.gps_marca_modelo)

    tecnico_obj = db.query(Tecnico).filter(Tecnico.nombre == tecnico_nombre, Tecnico.activo == True).first()
    if not tecnico_obj:
        raise HTTPException(status_code=404, detail=f"Tecnico '{tecnico_nombre}' no existe o inactivo. Dar de alta en panel admin.")

    if db.query(Unidad).filter(Unidad.codigo == codigo).first():
        raise HTTPException(status_code=409, detail=f"Unidad con codigo {codigo} ya existe")
    if db.query(Beacon).filter(Beacon.mac == mac).first():
        raise HTTPException(status_code=409, detail=f"Beacon con MAC {mac} ya existe")

    try:
        unidad = Unidad(codigo=codigo, estado="ACTIVA")
        db.add(unidad)
        db.flush()

        beacon = Beacon(mac=mac, unidad_id=unidad.id, gps_marca_modelo=gps_modelo, tipo=tipo)
        db.add(beacon)
        db.flush()

        instalacion = Instalacion(unidad_id=unidad.id, beacon_id=beacon.id, tecnico=tecnico_nombre, fecha_instalacion=datetime.utcnow())
        db.add(instalacion)
        db.flush()

        for tabla, reg_id, nuevo in [
            ("Unidades", str(unidad.id), {"codigo": unidad.codigo, "estado": unidad.estado}),
            ("Beacons", str(beacon.id), {"mac": beacon.mac, "gps_marca_modelo": beacon.gps_marca_modelo, "tipo": beacon.tipo}),
            ("Instalaciones", str(instalacion.id), {"unidad_id": instalacion.unidad_id, "beacon_id": instalacion.beacon_id, "tecnico": tecnico_nombre})
        ]:
            audit = Auditoria(tabla_afectada=tabla, operacion="INSERT", registro_id=reg_id, datos_anterior=None, datos_nuevo=json.dumps(nuevo, ensure_ascii=False), usuario=tecnico_nombre, trace_id=trace_id)
            db.add(audit)

        db.commit()
        db.refresh(unidad)
        db.refresh(beacon)
        db.refresh(instalacion)

        etiqueta_html = generar_etiqueta_html(unidad_codigo=unidad.codigo, mac=beacon.mac, gps_marca_modelo=beacon.gps_marca_modelo, tipo=beacon.tipo, tecnico=tecnico_nombre, fecha=instalacion.fecha_instalacion)
        logger.info("alta_exitosa", trace_id=trace_id, codigo=codigo, mac=mac, tipo=tipo, tecnico=tecnico_nombre)
        return unidad, beacon, instalacion, etiqueta_html

    except HTTPException:
        db.rollback()
        raise
    except IntegrityError as e:
        db.rollback()
        logger.error("integrity_error", trace_id=trace_id, error=str(e))
        raise HTTPException(status_code=409, detail=f"Conflicto de integridad: {str(e.orig)}")
    except Exception as e:
        db.rollback()
        logger.error("alta_fallo", trace_id=trace_id, error=str(e))
        raise HTTPException(status_code=500, detail=f"Error en alta atomica: {str(e)}")
