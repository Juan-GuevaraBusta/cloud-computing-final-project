"""
Router de catálogo: registro y listado de sensores (MongoDB).
"""

from fastapi import APIRouter, Depends, HTTPException
from pymongo.errors import DuplicateKeyError

from app.dependencies import get_mongodb_service
from app.schemas import MessageResponse, SensorCreate, SensorResponse
from app.services.mongodb import MongoDBService

router = APIRouter(prefix="/sensors", tags=["Catálogo de sensores"])


@router.get(
    "",
    response_model=list[SensorResponse],
    summary="Listar sensores registrados",
    description="Consulta la colección MongoDB `sensors` (metadatos de negocio, no telemetría MQTT).",
)
def list_sensors(
    mongo: MongoDBService = Depends(get_mongodb_service),
) -> list[SensorResponse]:
    """GET /sensors — todos los sensores del catálogo."""
    return mongo.list_sensors()


@router.post(
    "",
    response_model=SensorResponse,
    status_code=201,
    summary="Registrar un sensor",
    description=(
        "Alta lógica del dispositivo. El flujo MQTT no crea este registro automáticamente. "
        "El `device_id` debe coincidir con el del simulador Docker."
    ),
    responses={
        409: {"description": "device_id ya registrado"},
        503: {"description": "MongoDB no disponible"},
    },
)
def create_sensor(
    payload: SensorCreate,
    mongo: MongoDBService = Depends(get_mongodb_service),
) -> SensorResponse:
    """POST /sensors — validación Pydantic (extra=forbid) y unicidad de device_id."""
    if mongo.sensor_exists(payload.device_id):
        raise HTTPException(
            status_code=409,
            detail=f"El sensor '{payload.device_id}' ya está registrado",
        )
    try:
        return mongo.create_sensor(payload)
    except DuplicateKeyError as exc:
        raise HTTPException(status_code=409, detail="device_id duplicado") from exc
