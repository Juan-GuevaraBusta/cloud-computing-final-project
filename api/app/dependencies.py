"""
Dependencias inyectadas en FastAPI (servicios singleton por proceso).
"""

from functools import lru_cache

from fastapi import HTTPException

from app.config import Settings, get_settings
from app.services.dynamodb import DynamoDBService
from app.services.mongodb import MongoDBService


@lru_cache
def get_dynamodb_service() -> DynamoDBService:
    """Cliente DynamoDB cacheado."""
    return DynamoDBService(get_settings())


def get_mongodb_service() -> MongoDBService:
    """
    Cliente MongoDB por request cacheado a nivel proceso.
    Falla con 503 si no hay conexión (IP privada sin túnel).
    """
    settings = get_settings()
    try:
        service = MongoDBService(settings)
        if not service.ping():
            raise HTTPException(
                status_code=503,
                detail="MongoDB no responde. ¿Túnel/VPN hacia la VPC o stack aws-up activo?",
            )
        return service
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(
            status_code=503,
            detail=f"No se pudo conectar a MongoDB: {exc}",
        ) from exc


def get_settings_dep() -> Settings:
    """Expone Settings a los routers para metadatos Swagger."""
    return get_settings()
