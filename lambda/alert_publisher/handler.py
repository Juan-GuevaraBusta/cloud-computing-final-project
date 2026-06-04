"""
Lambda publicadora de alertas (Fase 4).

Disparada por la Regla IoT 3 cuando temperatura supera el umbral.
Envía un mensaje de emergencia a SQS para desacoplar el procesamiento.
"""

import json
import logging
import os
from datetime import datetime, timezone

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

SQS_QUEUE_URL = os.environ["ALERT_QUEUE_URL"]


def _build_alert_message(event: dict) -> dict:
    """
    Formatea el payload de IoT Core como mensaje de urgencia para SQS.
    """
    return {
        "alert_type": "HIGH_TEMPERATURE",
        "severity": "CRITICAL",
        "device_id": event.get("device_id"),
        "sensor_type": event.get("sensor_type"),
        "value": event.get("value"),
        "timestamp": event.get("timestamp"),
        "message": (
            f"ALERTA: temperatura crítica en {event.get('device_id')} "
            f"= {event.get('value')}°C"
        ),
        "published_at": datetime.now(timezone.utc).isoformat(),
    }


def lambda_handler(event, context):
    """
    Punto de entrada: recibe el evento de IoT Rule y publica en SQS.
    """
    sqs = boto3.client("sqs")
    body = _build_alert_message(event)

    response = sqs.send_message(
        QueueUrl=SQS_QUEUE_URL,
        MessageBody=json.dumps(body),
    )

    logger.info(
        "Alerta encolada device_id=%s value=%s messageId=%s",
        body.get("device_id"),
        body.get("value"),
        response.get("MessageId"),
    )

    return {
        "statusCode": 200,
        "body": json.dumps({"queued": True, "messageId": response.get("MessageId")}),
    }
