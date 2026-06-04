# Módulo networking — VPC para MongoDB y Lambda

## Propósito

Crea red aislada para que **Lambda** (S3 → MongoDB) y **EC2** (MongoDB Docker) se comuniquen sin exponer el puerto 27017 a Internet.

## Recursos

| Recurso | Función |
|---------|---------|
| `aws_vpc` | VPC `10.42.0.0/16` con DNS |
| `aws_subnet` (x2) | Subnets públicas en `a` y `b` (Lambda requiere 2 AZ) |
| `aws_internet_gateway` | Salida de EC2 para `docker pull` en el bootstrap |
| `aws_vpc_endpoint` (S3) | Lambda lee objetos S3 sin NAT |
| `aws_security_group.lambda` | Egress amplio |
| `aws_security_group.mongodb` | Ingress 27017 desde Lambda y ECS |
| `aws_security_group.alb` | HTTP 80 desde Internet (lab) |
| `aws_security_group.ecs` | Puerto 8000 solo desde ALB |

## Fase 5

ECS Fargate en subnets públicas (`assign_public_ip`) para pull de ECR sin NAT. ALB público → target group `/health`.
