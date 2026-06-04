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

**Puerta hacia Fase 5:** ver `docs/PUERTAS.md` (sección Fase 4 → 5, al cerrar ECS).

---

## Fase 5 — ECS + Terraform completo

---

## Fase 6 — Nuevo sensor (sustentación)
