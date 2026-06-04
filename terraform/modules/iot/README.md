# Módulo IoT — Thing, mTLS, política y reglas

## Propósito

Representa el **Edge Gateway** en AWS IoT Core, genera credenciales X.509, restringe permisos MQTT y enruta mensajes del tópico `lab/sensors/data` hacia DynamoDB y S3.

## Archivos

| Archivo | Responsabilidad |
|---------|-----------------|
| `main.tf` | Thing, certificado, política, adjuntos, archivos locales, reglas IoT |
| `variables.tf` | Entradas: ARNs, endpoint, bucket, tabla, Root CA |
| `outputs.tf` | Salidas del módulo (si aplica) |

## Recursos principales

- **`aws_iot_thing`**: Identidad lógica del gateway (`edge-gateway-01-{env}`).
- **`aws_iot_certificate`**: Par de claves y certificado PEM.
- **`aws_iot_policy`**: Solo `lab/sensors/*` y client id del Thing.
- **`local_file`**: Escribe certs y `mosquitto.conf` en `edge_gateway/`.
- **`aws_iot_topic_rule` (DynamoDB)**: Hot data — actualiza por `device_id`.
- **`aws_iot_topic_rule` (S3)**: Cold data — JSON particionado por fecha.

## Reglas actuales (2)

| Regla | SQL | Acción |
|-------|-----|--------|
| `SensorDataToDynamoDB_*` | `SELECT * FROM 'lab/sensors/data'` | `dynamodbv2` PutItem |
| `SensorDataToS3_*` | `SELECT * FROM 'lab/sensors/data'` | `s3` PutObject con particiones `year/month/day` |

## Regla 3 — Alertas (Fase 4) ✅

| Recurso | Descripción |
|---------|-------------|
| `aws_iot_topic_rule.temperature_alert` | `temperature` y `value > umbral` (default 30°C) |
| `aws_lambda_permission` | IoT Core → Lambda `alert_publisher` |

Umbral configurable: variable `temperature_alert_threshold` en `terraform/variables.tf`.
