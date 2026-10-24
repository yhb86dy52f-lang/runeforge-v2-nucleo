from pydantic_settings import BaseSettings, SettingsConfigDict
class Settings(BaseSettings):
    model_config = SettingsConfigDict(extra="allow", env_file=".env", env_file_encoding="utf-8")
    DATABASE_URL: str = "sqlite:///./flotakw.db"
    DB_ECHO: bool = False
    SECRET_KEY: str = "flotakw2024"
    ENV: str = "dev"
    APP_NAME: str = "FlotaKW OS v3.2 SOBERANO"
    PROJECT_NAME: str = "FlotaKW OS"
    VERSION: str = "3.0.0"
    def __getattr__(self, name):
        if "NAME" in name.upper(): return "FlotaKW OS v3.2 SOBERANO"
        if "VERSION" in name.upper(): return "3.0.0"
        return ""
def get_settings():
    return Settings()
