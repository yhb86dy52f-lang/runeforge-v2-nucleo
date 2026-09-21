from sqlalchemy import Column, Integer, String, DateTime, Boolean, Float
from sqlalchemy.sql import func
from.database import Base

class Instalacion(Base):
    __tablename__ = "instalaciones"
    id = Column(Integer, primary_key=True, index=True)
    beacon_id = Column(String(100), unique=True, index=True, nullable=False)
    gps_marca_modelo = Column(String(100), nullable=False, default="Queclink GV300")
    tipo = Column(String(50), nullable=False, default="GPS")
    fecha_instalacion = Column(DateTime(timezone=True), server_default=func.now())
    unidad_id = Column(String(50), index=True)
    cliente = Column(String(100))
    estado = Column(String(20), default="ACTIVA")
    lat = Column(Float, nullable=True)
    lng = Column(Float, nullable=True)
    notas = Column(String(500), nullable=True)
    activo = Column(Boolean, default=True)

class Unidad(Base):
    __tablename__ = "unidades"
    id = Column(Integer, primary_key=True, index=True)
    beacon_id = Column(String(100), index=True)
    placa = Column(String(20), unique=True)
    estado = Column(String(20), default="ONLINE")

class Beacon(Base):
    __tablename__ = "beacons"
    id = Column(Integer, primary_key=True, index=True)
    unidad_id = Column(String(50), index=True)
    mac = Column(String(50), unique=True)
    tipo = Column(String(50), default="BLE")

class Tecnico(Base):
    __tablename__ = "tecnicos"
    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String(100), unique=True)
    activo = Column(Boolean, default=True)

class Auditoria(Base):
    __tablename__ = "auditoria"
    id = Column(Integer, primary_key=True, index=True)
    accion = Column(String(100))
    detalle = Column(String(500))
    created_at = Column(DateTime(timezone=True), server_default=func.now())
