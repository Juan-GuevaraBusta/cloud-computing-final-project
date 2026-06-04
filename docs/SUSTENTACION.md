# Guía de sustentación — Plataforma IoT Edge

Documento para la **defensa oral y demo en vivo** del proyecto final (Computación en la Nube). Resume qué se presenta, en qué orden y qué debe estar funcionando antes de entrar al salón.

**Documentación de apoyo:** [DECISIONES.md](DECISIONES.md) · [PUERTAS.md](PUERTAS.md) · [FASES.md](FASES.md) · [FLUJO.md](../FLUJO.md)

---

## 1. Qué vas a sustentar

Evolución del **laboratorio base** (sensores → Mosquitto → IoT → DynamoDB + S3) a una **plataforma IoT** con:

| Capa | Componentes | Para qué sirve en la demo |
|------|-------------|---------------------------|
| Edge (local) | Docker: sensores + Mosquitto bridge | Generar telemetría en tiempo real |
| Ingesta AWS | IoT Core (3 reglas) | Hot (DynamoDB), cold (S3), alertas |
| Procesamiento | Lambda S3→Mongo, Lambdas alerta + SQS | Histórico y urgencias |
| Datos | DynamoDB, S3, MongoDB en EC2 | Actual, archivo, histórico y catálogo |
| Exposición | API FastAPI en **ECS** + ALB | Swagger y endpoints REST |
| Seguridad | mTLS, VPC, SG, LabRole, `.env` fuera de Git | Preguntas de arquitectura |

**Fases ya implementadas (0–5):** ver tabla en [DECISIONES.md — Estado del proyecto](DECISIONES.md#estado-del-proyecto-hasta-fase-5).

**Actividad en vivo (Fase 6 — enunciado):** agregar un **nuevo tipo de sensor** (distinto a temperatura y humedad), levantarlo en Docker, registrarlo con `POST /sensors` y demostrar lecturas en Swagger.

---

## 2. Requisitos antes de la sustentación

- [ ] Cuenta **AWS Academy Learner Lab** activa (credenciales en `~/.aws/credentials`).
- [ ] `make aws-up` ejecutado sin errores (Terraform + Lambdas + ECS).
- [ ] `make local-up` con sensores publicando (ver `make logs`).
- [ ] Swagger AWS abierto:  
  `terraform -chdir=terraform output -raw api_swagger_url`
- [ ] Opcional local: `make api-run` + `.env` (DynamoDB sí; Mongo local suele fallar sin túnel).
- [ ] Repasar [PUERTAS.md](PUERTAS.md) (preguntas Fase 0–5).
- [ ] Tener preparado el **nuevo sensor** en código (Fase 6) o ensayado el diff en `sensor_simulator.py` + `docker-compose.yml`.

**Tiempo de calentamiento tras `aws-up`:** 3–5 min (Mongo en EC2 + tarea ECS healthy). Con simulador activo, 2–3 min más para ver `/history` con datos.

---

## 3. Arquitectura en una frase (para la introducción)

> Los sensores publican en MQTT local; Mosquitto reenvía por mTLS a IoT Core; las reglas escriben en DynamoDB (tiempo real), S3 (archivo) y disparan alertas si la temperatura supera 30 °C; S3 activa una Lambda que persiste el histórico en MongoDB; la API en ECS consulta DynamoDB y MongoDB y se documenta sola en Swagger.

Diagrama completo: [README.md del repo](../README.md) y [FLUJO.md](../FLUJO.md).

---

## 4. Paso a paso de la demo (≈ 15–25 min)

### Bloque A — Contexto (2–3 min, sin AWS)

1. Mostrar `docker-compose.yml`: sensores + Mosquitto.
2. Explicar payload JSON: `device_id`, `sensor_type`, `value`, `timestamp` en `lab/sensors/data`.
3. Mencionar certificados en `edge_gateway/certs/` y que el secreto es `private.pem.key`.

### Bloque B — Nube ya desplegada (5–8 min)

1. Abrir **Swagger en el ALB** (`api_swagger_url`).
2. **`GET /health`** → `status: ok`, DynamoDB y MongoDB ok.
3. **`GET /sensor/sensor-temp-01/current`** → última temperatura.
4. **`GET /sensor/sensor-temp-01/recent`** → hasta 10 lecturas (sort key `timestamp`).
5. **`GET /sensors`** → catálogo (si vacío, hacer **`POST /sensors`** para temp y humedad).
6. **`GET /sensor/sensor-temp-01/history`** → histórico desde MongoDB (cadena S3 → Lambda).
7. Consola AWS (opcional): bucket S3 con prefijo `data/`, tabla DynamoDB, log group Lambda `s3-to-mongo` con “Insertado histórico”.

### Bloque C — Alertas (2–3 min)

1. Explicar regla 3: temperatura **> 30 °C** (`terraform/variables.tf`).
2. Con simulador activo, si `value` > 30, mostrar **CloudWatch** → `/aws/lambda/iot-edge-alert-consumer-lab` → texto **`URGENCIA IoT`**.
3. Mencionar SQS entre publisher y consumer (desacople).

### Bloque D — Fase 6 en vivo (5–10 min) ⭐

Según el enunciado del README del curso:

1. **Código:** en `python_device/sensor_simulator.py`, el simulador ya soporta `SENSOR_TYPE` por variable de entorno (añadir un tipo nuevo, p. ej. `pressure`, `light`, `co2` — el que elijan).
2. **`docker-compose.yml`:** agregar un tercer servicio con `CLIENT_ID`, `SENSOR_TYPE` y `INTERVAL` distintos.
3. Terminal: `docker compose up -d --build` (o `make local-up`).
4. **Swagger (ALB):** `POST /sensors` con el nuevo `device_id` y `sensor_type`.
5. Esperar **1–2 min**; probar:
   - `GET /sensor/{nuevo-id}/current`
   - `GET /sensor/{nuevo-id}/recent`
   - `GET /sensor/{nuevo-id}/history` (puede tardar un poco más por S3 → Lambda).
6. Cerrar mostrando que el **mismo flujo** aplica a cualquier tipo de sensor.

### Bloque E — Preguntas del profesor (usa PUERTAS)

Tener a mano [PUERTAS.md](PUERTAS.md) y [DECISIONES.md](DECISIONES.md): sort key DynamoDB, catálogo vs telemetría, por qué Mongo vía S3, LabRole, VPC, umbral 30 °C, encoding S3 `%3D` (si preguntan por un incidente de histórico vacío).

---

## 5. Comandos de referencia rápida

```bash
# Infraestructura AWS
make aws-up

# Sensores locales
make local-up
make logs

# URL Swagger en la nube
terraform -chdir=terraform output -raw api_swagger_url

# Salud API (sustituir DNS del ALB)
curl -s "http://$(terraform -chdir=terraform output -raw api_alb_dns_name)/health"

# Destruir todo al terminar el curso / ahorrar créditos
make clean
```

**Actualizar solo la API en ECS** (sin terraform completo):

```bash
make api-ecs-redeploy
```

---

## 6. Ejemplo `POST /sensors` (Swagger)

**Temperatura (si no está registrado):**

```json
{
  "device_id": "sensor-temp-01",
  "sensor_type": "temperature",
  "display_name": "Sensor temperatura",
  "location": "Laboratorio",
  "active": true
}
```

**Nuevo sensor (Fase 6 — ejemplo presión):**

```json
{
  "device_id": "sensor-pressure-01",
  "sensor_type": "pressure",
  "display_name": "Sensor presión",
  "location": "Laboratorio",
  "active": true
}
```

El `device_id` debe coincidir con `CLIENT_ID` en `docker-compose.yml`.

---

## 7. Problemas frecuentes y qué decir

| Síntoma | Causa probable | Qué hacer |
|---------|----------------|-----------|
| `/history` vacío | Lambda S3 fallaba (keys URL-encoded) — **ya corregido** | Ver logs `Insertado histórico`; dejar simulador 3–5 min |
| `/health` Mongo error en Mac | IP privada VPC | Demo en Swagger del **ALB**, no local |
| `409` en POST /sensors | Sensor ya registrado | Normal; usar GET /sensors |
| Sin alertas | Temperatura ≤ 30 °C | Esperar pico aleatorio o explicar umbral en `variables.tf` |
| ECS unhealthy | Mongo o imagen ECR | Esperar 5 min tras `aws-up`; revisar target group |

---

## 8. Checklist el día de la sustentación

- [ ] Learner Lab iniciado (timer de sesión).
- [ ] `make aws-up` hecho antes (o con tiempo de espera 5 min).
- [ ] `make local-up` + logs visibles.
- [ ] Pestaña Swagger ALB lista.
- [ ] Pestaña CloudWatch (consumer alertas) opcional.
- [ ] Diff o rama con **nuevo sensor** listo para mostrar en editor.
- [ ] [PUERTAS.md](PUERTAS.md) repasado.
- [ ] Plan B: si falla internet, capturas o video corto de Swagger (solo si el curso lo permite).

---

## 9. Cierre sugerido (30 segundos)

> Implementamos hot path en DynamoDB, archivo en S3, histórico en MongoDB vía Lambda, alertas desacopladas con SQS, API documentada en ECS detrás de un ALB, y el edge sigue siendo Mosquitto con mTLS. La Fase 6 demuestra que la plataforma acepta nuevos tipos de sensor sin cambiar IoT Core: solo catálogo API y contenedor Docker.

---

## 10. Después de la sustentación

```bash
make clean   # evita costos EC2 / ECS / NAT implícitos en subnets públicas
```

No commitear `.env` ni certificados en `edge_gateway/certs/`.
