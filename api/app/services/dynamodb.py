"""
Acceso a DynamoDB (hot data): lectura actual y últimos N eventos.
"""

from boto3.dynamodb.conditions import Key
from botocore.exceptions import ClientError

from app.config import Settings
from app.schemas import ReadingResponse, decimal_to_float


class DynamoDBService:
    """Consultas por device_id usando sort key timestamp."""

    def __init__(self, settings: Settings):
        import boto3

        self._table_name = settings.dynamodb_table_name
        self._resource = boto3.resource("dynamodb", region_name=settings.aws_region)
        self._table = self._resource.Table(self._table_name)

    def ping(self) -> bool:
        """Comprueba que la tabla existe y es accesible."""
        try:
            self._table.load()
            return True
        except ClientError:
            return False

    def get_current(self, device_id: str) -> ReadingResponse | None:
        """
        Última lectura del sensor: Query por device_id, orden descendente, Limit 1.
        """
        response = self._table.query(
            KeyConditionExpression=Key("device_id").eq(device_id),
            ScanIndexForward=False,
            Limit=1,
        )
        items = response.get("Items", [])
        if not items:
            return None
        return self._item_to_reading(items[0])

    def get_recent(self, device_id: str, limit: int = 10) -> list[ReadingResponse]:
        """
        Últimos N eventos del sensor en DynamoDB (misma Query con Limit=N).
        """
        response = self._table.query(
            KeyConditionExpression=Key("device_id").eq(device_id),
            ScanIndexForward=False,
            Limit=limit,
        )
        return [self._item_to_reading(item) for item in response.get("Items", [])]

    def _item_to_reading(self, item: dict) -> ReadingResponse:
        """Mapea ítem DynamoDB a respuesta API."""
        return ReadingResponse(
            device_id=item["device_id"],
            sensor_type=item.get("sensor_type"),
            value=decimal_to_float(item["value"]),
            timestamp=item["timestamp"],
            source="dynamodb",
        )
