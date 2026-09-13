from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Boolean, Text, Index
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from .database import Base

class Tecnico(Base):
    __tablename__ = "Tecnicos"
    __table_args__ = {"schema": "flota"}
    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String(100), unique=True, nullable=False, index=True)
    activo = Column(Boolean, default=True)
    created_at = Column(DateTime, default=func.now())

class Unidad(Base):
    __tablename__ = "Unidades"
    __table_args__ = (Index("IX_Unidades_codigo", "codigo", unique=True), {"schema": "flota"})
    id = Column(Integer, primary_key=True, index=True)
    codigo = Column(String(50), unique=True, nullable=False)
    estado = Column(String(20), default="ACTIVA")
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())
    beacons = relationship("Beacon", back_populates="unidad")
    instalaciones = relationship("Instalacion", back_populates="unidad")

class Beacon(Base):
    __tablename__ = "Beacons"
    __table_args__ = (
        Index("IX_Beacons_mac", "mac", unique=True),
        Index("IX_Beacons_unidad_id", "unidad_id"),
        {"schema": "flota"}
    )
    id = Column(Integer, primary_key=True, index=True)
    mac = Column(String(17), unique=True, nullable=False)
    unidad_id = Column(Integer, ForeignKey("flota.Unidades.id"), nullable=False)
    gps_marca_modelo = Column(String(100), nullable=False)
    tipo = Column(String(20), nullable=False)
    created_at = Column(DateTime, default=func.now())
    unidad = relationship("Unidad", back_populates="beacons")

class Instalacion(Base):
    __tablename__ = "Instalaciones"
    __table_args__ = (
        Index("IX_Instalaciones_unidad_id", "unidad_id"),
        Index("IX_Instalaciones_beacon_id", "beacon_id"),
        {"schema": "flota"}
    )
    id = Column(Integer, primary_key=True, index=True)
    unidad_id = Column(Integer, ForeignKey("flota.Unidades.id"), nullable=False)
    beacon_id = Column(Integer, ForeignKey("flota.Beacons.id"), nullable=False)
    tecnico = Column(String(100), nullable=False)
    fecha_instalacion = Column(DateTime, default=func.now())
    notas = Column(Text, nullable=True)
    unidad = relationship("Unidad", back_populates="instalaciones")
    beacon = relationship("Beacon")

class Auditoria(Base):
    __tablename__ = "Auditoria"
    __table_args__ = (
        Index("IX_Auditoria_tabla", "tabla_afectada"),
        Index("IX_Auditoria_timestamp", "timestamp"),
        {"schema": "flota"}
    )
    id = Column(Integer, primary_key=True, index=True)
    tabla_afectada = Column(String(50), nullable=False)
    operacion = Column(String(20), nullable=False)
    registro_id = Column(String(100), nullable=False)
    datos_anterior = Column(Text, nullable=True)
    datos_nuevo = Column(Text, nullable=True)
    usuario = Column(String(100), nullable=False)
    timestamp = Column(DateTime, default=func.now())
    trace_id = Column(String(50), nullable=True)
