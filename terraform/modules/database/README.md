# Módulo database — DynamoDB (Hot Data)

## Propósito

Tabla para el **estado más reciente** de cada sensor (patrón device shadow / device twin), no para historial completo.

## Archivos

| Archivo | Responsabilidad |
|---------|-----------------|
| `main.tf` | Recurso `aws_dynamodb_table.sensor_data` |
| `variables.tf` | `project_name`, `environment` |
| `outputs.tf` | Nombre de tabla para reglas IoT y API futura |

## Diseño de la tabla

- **Nombre:** `SensorData-{environment}`
- **Claves:** `device_id` (partition) + `timestamp` (sort key) — Fase 1 opción A
- **Comportamiento:** cada evento con distinto `timestamp` es un ítem nuevo; `GET /recent` usa `Query` + `Limit=10`
- **Billing:** `PAY_PER_REQUEST`

## Uso en el proyecto final

| Endpoint API | Relación con esta tabla |
|--------------|-------------------------|
| `GET /sensor/{id}/current` | Lectura directa por `device_id` |
| `GET /sensor/{id}/recent` | Requiere **cambio de diseño** (sort key, GSI o tabla de eventos) — ver `docs/DECISIONES.md` |
| `POST /sensors` | Probable **nueva tabla** de catálogo (no implementada aún) |

## Próximos cambios

- Evaluar tabla adicional o sort key `timestamp` para últimos N eventos.
- Permisos IAM para la API en ECS (lectura/escritura).
