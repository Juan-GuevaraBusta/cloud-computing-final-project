# Módulo storage — Amazon S3 (Cold Data)

## Propósito

Persistir **cada evento** como archivo JSON para analítica histórica (consultas con Athena) y como disparador futuro de Lambda hacia MongoDB.

## Archivos

| Archivo | Responsabilidad |
|---------|-----------------|
| `main.tf` | Buckets de datos de sensores y resultados Athena |
| `variables.tf` | `project_name`, `environment` |
| `outputs.tf` | Nombre del bucket de sensores para reglas IoT |

## Buckets

| Recurso | Uso |
|---------|-----|
| `aws_s3_bucket.sensor_data` | Archivos JSON por evento (regla IoT) |
| `aws_s3_bucket.athena_results` | Resultados de consultas Athena (laboratorio) |

## Particionado (regla IoT)

Las claves de objeto siguen el patrón:

`data/year=YYYY/month=MM/day=DD/{uuid}.json`

Facilita consultas por rango de fechas en Athena sin escanear todo el bucket.

## Próximos cambios

- Event notification `s3:ObjectCreated:*` → Lambda `s3_to_mongo`.
- Política y rol IAM para que Lambda lea objetos del bucket.
