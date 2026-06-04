# API FastAPI — IoT Edge Platform

## Local (Fase 3)

```bash
make api-install
# .env en la raíz con MONGODB_URI (terraform output) y DYNAMODB_TABLE_NAME
make api-run
```

Swagger: http://127.0.0.1:8000/docs

## AWS ECS (Fase 5)

La imagen se construye desde este directorio (`Dockerfile`). Variables de entorno las inyecta el task definition de Terraform (no se usa `.env` en el contenedor).

```bash
make aws-up
terraform -chdir=terraform output -raw api_swagger_url
```

Tras cambiar código en `app/`:

```bash
make api-ecs-redeploy
```

## Endpoints principales

| Ruta | Descripción |
|------|-------------|
| `GET /health` | DynamoDB + MongoDB (health check del ALB) |
| `GET /current` | Última lectura por `device_id` (DynamoDB) |
| `GET /recent` | Histórico reciente (DynamoDB) |
| `GET/POST /sensors` | Catálogo MongoDB `sensors` |
