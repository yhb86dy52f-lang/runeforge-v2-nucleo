-- Datos de ejemplo para validar ontologia
INSERT INTO flota.Unidades (codigo, estado) VALUES ('KW-1001', 'ACTIVA'), ('KW-1002_R', 'ACTIVA');
DECLARE @u1 INT = (SELECT id FROM flota.Unidades WHERE codigo='KW-1001');
DECLARE @u2 INT = (SELECT id FROM flota.Unidades WHERE codigo='KW-1002_R');

INSERT INTO flota.Beacons (mac, unidad_id, gps_marca_modelo, tipo) VALUES ('AA:BB:CC:00:11:01', @u1, 'CALAMP', 'CALAMP'), ('AA:BB:CC:00:11:02', @u2, 'TELTONIKA FMB920', 'VARIABLE');

DECLARE @b1 INT = (SELECT id FROM flota.Beacons WHERE mac='AA:BB:CC:00:11:01');
DECLARE @b2 INT = (SELECT id FROM flota.Beacons WHERE mac='AA:BB:CC:00:11:02');

INSERT INTO flota.Instalaciones (unidad_id, beacon_id, tecnico) VALUES (@u1, @b1, 'JUAN PEREZ'), (@u2, @b2, 'MARIA LOPEZ');
