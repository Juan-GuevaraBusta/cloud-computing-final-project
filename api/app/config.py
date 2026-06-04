"""
Configuración de la API desde variables de entorno (.env en la raíz del repo).
"""

from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

# Raíz del proyecto: api/app/config.py → ../../.env
_REPO_ROOT = Path(__file__).resolve().parents[2]
_ENV_FILE = _REPO_ROOT / ".env"


class Settings(BaseSettings):
    """Variables requeridas para DynamoDB y MongoDB."""

    model_config = SettingsConfigDict(
        env_file=str(_ENV_FILE),
        env_file_encoding="utf-8",
        extra="ignore",
    )

    aws_region: str = "us-east-1"
    dynamodb_table_name: str = "SensorData-lab"
    mongodb_uri: str
    mongodb_database: str = "iot"
    mongodb_sensors_collection: str = "sensors"
    mongodb_events_collection: str = "sensor_events"
    api_title: str = "IoT Edge Platform API"
    api_version: str = "1.0.0"


@lru_cache
def get_settings() -> Settings:
    """Instancia única de configuración (cacheada)."""
    return Settings()
