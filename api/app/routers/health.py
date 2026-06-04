"""
Router de salud: comprobación de DynamoDB y MongoDB.
"""

from fastapi import APIRouter, Depends

from app.config import Settings
from pymongo import MongoClient
from pymongo.errors import PyMongoError

from app.dependencies import get_dynamodb_service, get_settings_dep
from app.schemas import HealthResponse
from app.services.dynamodb import DynamoDBService

router = APIRouter(tags=["Salud"])


def _ping_mongodb(settings: Settings) -> str:
    """Ping a MongoDB sin lanzar 503 (el health puede estar degradado)."""
    try:
        client = MongoClient(settings.mongodb_uri, serverSelectionTimeoutMS=2000)
        client.admin.command("ping")
        return "ok"
    except PyMongoError as exc:
        return f"unavailable: {exc}"


@router.get(
    "/health",
    response_model=HealthResponse,
    summary="Estado de la API y dependencias",
    description="Verifica conectividad con DynamoDB y MongoDB. Útil para ALB/ECS en fases posteriores.",
)
def health_check(
    settings: Settings = Depends(get_settings_dep),
    dynamodb: DynamoDBService = Depends(get_dynamodb_service),
) -> HealthResponse:
    """Ejecuta ping ligero a cada almacén."""
    ddb_ok = dynamodb.ping()
    mongo_status = _ping_mongodb(settings)

    overall = "ok" if ddb_ok and mongo_status == "ok" else "degraded"
    return HealthResponse(
        status=overall,
        dynamodb_table=settings.dynamodb_table_name,
        mongodb_database=settings.mongodb_database,
        checks={
            "dynamodb": "ok" if ddb_ok else "error",
            "mongodb": mongo_status,
        },
    )
