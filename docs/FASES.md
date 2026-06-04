# Fases del proyecto y puertas de conocimiento

## Fase 0 — Laboratorio base (actual)

**Objetivo:** Entender y documentar sensores → Mosquitto → IoT → DynamoDB + S3.

**Entregables:** README por carpeta, comentarios en código, lab ejecutado.

**Puerta hacia Fase 1:** Responder correctamente las preguntas de comprensión (ver evaluación en el chat o repasar `FLUJO.md`).

---

## Fase 1 — Decisiones de diseño ✅

**Objetivo:** Completar `docs/DECISIONES.md` (`/recent`, catálogo sensores, hosting MongoDB).

**Completado:** Opción A (sort key), catálogo en MongoDB `sensors`, EC2 `t3.micro` + auth + Lambda en VPC.

**Puerta hacia Fase 2:** Poder explicar preguntas 2–4 en `docs/DECISIONES.md` (sección “Puerta Fase 1”) sin leer.

---

## Fase 2 — S3 → Lambda → MongoDB ✅

**Objetivo:** Histórico en MongoDB; Terraform en `modules/networking` + `modules/compute`.

**Implementado en repo:**

- VPC, SG, endpoint S3, EC2 `t3.micro` + MongoDB autenticado
- Lambda `s3_to_mongo` en VPC + notificación S3 (`data/`)
- DynamoDB con sort key `timestamp`
- `make lambda-build` + `make aws-up`

**Verificación:** tras deploy, esperar 5 min, subir datos con sensores, revisar CloudWatch y colección `sensor_events`.

---

## Fase 3 — API FastAPI (local) ✅

**Objetivo:** Endpoints contra DynamoDB y MongoDB.

**Implementado:**

- Carpeta `api/` con FastAPI, Pydantic, servicios DynamoDB/MongoDB
- Swagger: http://localhost:8000/docs (`make api-run`)
- Repaso de preguntas: `docs/PUERTAS.md`

**Puerta hacia Fase 4:** ✅ Respuestas en `docs/DECISIONES.md` (sección Puerta Fase 3 → Fase 4).

---

## Fase 4 — Alertas IoT → Lambda → SQS → CloudWatch ✅

**Implementado:**

- Módulo `terraform/modules/messaging` (SQS + 2 Lambdas)
- Regla IoT 3 en `modules/iot` (temperatura > umbral, default 30°C)
- `lambda/alert_publisher`, `lambda/alert_consumer`

**Verificación:** CloudWatch log group del consumer con mensajes `URGENCIA IoT`.

**Puerta hacia Fase 5:** ✅ [PUERTAS.md](PUERTAS.md) y [DECISIONES.md](DECISIONES.md#puerta-fase-4--fase-5--respuestas-aprobada).

---

## Fase 5 — ECS + ALB + Swagger en AWS ✅

**Objetivo:** API FastAPI en Fargate detrás de ALB; MongoDB por IP privada en la VPC.

**Implementado:**

- `api/Dockerfile` (imagen `linux/amd64`)
- `terraform/modules/networking`: SG ALB + ECS; MongoDB acepta tráfico desde ECS
- `terraform/modules/compute/ecs.tf`: ECR, push automático en `apply`, cluster, task, servicio, ALB
- Outputs: `api_swagger_url`, `ecr_repository_url`
- `make api-ecr-push` / `make api-ecs-redeploy` para actualizar código sin `terraform apply` completo

**Despliegue:**

```bash
make aws-up   # requiere Docker; publica imagen y crea ECS
```

Tras 2–3 min (Mongo + tarea ECS healthy):

```bash
terraform -chdir=terraform output -raw api_swagger_url
curl "$(terraform -chdir=terraform output -raw api_swagger_url | sed 's|/docs||')/health"
```

**Verificación:** `/health` con `mongodb: ok` y `dynamodb: ok`; `/current` y `/recent` con datos del simulador.

**Puerta hacia Fase 6:** ✅ [PUERTAS.md](PUERTAS.md#fase-5--fase-6-preparación-sustentación-) · Demo: [SUSTENTACION.md](SUSTENTACION.md).

---

## Fase 6 — Nuevo sensor (sustentación)

**Objetivo (enunciado):** demostrar en vivo un tercer tipo de sensor.

**Guía completa paso a paso:** [docs/SUSTENTACION.md](SUSTENTACION.md)

**Resumen:**

1. Extender `python_device/sensor_simulator.py` / `docker-compose.yml` con nuevo `SENSOR_TYPE` y `CLIENT_ID`.
2. `make local-up` y ver publicaciones en logs.
3. Swagger (ALB): `POST /sensors` → `GET .../current`, `/recent`, `/history`.
4. Repaso oral: [PUERTAS.md](PUERTAS.md) Fase 5 → 6.

**Puerta:** respuestas en [DECISIONES.md — Puerta Fase 5 → Fase 6](DECISIONES.md#puerta-fase-5--fase-6--respuestas-aprobada--preparación-sustentación).
