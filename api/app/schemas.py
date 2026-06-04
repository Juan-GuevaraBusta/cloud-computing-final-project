"""
Esquemas Pydantic: validación, documentación Swagger y serialización de respuestas.
"""

from datetime import datetime, timezone
from typing import Any

from pydantic import BaseModel, ConfigDict, Field, field_validator


class SensorCreate(BaseModel):
    """Cuerpo de POST /sensors — catálogo lógico (no llega por MQTT)."""

    model_config = ConfigDict(extra="forbid")

    device_id: str = Field(
        ...,
        min_length=3,
        max_length=64,
        pattern=r"^[a-zA-Z0-9\-_]+$",
        description="Identificador único; debe coincidir con CLIENT_ID del simulador",
        examples=["sensor-temp-01"],
    )
    sensor_type: str = Field(
        ...,
        min_length=2,
        max_length=32,
        description="Tipo de magnitud: temperature, humidity, etc.",
        examples=["temperature"],
    )
    display_name: str = Field(..., min_length=1, max_length=128)
    location: str | None = Field(default=None, max_length=256)
    active: bool = True


class SensorResponse(BaseModel):
    """Sensor registrado en MongoDB."""

    model_config = ConfigDict(extra="ignore")

    device_id: str
    sensor_type: str
    display_name: str
    location: str | None = None
    active: bool = True
    registered_at: str


class ReadingResponse(BaseModel):
    """Lectura de telemetría (DynamoDB o MongoDB)."""

    model_config = ConfigDict(extra="ignore")

    device_id: str
    sensor_type: str | None = None
    value: float
    timestamp: str
    source: str | None = Field(
        default=None,
        description="Origen del dato: dynamodb | mongodb_history",
    )


class HistoryResponse(BaseModel):
    """Lista de lecturas históricas desde MongoDB."""

    device_id: str
    count: int
    items: list[ReadingResponse]


class HealthResponse(BaseModel):
    """Estado de dependencias para monitoreo."""

    status: str
    dynamodb_table: str
    mongodb_database: str
    checks: dict[str, str]


class MessageResponse(BaseModel):
    """Mensaje genérico de éxito."""

    message: str


def utc_now_iso() -> str:
    """Marca de tiempo ISO 8601 en UTC para registered_at."""
    return datetime.now(timezone.utc).isoformat()


def decimal_to_float(value: Any) -> float:
    """Convierte Decimal de boto3 a float para JSON/Swagger."""
    return float(value)
