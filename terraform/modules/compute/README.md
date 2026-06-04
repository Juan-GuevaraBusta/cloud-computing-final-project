# Módulo compute — EC2 MongoDB + Lambda S3 → MongoDB

## Propósito (Fase 2)

| Componente | Función |
|------------|---------|
| `aws_instance.mongodb` | `t3.micro` con MongoDB 7 en Docker y autenticación |
| `aws_lambda_function.s3_to_mongo` | Procesa `s3:ObjectCreated` bajo prefijo `data/` |
| `aws_s3_bucket_notification` | Enlaza bucket de sensores con la Lambda |
| Rol de ejecución | **LabRole** (Learner Lab no permite `iam:CreateRole`) |

## Archivos

| Archivo | Responsabilidad |
|---------|-----------------|
| `main.tf` | EC2, Lambda, IAM, notificación S3, empaquetado zip |
| `user_data/mongodb.sh.tpl` | Bootstrap Docker + contenedor Mongo |
| `variables.tf` / `outputs.tf` | Entradas y URI sensible |

## Código de la Lambda

Fuente en `lambda/s3_to_mongo/` (ver README de esa carpeta).

## Post-despliegue

1. Esperar **3–5 min** tras `make aws-up` (Docker + Mongo en EC2).
2. `make local-up` y generar eventos en S3.
3. Revisar logs: CloudWatch → función `iot-edge-s3-to-mongo-lab`.
4. URI para `.env`: `terraform -chdir=terraform output -raw mongodb_uri` (solo útil con acceso a la VPC).

## Costos

EC2 y Lambda solo existen mientras el stack de Terraform esté arriba (`make aws-down` / `make clean`).
