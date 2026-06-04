# Lambda alert_publisher

## Propósito

Recibe el evento de la **Regla IoT 3** (temperatura > umbral) y envía un JSON de emergencia a **SQS**.

## Variables de entorno

| Variable | Descripción |
|----------|-------------|
| `ALERT_QUEUE_URL` | URL de la cola SQS (Terraform) |

## Build

Incluido en `make lambda-build` / `lambda/build_all.sh`.
