CREATE VIEW flota.vw_UnidadCompleta AS
SELECT 
    u.Codigo, u.ModeloVehiculo, u.NumeroEconomico,
    b.MAC, b.SerialNumber AS BeaconSerial, cg.Marca, cg.Modelo AS GPSModelo,
    t.NombreCompleto AS Tecnico, i.FechaInstalacion, i.CoordenadasLat, i.CoordenadasLng
FROM flota.Instalaciones i
JOIN flota.Unidades u ON i.IdUnidad = u.Id
JOIN flota.Beacons b ON i.IdBeacon = b.Id
JOIN flota.CatalogoGPS cg ON b.IdCatalogoGPS = cg.Id
JOIN flota.Tecnicos t ON i.IdTecnico = t.Id
WHERE i.Estado = 'EXITOSA';