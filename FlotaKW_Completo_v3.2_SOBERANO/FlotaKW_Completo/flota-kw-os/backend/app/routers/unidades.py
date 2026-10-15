from fastapi import APIRouter, Depends, Query, HTTPException, Request
from sqlalchemy.orm import Session
from sqlalchemy import or_
from typing import Optional
from ..database import get_db
from ..schemas import AltaRequest, AltaResponse, PaginatedUnidades, UnidadCompletaOut
from ..services.alta_service import alta_atomica
from ..models import Unidad, Beacon, Instalacion, Tecnico, Auditoria

router = APIRouter()

@router.post("/alta", response_model=AltaResponse)
def alta_unidad(req: AltaRequest, request: Request, db: Session = Depends(get_db)):
    trace_id = getattr(request.state, "trace_id", "NO-TRACE")
    unidad, beacon, instalacion, etiqueta_html = alta_atomica(db, req, trace_id)
    return {"status": "ok", "unidad": unidad, "beacon": beacon, "instalacion": instalacion, "etiqueta_html": etiqueta_html, "trace_id": trace_id}

@router.get("/unidades", response_model=PaginatedUnidades)
def listar_unidades(search: Optional[str] = Query(None), tecnico: Optional[str] = Query(None), tipo: Optional[str] = Query(None), page: int = Query(1, ge=1), limit: int = Query(20, ge=1, le=100), db: Session = Depends(get_db)):
    query = db.query(Unidad, Beacon, Instalacion).join(Beacon, Beacon.unidad_id == Unidad.id).join(Instalacion, Instalacion.beacon_id == Beacon.id)
    if search:
        s = f"%{search.upper()}%"
        query = query.filter(or_(Unidad.codigo.like(s), Beacon.mac.like(s), Beacon.gps_marca_modelo.like(s)))
    if tecnico:
        query = query.filter(Instalacion.tecnico == tecnico)
    if tipo:
        query = query.filter(Beacon.tipo == tipo.upper())
    total = query.count()
    items_q = query.order_by(Instalacion.fecha_instalacion.desc()).offset((page-1)*limit).limit(limit).all()
    items = []
    for unidad, beacon, instalacion in items_q:
        items.append(UnidadCompletaOut(codigo=unidad.codigo, unidad_id=unidad.id, estado=unidad.estado, mac=beacon.mac, gps_marca_modelo=beacon.gps_marca_modelo, tipo=beacon.tipo, tecnico=instalacion.tecnico, fecha_instalacion=instalacion.fecha_instalacion, beacon_id=beacon.id))
    return {"total": total, "page": page, "limit": limit, "items": items}

@router.get("/unidades/{codigo}", response_model=UnidadCompletaOut)
def detalle_unidad(codigo: str, db: Session = Depends(get_db)):
    codigo = codigo.upper()
    res = db.query(Unidad, Beacon, Instalacion).join(Beacon, Beacon.unidad_id == Unidad.id).join(Instalacion, Instalacion.beacon_id == Beacon.id).filter(Unidad.codigo == codigo).first()
    if not res:
        raise HTTPException(status_code=404, detail=f"Unidad {codigo} no encontrada")
    unidad, beacon, instalacion = res
    return UnidadCompletaOut(codigo=unidad.codigo, unidad_id=unidad.id, estado=unidad.estado, mac=beacon.mac, gps_marca_modelo=beacon.gps_marca_modelo, tipo=beacon.tipo, tecnico=instalacion.tecnico, fecha_instalacion=instalacion.fecha_instalacion, beacon_id=beacon.id)

@router.get("/tecnicos")
def listar_tecnicos(db: Session = Depends(get_db)):
    return db.query(Tecnico).filter(Tecnico.activo == True).all()

@router.get("/auditoria")
def listar_auditoria(limit: int = 50, db: Session = Depends(get_db)):
    return db.query(Auditoria).order_by(Auditoria.created_at.desc()).limit(limit).all()

@router.get("/stats")
def stats(db: Session = Depends(get_db)):
    from sqlalchemy import func
    from datetime import date
    total_unidades = db.query(func.count(Unidad.id)).scalar()
    total_beacons = db.query(func.count(Beacon.id)).scalar()
    total_hoy = db.query(func.count(Instalacion.id)).scalar()
    por_tecnico = db.query(Instalacion.tecnico, func.count(Instalacion.id)).group_by(Instalacion.tecnico).all()
    return {"total_unidades": total_unidades, "total_beacons": total_beacons, "instalaciones_hoy": total_hoy or 0, "por_tecnico": [{"tecnico": t, "count": c} for t,c in por_tecnico]}
