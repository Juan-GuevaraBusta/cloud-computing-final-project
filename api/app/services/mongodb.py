"""
Acceso a MongoDB: catálogo de sensores e histórico (sensor_events).
"""

from pymongo import MongoClient
from pymongo.errors import DuplicateKeyError, PyMongoError

from app.config import Settings
from app.schemas import ReadingResponse, SensorCreate, SensorResponse, utc_now_iso


class MongoDBService:
    """Colecciones sensors (catálogo) y sensor_events (histórico vía Lambda)."""

    def __init__(self, settings: Settings):
        self._db_name = settings.mongodb_database
        self._client = MongoClient(settings.mongodb_uri, serverSelectionTimeoutMS=3000)
        self._db = self._client[self._db_name]
        self._sensors = self._db[settings.mongodb_sensors_collection]
        self._events = self._db[settings.mongodb_events_collection]
        self._sensors.create_index("device_id", unique=True)

    def ping(self) -> bool:
        """Comprueba conectividad con el servidor MongoDB."""
        try:
            self._client.admin.command("ping")
            return True
        except PyMongoError:
            return False

    def list_sensors(self) -> list[SensorResponse]:
        """Devuelve todos los sensores registrados en el catálogo."""
        docs = self._sensors.find().sort("device_id", 1)
        return [self._doc_to_sensor(doc) for doc in docs]

    def create_sensor(self, payload: SensorCreate) -> SensorResponse:
        """
        Registra un sensor en el catálogo. device_id único (índice).
        Raises DuplicateKeyError si ya existe.
        """
        doc = {
            "device_id": payload.device_id,
            "sensor_type": payload.sensor_type,
            "display_name": payload.display_name,
            "location": payload.location,
            "active": payload.active,
            "registered_at": utc_now_iso(),
        }
        self._sensors.insert_one(doc)
        return self._doc_to_sensor(doc)

    def sensor_exists(self, device_id: str) -> bool:
        """Indica si el device_id ya está en el catálogo."""
        return self._sensors.count_documents({"device_id": device_id}, limit=1) > 0

    def get_history(self, device_id: str, limit: int = 100) -> list[ReadingResponse]:
        """
        Histórico completo (o ventana) desde sensor_events, más recientes primero.
        """
        cursor = (
            self._events.find({"device_id": device_id})
            .sort("timestamp", -1)
            .limit(limit)
        )
        readings = []
        for doc in cursor:
            readings.append(
                ReadingResponse(
                    device_id=doc.get("device_id", device_id),
                    sensor_type=doc.get("sensor_type"),
                    value=float(doc.get("value", 0)),
                    timestamp=doc.get("timestamp", doc.get("ingested_at", "")),
                    source="mongodb_history",
                )
            )
        return readings

    def _doc_to_sensor(self, doc: dict) -> SensorResponse:
        """Mapea documento MongoDB a SensorResponse."""
        return SensorResponse(
            device_id=doc["device_id"],
            sensor_type=doc["sensor_type"],
            display_name=doc["display_name"],
            location=doc.get("location"),
            active=doc.get("active", True),
            registered_at=doc["registered_at"],
        )
