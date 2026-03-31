from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    APP_NAME: str = "SmartPS"
    DEBUG: bool = True

    DATABASE_URL: str = "sqlite:///./smartps.db"
    REDIS_URL: str = "redis://localhost:6379/0"
    USE_REDIS: bool = False

    SECRET_KEY: str = "your-super-secret-key-change-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440

    ALLOWED_ORIGINS: str = "http://localhost:3000,http://localhost:8080,*"
    OCR_CONFIDENCE_THRESHOLD: float = 0.85

    class Config:
        env_file = ".env"
        case_sensitive = True

    @property
    def allowed_origins_list(self) -> list[str]:
        return [origin.strip() for origin in self.ALLOWED_ORIGINS.split(",")]


@lru_cache()
def get_settings() -> Settings:
    return Settings()
