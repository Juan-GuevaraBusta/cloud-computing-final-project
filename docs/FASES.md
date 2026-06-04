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

## Fase 2 — S3 → Lambda → MongoDB

**Objetivo:** Histórico en MongoDB; Terraform en `modules/compute`.

---

## Fase 3 — API FastAPI (local)

**Objetivo:** Endpoints contra DynamoDB y MongoDB.

---

## Fase 4 — Alertas IoT → Lambda → SQS → CloudWatch

---

## Fase 5 — ECS + Terraform completo

---

## Fase 6 — Nuevo sensor (sustentación)
