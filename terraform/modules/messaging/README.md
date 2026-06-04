# Módulo messaging — Alertas SQS + Lambdas (Fase 4)

## Propósito

Cadena asíncrona de urgencia:

```
IoT Regla 3 (temp > umbral) → Lambda alert_publisher → SQS → Lambda alert_consumer → CloudWatch Logs
```

## Archivos

| Archivo | Responsabilidad |
|---------|-----------------|
| `main.tf` | Cola SQS (+ DLQ), Lambdas, event source mapping SQS→consumer |
| `variables.tf` | `lab_role_arn` |
| `outputs.tf` | ARNs, URL de cola, nombres de funciones |

## Código Lambda

| Función | Carpeta |
|---------|---------|
| Publicador | `lambda/alert_publisher/` |
| Consumidor | `lambda/alert_consumer/` |

La **regla IoT 3** vive en `modules/iot` (necesita ARN de la Lambda publicadora).

## Rol IAM

**LabRole** (Learner Lab); no se crean roles nuevos.

## Verificación

1. `make aws-up` y `make local-up`
2. Esperar lecturas con temperatura > umbral (simulador ~20–35°C; umbral default 30°C)
3. CloudWatch → `/aws/lambda/iot-edge-alert-consumer-lab` → logs `URGENCIA IoT`
4. SQS → cola `iot-edge-alerts-lab` recibe y vacía mensajes
