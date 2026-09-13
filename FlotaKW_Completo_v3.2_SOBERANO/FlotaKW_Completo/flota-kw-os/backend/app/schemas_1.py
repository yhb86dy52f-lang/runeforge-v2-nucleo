from pydantic import BaseModel, Field, field_validator
from typing import Optional, List
from datetime import datetime
import re

class AltaRequest(BaseModel):
    codigo: str = Field(..., min_length=3, max_length=50)
    mac: str = Field(...)
    tecnico: str = Field(..., min_length=2, max_length=100)
    gps_marca_modelo: Optional[str] = Field(None)

    @field_validator("codigo")
    @classmethod
    def codigo_upper(cls, v):
        v = v.strip().upper()
        if not re.match(r"^[A-Z0-9\-]+(_R)?$", v):
            raise ValueError("Codigo invalido. Formato: KW-XXXX o KW-XXXX_R")
        return v

    @field_validator("mac")
    @classmethod
    def mac_normalize(cls, v):
        v = v.strip().upper()
        clean = re.sub(r"[^0-9A-F]", "", v)
        if len(clean) != 12:
            raise ValueError("MAC invalida. Debe tener 12 hex")
        return ":".join(clean[i:i+2] for i in range(0, 12, 2))

class UnidadOut(BaseModel):
    id: int
    codigo: str
    estado: str
    created_at: datetime
    class Config:
        from_attributes = True

class BeaconOut(BaseModel):
    id: int
    mac: str
    unidad_id: int
    gps_marca_modelo: str
    tipo: str
    created_at: datetime
    class Config:
        from_attributes = True

class InstalacionOut(BaseModel):
    id: int
    unidad_id: int
    beacon_id: int
    tecnico: str
    fecha_instalacion: datetime
    class Config:
        from_attributes = True

class UnidadCompletaOut(BaseModel):
    codigo: str
    unidad_id: int
    estado: str
    mac: str
    gps_marca_modelo: str
    tipo: str
    tecnico: str
    fecha_instalacion: datetime
    beacon_id: int

class AltaResponse(BaseModel):
    status: str
    unidad: UnidadOut
    beacon: BeaconOut
    instalacion: InstalacionOut
    etiqueta_html: str
    trace_id: str

class PaginatedUnidades(BaseModel):
    total: int
    page: int
    limit: int
    items: List[UnidadCompletaOut]
