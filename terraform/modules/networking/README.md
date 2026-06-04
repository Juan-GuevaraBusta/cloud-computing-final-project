# Módulo networking — Red (pendiente)

## Propósito

Reservado para **VPC, subnets, security groups y ALB** cuando la API en ECS o MongoDB en red privada lo requieran.

## Estado actual

`main.tf` está vacío (solo comentario placeholder).

## Qué se afrontará aquí

- VPC y subnets públicas/privadas para ECS Fargate.
- Security groups: ALB → tasks; tasks → DynamoDB (vía VPC endpoint o internet según lab).
- Acceso restringido a MongoDB (si corre en EC2 o DocumentDB).

## Archivos previstos (futuro)

| Archivo | Responsabilidad |
|---------|-----------------|
| `main.tf` | VPC, IGW, subnets, SG, ALB |
| `variables.tf` | CIDR, entorno |
| `outputs.tf` | IDs de subnets, DNS del ALB |
