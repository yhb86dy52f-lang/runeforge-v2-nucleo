# FlotaKW OS - Ontologia Operativa v3.0
### Esto no es una app, es el sistema nervioso de tu flota.

> Manifiesto Palantir: No vendes software, vendes ontologia operativa. Cada linea de codigo es una decision estrategica.

## Arquitectura Soberana (3 capas)

### Capa 1: Ontologia (SQL Server - FlotaKW_CT)
- Esquema `flota`
- Tablas: `Unidades`, `Beacons`, `Instalaciones`, `Tecnicos`, `Auditoria`
- Indices sobre `codigo` y `mac` para decision en el borde (query < 50ms)
- Vista `vw_UnidadCompleta`: proyeccion unica de verdad que une Unidad+Beacon+Instalacion
- Auditoria inmutable con `trace_id`

### Capa 2: Cerebro (FastAPI - Python)
**Regla de Oro implementada en `alta_service.py`:**
```python
if codigo.endswith("_R"):
    # VARIABLE - requiere gps_marca_modelo obligatorio
    gps, tipo = input.upper(), "VARIABLE"
else:
    # CALAMP - forzado, ignora input frontend
    gps, tipo = "CALAMP", "CALAMP"
```

Endpoints:
- `POST /api/v1/alta` -> Alta atomica transaccional
- `GET /api/v1/unidades` -> Listado paginado + filtros (search, tecnico, tipo)
- `GET /api/v1/unidades/{codigo}` -> Detalle completo
- `GET /api/v1/etiqueta/{codigo}` -> HTML etiqueta blanco/marco negro lista para imprimir
- `GET /api/v1/tecnicos`, `/stats`, `/auditoria`

Reglas inviolables:
- Validacion en backend, nunca en frontend
- Transaccion atomica: si falla un INSERT, todo rollback
- Logging estructurado con trace_id (structlog + contextvars)
- Tipado fuerte con Pydantic v2

### Capa 3: Interfaz Universal (Flutter)
- `mobile_scanner` para QR -> extrae MAC automatico
- Formulario alta: detecta _R y exige campo GPS
- Dashboard: stats hoy, por tecnico, buscador
- Vista etiqueta: renderiza HTML backend + QR + boton imprimir
- Panel admin: gestion tecnicos y auditoria

## Instalacion

### Requisitos
- Docker + Docker Compose
- Flutter 3.0+ (para compilar movil/web)

### Levantar en desarrollo
```bash
cp backend/.env.example backend/.env
docker-compose up --build
```
- API: http://localhost:8000/docs (Swagger automatico)
- SQL Server: localhost:1433 / SA / FlotaKW2024!
- Flutter Web: http://localhost:8080

### Migraciones SQL
Ejecuta en orden:
1. `sql/migrations/001_migration_indices_auditoria.sql` - Crea esquema, indices, auditoria
2. `sql/migrations/002_vista_unidad_completa.sql` - Crea vista ontologica
3. `sql/seeds/003_seed_data.sql` - Datos ejemplo

```bash
# Con sqlcmd
sqlcmd -S localhost -U sa -P FlotaKW2024! -d FlotaKW_CT -i sql/migrations/001_migration_indices_auditoria.sql
sqlcmd -S localhost -U sa -P FlotaKW2024! -d FlotaKW_CT -i sql/migrations/002_vista_unidad_completa.sql
```

### Backend local sin Docker (SQLite para tests rapidos)
```bash
cd backend
python -m venv venv && source venv/bin/activate
pip install -r requirements.txt
DATABASE_URL=sqlite:///./flotakw.db uvicorn app.main:app --reload
```

### Flutter local
```bash
cd mobile-app
flutter pub get
flutter run -d chrome  # web
flutter run -d android # movil
```

## Diagrama de flujo Alta

```
[TECNICO] -- escanea QR --> [APP] extrae MAC
[APP] --> Form: codigo, mac (auto), tecnico, gps? (si _R)
[APP] --> POST /api/v1/alta {codigo, mac, tecnico, gps_marca_modelo?}
[BACKEND] -> TracingMiddleware genera trace_id
[BACKEND] -> aplicar_regla_de_oro():
           - _R? exige gps_marca_modelo -> VARIABLE
           - sin _R -> fuerza CALAMP
[BACKEND] -> BEGIN TRANSACTION
           -> Check Unidad.codigo unico
           -> Check Beacon.mac unico
           -> Check Tecnico activo
           -> INSERT Unidad
           -> INSERT Beacon (FK unidad)
           -> INSERT Instalacion (FK unidad, beacon)
           -> INSERT 3x Auditoria (INSERT Unidades, Beacons, Instalaciones)
[BACKEND] -> COMMIT o ROLLBACK
[BACKEND] -> generar_etiqueta_html() con QR base64 + marco negro
[BACKEND] -> Response {unidad, beacon, instalacion, etiqueta_html, trace_id}
[APP] -> Muestra etiqueta + boton imprimir
[BD] -> flota.Auditoria registra todo con trace_id para trazabilidad
```

## Tests
```bash
cd backend
pytest tests/test_regla_oro.py -v
```
Cubre regla de oro, normalizacion MAC, validacion codigo.

## Ventaja Competitiva
- Tu BD es tu unica fuente de verdad. No dependes de nadie.
- Cada instalacion es atómica e inmutable.
- La etiqueta fisica es la proyeccion del dato digital.
- El tecnico en campo no decide que GPS es, lo decide la ontologia.

---
Fundador: Esto es codigo soberano. No se subcontrata. Cada linea protege tu imperio logistico.
