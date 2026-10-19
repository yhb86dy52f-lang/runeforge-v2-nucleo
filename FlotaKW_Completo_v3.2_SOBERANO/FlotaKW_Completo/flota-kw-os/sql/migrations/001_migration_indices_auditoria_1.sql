-- ONTOLOGIA OPERATIVA FlotaKW_CT v3.0 - Migracion 001
-- Capa 1: Indices + Auditoria + Tecnicos

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'flota')
    EXEC('CREATE SCHEMA flota');

-- Tabla Tecnicos (si no existe)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name='Tecnicos' AND schema_id=SCHEMA_ID('flota'))
CREATE TABLE flota.Tecnicos (
    id INT IDENTITY(1,1) PRIMARY KEY,
    nombre NVARCHAR(100) UNIQUE NOT NULL,
    activo BIT DEFAULT 1,
    created_at DATETIME DEFAULT GETDATE()
);

-- Unidades: asegurar indice sobre codigo
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name='Unidades' AND schema_id=SCHEMA_ID('flota'))
CREATE TABLE flota.Unidades (
    id INT IDENTITY(1,1) PRIMARY KEY,
    codigo NVARCHAR(50) UNIQUE NOT NULL,
    estado NVARCHAR(20) DEFAULT 'ACTIVA',
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME DEFAULT GETDATE()
);
ELSE
BEGIN
    IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name='IX_Unidades_codigo')
        CREATE UNIQUE INDEX IX_Unidades_codigo ON flota.Unidades(codigo);
END

-- Beacons: indice mac
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name='Beacons' AND schema_id=SCHEMA_ID('flota'))
CREATE TABLE flota.Beacons (
    id INT IDENTITY(1,1) PRIMARY KEY,
    mac NVARCHAR(17) UNIQUE NOT NULL,
    unidad_id INT NOT NULL FOREIGN KEY REFERENCES flota.Unidades(id),
    gps_marca_modelo NVARCHAR(100) NOT NULL,
    tipo NVARCHAR(20) NOT NULL,
    created_at DATETIME DEFAULT GETDATE()
);
ELSE
BEGIN
    IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name='IX_Beacons_mac')
        CREATE UNIQUE INDEX IX_Beacons_mac ON flota.Beacons(mac);
    IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name='IX_Beacons_unidad_id')
        CREATE INDEX IX_Beacons_unidad_id ON flota.Beacons(unidad_id);
END

-- Instalaciones
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name='Instalaciones' AND schema_id=SCHEMA_ID('flota'))
CREATE TABLE flota.Instalaciones (
    id INT IDENTITY(1,1) PRIMARY KEY,
    unidad_id INT NOT NULL FOREIGN KEY REFERENCES flota.Unidades(id),
    beacon_id INT NOT NULL FOREIGN KEY REFERENCES flota.Beacons(id),
    tecnico NVARCHAR(100) NOT NULL,
    fecha_instalacion DATETIME DEFAULT GETDATE(),
    notas NVARCHAR(MAX) NULL
);

-- Auditoria inmutable
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name='Auditoria' AND schema_id=SCHEMA_ID('flota'))
CREATE TABLE flota.Auditoria (
    id INT IDENTITY(1,1) PRIMARY KEY,
    tabla_afectada NVARCHAR(50) NOT NULL,
    operacion NVARCHAR(20) NOT NULL,
    registro_id NVARCHAR(100) NOT NULL,
    datos_anterior NVARCHAR(MAX) NULL,
    datos_nuevo NVARCHAR(MAX) NULL,
    usuario NVARCHAR(100) NOT NULL,
    timestamp DATETIME DEFAULT GETDATE(),
    trace_id NVARCHAR(50) NULL
);

CREATE INDEX IX_Auditoria_tabla ON flota.Auditoria(tabla_afectada);
CREATE INDEX IX_Auditoria_timestamp ON flota.Auditoria(timestamp);

-- Seed tecnicos
MERGE flota.Tecnicos AS target
USING (VALUES ('JUAN PEREZ'), ('MARIA LOPEZ'), ('CARLOS RUIZ'), ('SISTEMA')) AS source(nombre)
ON target.nombre = source.nombre
WHEN NOT MATCHED THEN INSERT (nombre, activo) VALUES (source.nombre, 1);
