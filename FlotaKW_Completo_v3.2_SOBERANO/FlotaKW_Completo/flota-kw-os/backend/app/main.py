from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .config import get_settings
from .database import Base, engine
import app.models
from app.models import *
from .routers import unidades, etiquetas
from .middleware.tracing import TracingMiddleware
import structlog, logging

structlog.configure(processors=[structlog.contextvars.merge_contextvars, structlog.processors.add_log_level, structlog.processors.TimeStamper(fmt="iso"), structlog.processors.JSONRenderer()], wrapper_class=structlog.make_filtering_bound_logger(logging.NOTSET), context_class=dict, logger_factory=structlog.PrintLoggerFactory())

settings = get_settings()
app = FastAPI(title=settings.APP_NAME, description="Ecosistema soberano FlotaKW_CT v3.0 - Ontologia Operativa. Sin _R=CALAMP, Con _R=VARIABLE, Instalacion atomica, Auditoria inmutable", version="3.0.0")
app.add_middleware(TracingMiddleware)
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_credentials=True, allow_methods=["*"], allow_headers=["*"])
Base.metadata.create_all(bind=engine)
app.include_router(unidades.router, prefix=settings.API_V1_PREFIX, tags=["Unidades"])
app.include_router(etiquetas.router, prefix=settings.API_V1_PREFIX, tags=["Etiquetas"])

@app.get("/")
def root():
    return {"status": "operativo", "ontologia": "FlotaKW_CT v3.0", "mensaje": "Tu base de datos es tu unica fuente de verdad."}

@app.get("/health")
def health():
    return {"status": "ok"}
