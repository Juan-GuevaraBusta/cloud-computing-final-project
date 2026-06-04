"""
Router de lecturas: DynamoDB (actual/recientes) y MongoDB (histórico).
"""

from fastapi import APIRouter, Depends, HTTPException, Path

from app.dependencies import get_dynamodb_service, get_mongodb_service
from app.schemas import HistoryResponse, ReadingResponse
from app.services.dynamodb import DynamoDBService
from app.services.mongodb import MongoDBService

router = APIRouter(prefix="/sensor", tags=["Lecturas de sensores"])

DEVICE_ID_PATH = Path(
    ...,
    min_length=3,
    max_length=64,
    pattern=r"^[a-zA-Z0-9\-_]+$",
    description="Identificador del sensor (ej. sensor-temp-01)",
    examples=["sensor-temp-01"],
)


@router.get(
    "/{device_id}/current",
    response_model=ReadingResponse,
    summary="Lectura actual (DynamoDB)",
    description="Último evento del sensor según sort key `timestamp` (hot data).",
    responses={404: {"description": "Sin lecturas para ese device_id"}},
)
def get_current_reading(
    device_id: str = DEVICE_ID_PATH,
    dynamodb: DynamoDBService = Depends(get_dynamodb_service),
) -> ReadingResponse:
    """GET /sensor/{id}/current — Query DynamoDB Limit=1 descendente."""
    reading = dynamodb.get_current(device_id)
    if reading is None:
        raise HTTPException(
            status_code=404,
            detail=f"No hay lecturas en DynamoDB para '{device_id}'",
        )
    return reading


@router.get(
    "/{device_id}/recent",
    response_model=list[ReadingResponse],
    summary="Últimos 10 eventos (DynamoDB)",
    description="Ventana reciente en hot storage; máximo 10 ítems por diseño del proyecto.",
)
def get_recent_readings(
    device_id: str = DEVICE_ID_PATH,
    dynamodb: DynamoDBService = Depends(get_dynamodb_service),
) -> list[ReadingResponse]:
    """GET /sensor/{id}/recent — Query con Limit=10."""
    return dynamodb.get_recent(device_id, limit=10)


@router.get(
    "/{device_id}/history",
    response_model=HistoryResponse,
    summary="Histórico completo (MongoDB)",
    description=(
        "Eventos replicados desde S3 por la Lambda `s3_to_mongo` (colección `sensor_events`). "
        "Requiere acceso de red a MongoDB en EC2."
    ),
    responses={503: {"description": "MongoDB no disponible"}},
)
def get_history(
    device_id: str = DEVICE_ID_PATH,
    mongo: MongoDBService = Depends(get_mongodb_service),
) -> HistoryResponse:
    """GET /sensor/{id}/history — find en MongoDB ordenado por timestamp."""
    items = mongo.get_history(device_id)
    return HistoryResponse(device_id=device_id, count=len(items), items=items)
