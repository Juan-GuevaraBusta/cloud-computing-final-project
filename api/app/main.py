"""
API REST unificada — plataforma IoT (Fase 3).

Documentación interactiva:
  - Swagger UI: /docs
  - ReDoc:      /redoc
  - OpenAPI:    /openapi.json
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import get_settings
from app.routers import health, readings, sensors

settings = get_settings()

app = FastAPI(
    title=settings.api_title,
    version=settings.api_version,
    description="""
API del proyecto IoT Edge → AWS IoT Core → DynamoDB (hot) + S3 → Lambda → MongoDB (histórico).

**Documentación del curso:** ver `docs/PUERTAS.md`, `docs/DECISIONES.md` y `docs/FASES.md`.

| Endpoint | Almacén |
|----------|---------|
| `GET/POST /sensors` | MongoDB catálogo |
| `GET /sensor/{id}/current` | DynamoDB |
| `GET /sensor/{id}/recent` | DynamoDB (10) |
| `GET /sensor/{id}/history` | MongoDB eventos |
    """,
    openapi_tags=[
        {"name": "Salud", "description": "Monitoreo y readiness"},
        {"name": "Catálogo de sensores", "description": "Registro lógico POST/GET /sensors"},
        {"name": "Lecturas de sensores", "description": "Telemetría current/recent/history"},
    ],
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
)

# CORS permisivo en desarrollo local (ajustar en ECS/producción)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health.router)
app.include_router(sensors.router)
app.include_router(readings.router)


@app.get("/", include_in_schema=False)
def root():
    """Redirige mentalmente a Swagger; enlace explícito para navegadores."""
    return {
        "message": "IoT Platform API",
        "swagger": "/docs",
        "redoc": "/redoc",
        "health": "/health",
    }
