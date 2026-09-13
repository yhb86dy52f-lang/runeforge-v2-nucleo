-- Vista ontologica: UnidadCompleta - proyeccion unica de verdad
IF OBJECT_ID('flota.vw_UnidadCompleta', 'V') IS NOT NULL
    DROP VIEW flota.vw_UnidadCompleta;
GO

CREATE VIEW flota.vw_UnidadCompleta AS
SELECT 
    u.id AS unidad_id,
    u.codigo,
    u.estado,
    u.created_at AS unidad_created,
    b.id AS beacon_id,
    b.mac,
    b.gps_marca_modelo,
    b.tipo,
    i.id AS instalacion_id,
    i.tecnico,
    i.fecha_instalacion,
    a.timestamp AS auditoria_timestamp
FROM flota.Unidades u
LEFT JOIN flota.Beacons b ON b.unidad_id = u.id
LEFT JOIN flota.Instalaciones i ON i.beacon_id = b.id
LEFT JOIN flota.Auditoria a ON a.registro_id = CAST(u.id AS NVARCHAR) AND a.tabla_afectada='Unidades';
GO

-- Ejemplo uso:
-- SELECT * FROM flota.vw_UnidadCompleta WHERE codigo='KW-1234';
