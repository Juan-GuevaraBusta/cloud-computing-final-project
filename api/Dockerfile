# API FastAPI para ECS Fargate (Fase 5).
# Build: docker build --platform linux/amd64 -t <ecr-url>:latest ./api

FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app ./app

EXPOSE 8000

# Variables de entorno inyectadas por ECS (MONGODB_URI, DYNAMODB_TABLE_NAME, AWS_REGION).
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
