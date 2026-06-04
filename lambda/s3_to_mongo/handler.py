"""
Lambda: copia eventos de sensores desde S3 hacia MongoDB (histórico / cold path).

Trigger: s3:ObjectCreated en el bucket de datos del proyecto.
Colección destino: sensor_events (idempotente por s3_key).
"""

import json
import logging
import os
from datetime import datetime, timezone

import boto3
from pymongo import MongoClient
from pymongo.errors import DuplicateKeyError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

MONGODB_URI = os.environ["MONGODB_URI"]
MONGODB_DB = os.environ.get("MONGODB_DB", "iot")
MONGODB_COLLECTION = os.environ.get("MONGODB_COLLECTION", "sensor_events")

_s3 = boto3.client("s3")
_mongo_client: MongoClient | None = None


def _get_collection():
    """Cliente MongoDB reutilizado entre invocaciones (warm start)."""
    global _mongo_client
    if _mongo_client is None:
        _mongo_client = MongoClient(MONGODB_URI, serverSelectionTimeoutMS=5000)
        collection = _mongo_client[MONGODB_DB][MONGODB_COLLECTION]
        collection.create_index("s3_key", unique=True)
    return _mongo_client[MONGODB_DB][MONGODB_COLLECTION]


def _parse_s3_records(event: dict) -> list[tuple[str, str]]:
    """Extrae (bucket, key) de un evento de notificación S3."""
    records = []
    for record in event.get("Records", []):
        bucket = record["s3"]["bucket"]["name"]
        key = record["s3"]["object"]["key"]
        records.append((bucket, key))
    return records


def _load_sensor_payload(bucket: str, key: str) -> dict:
    """Lee y parsea el JSON del objeto en S3."""
    response = _s3.get_object(Bucket=bucket, Key=key)
    body = response["Body"].read().decode("utf-8")
    return json.loads(body)


def _build_document(bucket: str, key: str, payload: dict) -> dict:
    """Arma el documento a insertar en MongoDB."""
    return {
        "device_id": payload.get("device_id"),
        "sensor_type": payload.get("sensor_type"),
        "value": payload.get("value"),
        "timestamp": payload.get("timestamp"),
        "s3_bucket": bucket,
        "s3_key": key,
        "ingested_at": datetime.now(timezone.utc).isoformat(),
        "source": "s3_object_created",
    }


def lambda_handler(event, context):
    """
    Punto de entrada AWS Lambda.

    Por cada objeto creado en S3, inserta un documento en MongoDB.
    Duplicados (mismo s3_key) se ignoran de forma segura.
    """
    collection = _get_collection()
    processed = 0
    skipped = 0
    errors = 0

    for bucket, key in _parse_s3_records(event):
        try:
            payload = _load_sensor_payload(bucket, key)
            document = _build_document(bucket, key, payload)
            collection.insert_one(document)
            processed += 1
            logger.info("Insertado histórico device_id=%s key=%s", document.get("device_id"), key)
        except DuplicateKeyError:
            skipped += 1
            logger.info("Duplicado ignorado s3_key=%s", key)
        except Exception as exc:
            errors += 1
            logger.exception("Error procesando s3://%s/%s: %s", bucket, key, exc)
            raise

    return {
        "statusCode": 200,
        "body": json.dumps({"processed": processed, "skipped": skipped, "errors": errors}),
    }
