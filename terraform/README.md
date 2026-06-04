# terraform — Infraestructura como código (AWS)

## Propósito

Despliega y configura los recursos del **laboratorio base** en AWS Learner Lab: almacenamiento (S3), estado caliente (DynamoDB), identidad y reglas de **IoT Core**, y artefactos locales para el Edge Gateway (certificados + `mosquitto.conf`).

## Estructura de módulos

```
terraform/
├── main.tf          # Orquesta módulos storage, database, iot
├── data.tf          # LabRole, cuenta, región, endpoint IoT, Root CA HTTP
├── variables.tf     # project_name, environment
├── outputs.tf       # Salidas útiles tras apply
└── modules/
    ├── storage/     # Buckets S3 (datos + resultados Athena)
    ├── database/    # Tabla DynamoDB SensorData
    ├── iot/         # Thing, certificados, política, reglas, archivos locales
    ├── compute/     # (vacío) Lambdas y ECS — proyecto final
    └── networking/  # (vacío) VPC, SG — proyecto final
```

## Flujo tras `terraform apply`

1. Crea buckets y tabla DynamoDB.
2. Crea Thing, certificado y política IoT; adjunta permisos al certificado.
3. Define reglas IoT → DynamoDB y IoT → S3 en paralelo.
4. Escribe certificados y `mosquitto.conf` en `../edge_gateway/`.

## Archivos raíz

| Archivo | Responsabilidad |
|---------|-----------------|
| `main.tf` | Provider AWS y llamadas a módulos |
| `data.tf` | Datos de cuenta, `LabRole`, endpoint IoT, descarga Root CA |
| `variables.tf` | Nombre del proyecto y sufijo de entorno |
| `outputs.tf` | Valores de salida post-despliegue |

## Próximos cambios (proyecto final)

| Módulo | Qué se afrontará |
|--------|------------------|
| `database` | Posible tabla de catálogo de sensores o sort key para `/recent` |
| `storage` | Notificación S3 → Lambda |
| `iot` | Regla 3 (alertas por umbral de temperatura) |
| `compute` | Lambdas (S3→MongoDB, alertas), ECS + FastAPI |
| `networking` | VPC/subnets si MongoDB o ECS lo requieren |

## Comandos

```bash
make aws-up    # init + apply
make aws-down  # destroy
make clean     # destroy + limpia certs locales
```

Ver README de cada submódulo en `modules/*/README.md`.
