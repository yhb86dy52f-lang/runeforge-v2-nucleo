@echo off
setlocal
cd /d "%~dp0"
title FlotaKW SOBERANO - Backend

echo ============================================
echo  FlotaKW OS v3.2 SOBERANO - RUN AUTONOMO
echo  Carpeta: %CD%
echo ============================================

if not exist "app\main.py" (
    echo [ERROR] Este .bat debe estar DENTRO de backend\ donde esta app\main.py
    pause
    exit /b 1
)

echo [1/4] Limpiando DB...
del /f /q flotakw.db 2>nul
echo DATABASE_URL=sqlite:///./flotakw.db> .env

echo [2/4] Escribiendo app\config.py...
> app\config.py echo from pydantic_settings import BaseSettings, SettingsConfigDict
>> app\config.py echo class Settings(BaseSettings):
>> app\config.py echo     model_config = SettingsConfigDict(extra="allow", env_file=".env", env_file_encoding="utf-8")
>> app\config.py echo     DATABASE_URL: str = "sqlite:///./flotakw.db"
>> app\config.py echo     DB_ECHO: bool = False
>> app\config.py echo     SECRET_KEY: str = "flotakw2024"
>> app\config.py echo     ENV: str = "dev"
>> app\config.py echo     APP_NAME: str = "FlotaKW OS v3.2 SOBERANO"
>> app\config.py echo     PROJECT_NAME: str = "FlotaKW OS"
>> app\config.py echo     VERSION: str = "3.0.0"
>> app\config.py echo     def __getattr__(self, name):
>> app\config.py echo         if "NAME" in name.upper(): return "FlotaKW OS v3.2 SOBERANO"
>> app\config.py echo         if "VERSION" in name.upper(): return "3.0.0"
>> app\config.py echo         return ""
>> app\config.py echo def get_settings():
>> app\config.py echo     return Settings()

echo [3/4] Escribiendo app\models.py sin flota...
> app\models.py echo from sqlalchemy import Column, Integer, String, DateTime, Boolean
>> app\models.py echo from sqlalchemy.sql import func
>> app\models.py echo from .database import Base
>> app\models.py echo.
>> app\models.py echo class Tecnico(Base):
>> app\models.py echo     __tablename__ = "Tecnicos"
>> app\models.py echo     __table_args__ = {}
>> app\models.py echo     id = Column(Integer, primary_key=True, index=True)
>> app\models.py echo     nombre = Column(String(100))
>> app\models.py echo     activo = Column(Boolean, default=True)
>> app\models.py echo     created_at = Column(DateTime, server_default=func.now())
>> app\models.py echo.
>> app\models.py echo class Unidad(Base):
>> app\models.py echo     __tablename__ = "Unidades"
>> app\models.py echo     __table_args__ = {}
>> app\models.py echo     id = Column(Integer, primary_key=True, index=True)
>> app\models.py echo     codigo = Column(String(50), unique=True)
>> app\models.py echo     estado = Column(String(20), default="DISPONIBLE")
>> app\models.py echo     mac = Column(String(50), nullable=True)
>> app\models.py echo     tecnico = Column(String(100), nullable=True)
>> app\models.py echo     created_at = Column(DateTime, server_default=func.now())
>> app\models.py echo.
>> app\models.py echo class Beacon(Base):
>> app\models.py echo     __tablename__ = "Beacons"
>> app\models.py echo     __table_args__ = {}
>> app\models.py echo     id = Column(Integer, primary_key=True)
>> app\models.py echo     unidad_id = Column(Integer, nullable=True)
>> app\models.py echo     mac = Column(String(50))
>> app\models.py echo     created_at = Column(DateTime, server_default=func.now())
>> app\models.py echo.
>> app\models.py echo class Instalacion(Base):
>> app\models.py echo     __tablename__ = "Instalaciones"
>> app\models.py echo     __table_args__ = {}
>> app\models.py echo     id = Column(Integer, primary_key=True)
>> app\models.py echo     unidad_id = Column(Integer, nullable=True)
>> app\models.py echo     tecnico = Column(String(100))
>> app\models.py echo     created_at = Column(DateTime, server_default=func.now())
>> app\models.py echo.
>> app\models.py echo class Auditoria(Base):
>> app\models.py echo     __tablename__ = "Auditoria"
>> app\models.py echo     __table_args__ = {}
>> app\models.py echo     id = Column(Integer, primary_key=True)
>> app\models.py echo     accion = Column(String(100))
>> app\models.py echo     detalle = Column(String(500))
>> app\models.py echo     created_at = Column(DateTime, server_default=func.now())
>> app\models.py echo.
>> app\models.py echo Tecnicos = Tecnico
>> app\models.py echo Unidades = Unidad
>> app\models.py echo Beacons = Beacon
>> app\models.py echo Instalaciones = Instalacion

echo [4/4] Levantando en http://127.0.0.1:8000/docs
set DATABASE_URL=sqlite:///./flotakw.db
set PYTHONPATH=.
python -m uvicorn app.main:app --port 8000 --host 127.0.0.1
if errorlevel 1 py -m uvicorn app.main:app --port 8000 --host 127.0.0.1
pause