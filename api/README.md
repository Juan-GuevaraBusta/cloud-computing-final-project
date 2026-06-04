# api — REST FastAPI (Fase 3)

## Propósito

API unificada sobre **DynamoDB** (lectura actual y recientes) y **MongoDB** (catálogo e histórico). Documentación consumible en **Swagger** sin leer el código fuente.

## Swagger / OpenAPI

| URL | Contenido |
|-----|-----------|
| http://localhost:8000/docs | **Swagger UI** (probar endpoints) |
| http://localhost:8000/redoc | ReDoc |
| http://localhost:8000/openapi.json | Esquema OpenAPI |

## Archivos

| Ruta | Responsabilidad |
|------|-----------------|
| `app/main.py` | App FastAPI, tags, CORS, montaje de routers |
| `app/config.py` | Variables desde `.env` en la raíz del repo |
| `app/schemas.py` | Modelos Pydantic (validación + schema Swagger) |
| `app/dependencies.py` | Inyección DynamoDB / MongoDB |
| `app/services/dynamodb.py` | Query current / recent |
| `app/services/mongodb.py` | Catálogo `sensors` e histórico `sensor_events` |
| `app/routers/health.py` | `GET /health` |
| `app/routers/sensors.py` | `GET/POST /sensors` |
| `app/routers/readings.py` | `GET /sensor/{id}/current|recent|history` |
| `requirements.txt` | Dependencias Python |

## Variables de entorno

Copiar desde `../.env.example` a `../.env`:

| Variable | Uso |
|----------|-----|
| `MONGODB_URI` | Conexión MongoDB (EC2 en VPC) |
| `AWS_REGION` | Región DynamoDB |
| `DYNAMODB_TABLE_NAME` | Default `SensorData-lab` |

## Ejecutar en local

Desde la **raíz del repo** (con venv activo y credenciales AWS del Learner Lab):

```bash
pip install -r api/requirements.txt
make api-run
```

Abrir http://localhost:8000/docs

## Endpoints

| Método | Ruta | Almacén |
|--------|------|---------|
| GET | `/health` | Comprueba DynamoDB + MongoDB |
| GET | `/sensors` | MongoDB |
| POST | `/sensors` | MongoDB |
| GET | `/sensor/{device_id}/current` | DynamoDB |
| GET | `/sensor/{device_id}/recent` | DynamoDB (10) |
| GET | `/sensor/{device_id}/history` | MongoDB |

## Notas

- **DynamoDB** funciona desde tu Mac con credenciales AWS.
- **MongoDB** requiere alcanzar la IP privada del EC2 (túnel SSM/VPN) o probar `/history` cuando la API esté en ECS (Fase 5).
- Preguntas de repaso del curso: `docs/PUERTAS.md`.

## Próximos cambios (Fase 5)

- `Dockerfile` + despliegue en ECS.
- CORS y rate limiting acotados a producción.
