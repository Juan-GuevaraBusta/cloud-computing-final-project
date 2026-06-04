#!/usr/bin/env bash
# Construye y publica la imagen de la API en ECR (Fase 5).
# Uso: push_api_image.sh <repository_url> [aws_region]
set -euo pipefail

REPO_URL="${1:?Falta URL del repositorio ECR}"
AWS_REGION="${2:-us-east-1}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
API_DIR="${SCRIPT_DIR}/../../../../api"
REGISTRY="${REPO_URL%%/*}"

if ! command -v docker >/dev/null 2>&1; then
  echo "Error: docker no está instalado o no está en PATH" >&2
  exit 1
fi

aws ecr get-login-password --region "${AWS_REGION}" \
  | docker login --username AWS --password-stdin "${REGISTRY}"

docker build --platform linux/amd64 -t "${REPO_URL}:latest" "${API_DIR}"
docker push "${REPO_URL}:latest"

echo "Imagen publicada: ${REPO_URL}:latest"
