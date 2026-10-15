from pydantic_settings import BaseSettings
from functools import lru_cache

class Settings(BaseSettings):
    DATABASE_URL: str = "mssql+pyodbc://sa:FlotaKW2024!@localhost:1433/FlotaKW_CT?driver=ODBC+Driver+18+for+SQL+Server&TrustServerCertificate=yes"
    DB_ECHO: bool = False
    API_V1_PREFIX: str = "/api/v1"
    CORS_ORIGINS: str = "*"
    LOG_LEVEL: str = "INFO"
    APP_NAME: str = "FlotaKW OS - Ontologia Operativa"

    class Config:
        env_file = ".env"

@lru_cache
def get_settings():
    return Settings()
