.PHONY: aws-up aws-down local-up local-down logs clean lambda-build api-run api-install

# --- Comandos AWS (Terraform) ---

lambda-build:
	@echo "Empaquetando Lambda s3_to_mongo (dependencias Linux x86_64)..."
	chmod +x lambda/s3_to_mongo/build.sh
	bash lambda/s3_to_mongo/build.sh

aws-up: lambda-build
	@echo "Desplegando infraestructura en AWS (IoT, DynamoDB, S3, VPC, EC2 MongoDB, Lambda)..."
	mkdir -p edge_gateway/certs
	cd terraform && terraform init -upgrade && terraform apply -auto-approve
	@echo "Infraestructura desplegada. Certificados y mosquitto.conf generados."
	@echo "URI MongoDB (sensible): terraform -chdir=terraform output -raw mongodb_uri"

aws-down:
	@echo "Destruyendo infraestructura en AWS..."
	cd terraform && terraform destroy -auto-approve
	@echo "Infraestructura de AWS destruida."

# --- Comandos Locales (Docker Compose) ---

local-up:
	@echo "Levantando Edge Gateway (Mosquitto) y Sensores locales..."
	docker compose up -d --build
	@echo "Contenedores iniciados. Usa 'make logs' para ver el flujo de datos."

local-down:
	@echo "Deteniendo contenedores locales..."
	docker compose down
	@echo "Contenedores detenidos."

logs:
	docker compose logs -f

# --- API FastAPI (Fase 3) ---

api-install:
	./venv/bin/pip install -r api/requirements.txt

api-run:
	@echo "Swagger UI: http://127.0.0.1:8000/docs"
	cd api && ../venv/bin/uvicorn app.main:app --reload --host 127.0.0.1 --port 8000

clean: local-down aws-down
	@echo "Limpiando certificados locales..."
	rm -rf edge_gateway/certs/*
	rm -f edge_gateway/mosquitto.conf
	@echo "Entorno limpio."
