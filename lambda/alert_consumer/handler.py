"""
Lambda consumidora de alertas (Fase 4).

Trigger: cola SQS. Escribe un log de urgencia en CloudWatch Logs.
"""

import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    """
    Procesa cada registro SQS y registra la alerta en CloudWatch.
    """
    processed = 0

    for record in event.get("Records", []):
        body = json.loads(record["body"])
        logger.critical(
            "URGENCIA IoT | %s | device=%s value=%s ts=%s",
            body.get("message"),
            body.get("device_id"),
            body.get("value"),
            body.get("timestamp"),
        )
        processed += 1

    return {"statusCode": 200, "processed": processed}
