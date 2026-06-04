# Módulo compute — Cómputo (pendiente)

## Propósito

Reservado para **AWS Lambda** y **Amazon ECS** del proyecto final. En el laboratorio base no despliega recursos.

## Estado actual

`main.tf` está vacío (solo comentario placeholder).

## Qué se afrontará aquí

| Componente | Función |
|------------|---------|
| Lambda `s3_to_mongo` | Trigger S3 → leer JSON → insertar en MongoDB |
| Lambda `alert_publisher` | IoT Rule 3 → enviar mensaje a SQS |
| Lambda `alert_consumer` | SQS → log en CloudWatch |
| ECS + ECR | Contenedor FastAPI (API REST) |

## Archivos previstos (futuro)

| Archivo | Responsabilidad |
|---------|-----------------|
| `main.tf` | Lambdas, roles IAM, ECS cluster, task definition, ECR |
| `variables.tf` | URIs, nombres de colas, imagen Docker |
| `outputs.tf` | URL del ALB, ARNs de Lambdas |
