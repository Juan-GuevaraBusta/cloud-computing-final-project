# lambda/s3_to_mongo — Histórico S3 → MongoDB

## Propósito

Función **AWS Lambda** disparada por `s3:ObjectCreated:*` en el bucket de sensores. Lee cada JSON archivado por la regla IoT y lo inserta en MongoDB (`sensor_events`).

## Archivos

| Archivo | Responsabilidad |
|---------|-----------------|
| `handler.py` | Lógica: S3 GetObject → insert MongoDB, índice único `s3_key` |
| `requirements.txt` | Dependencia `pymongo` |
| `build.sh` | Genera carpeta `build/` para el zip de despliegue |
| `build/` | Artefacto generado (ignorar en Git) |

## Variables de entorno (Terraform)

| Variable | Descripción |
|----------|-------------|
| `MONGODB_URI` | URI con usuario/contraseña y host EC2 (VPC) |
| `MONGODB_DB` | Base de datos (default `iot`) |
| `MONGODB_COLLECTION` | Colección (default `sensor_events`) |

## Rol IAM

Usa **LabRole** (`terraform/data.tf`), igual que las reglas IoT. El Learner Lab no permite crear roles nuevos con Terraform.

## Red

La función corre en **VPC** (subnets del módulo `networking`) para alcanzar MongoDB en EC2 sin exponer el puerto 27017 a Internet.

## Build local

```bash
make lambda-build
```

`make aws-up` ejecuta este paso antes de `terraform apply`.
