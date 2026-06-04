# Decisiones de arquitectura (proyecto final)

Documento cerrado en **Fase 1**. Cualquier cambio debe actualizarse aquí antes de implementar.

---

## `GET /sensor/{id}/recent` (últimos 10 eventos)

El README pide leer desde DynamoDB. La tabla base solo tiene `device_id` como partition key y **sobrescribe** cada lectura; no guarda historial de eventos.

| Opción | Pros | Contras |
|--------|------|---------|
| A. Sort key `timestamp` en la misma tabla | Alineado con el enunciado | Cambiar esquema, regla IoT y queries |
| B. Tabla `SensorEvents` separada | Hot state intacto en `SensorData` | Más Terraform |
| C. `/recent` desde MongoDB | Reutiliza histórico Lambda | No coincide literalmente con el README |

**Decisión elegida:** **A** — Añadir **sort key** `timestamp` (o `event_id`) en `SensorData-{env}`.

**Implementación prevista:**

- Partition key: `device_id`
- Sort key: `timestamp` (ISO 8601) o `event_id` (UUID por evento)
- `GET /current`: `Query` con `device_id` y `ScanIndexForward=false`, `Limit=1` (último evento)
- `GET /recent`: misma query con `Limit=10`
- Regla IoT DynamoDB: sigue haciendo `PutItem`; cada evento es un ítem distinto (ya no sobrescribe)

**Por qué no el diseño actual:** sin sort key la clave primaria es solo `device_id`; DynamoDB reemplaza el ítem anterior y no puede devolver “últimos 10”.

---

## `POST /sensors` (catálogo)

**Decisión elegida:** colección MongoDB **`sensors`**.

### Qué guarda el catálogo (y qué NO guarda el flujo MQTT)

El flujo IoT (sensor → Mosquitto → IoT → DynamoDB/S3) solo ingiere **telemetría** cuando un `device_id` publica en `lab/sensors/data`. **No** registra metadatos de negocio ni valida que el sensor esté “dado de alta”.

`POST /sensors` persiste el **registro lógico** del dispositivo, por ejemplo:

| Campo (ejemplo) | Propósito |
|-----------------|-----------|
| `device_id` | Clave de correlación con MQTT y DynamoDB |
| `sensor_type` | `temperature`, `humidity`, etc. |
| `display_name` | Nombre para UI o sustentación |
| `location` | Ubicación opcional |
| `registered_at` | Cuándo se registró en la plataforma |
| `active` | Si el sensor está habilitado |

La API puede rechazar o advertir lecturas de sensores no registrados (regla de negocio futura).

---

## MongoDB (hosting)

**Decisión elegida:** **EC2 + Docker** (MongoDB en contenedor en la misma cuenta AWS).

| Parámetro | Valor |
|-----------|--------|
| Instancia | `t3.micro` |
| Autenticación | Sí — usuario/contraseña en MongoDB (`MONGODB_URI` con credenciales) |
| Acceso desde Lambda | Lambda en **VPC** (subnets privadas + security groups) |
| Acceso desde ECS (API) | Misma VPC; SG de EC2 solo permite 27017 desde SG de Lambda y ECS |
| Política de costos | Recursos de cómputo/EC2 solo mientras exista el stack de `make aws-up`; destruir con `make aws-down` / `make clean` |

**Justificación breve:** histórico y catálogo en un document store; control en AWS; coherente con el diagrama S3 → Lambda → MongoDB.

**Alternativa descartada para este proyecto:** Atlas M0 (válida para prototipos, pero se prioriza EC2 en VPC del lab).

---

## Secretos y `MONGODB_URI`

| Entorno | Dónde va `MONGODB_URI` | ¿En Git? |
|---------|------------------------|----------|
| Desarrollo local (API) | Archivo **`.env`** en la raíz del repo | **No** — listado en `.gitignore` |
| Plantilla para el equipo | **`.env.example`** (sin contraseñas reales) | Sí |
| Lambda (AWS) | Variable de entorno en Terraform (`environment { variables }`) o **Secrets Manager** | No |
| ECS (AWS) | Variables de la task definition o secretos de ECS | No |

**Regla:** el archivo `.env` es solo para tu máquina. En la nube, Terraform/ECS/Lambda inyectan la misma variable; nunca commitear `.env` ni pegar la URI en código fuente.

Ejemplo local (`.env.example`):

```bash
MONGODB_URI=mongodb://usuario:password@HOST:27017/iot?authSource=admin
AWS_REGION=us-east-1
```

---

## Por qué el histórico largo va a MongoDB (vía S3 + Lambda), no solo a DynamoDB

| Motivo | Explicación |
|--------|-------------|
| Separación hot / cold | DynamoDB optimizado para **estado actual** y **últimos N** eventos (`/current`, `/recent`); MongoDB para **histórico completo** (`/history`). |
| S3 ya es el archivo de verdad | Cada evento ya se guarda en S3 (regla IoT); Lambda replica ese JSON en MongoDB sin duplicar lógica en el edge. |
| Coste y escala | Guardar todo el histórico en DynamoDB implica un ítem por evento × todos los sensores × tiempo; encarece el lab. S3 + batch/analytics es el patrón del proyecto. |
| Enunciado del README | Hitos 2–3 exigen trigger S3 → Lambda → MongoDB explícitamente. |
| Consultas | `/history` son listados largos por `device_id`; colección documental encaja mejor que escanear tablas enormes en DynamoDB. |

DynamoDB **no se elimina**: sigue alimentado por IoT para tiempo real y recientes; MongoDB se alimenta desde S3 de forma asíncrona.

---

## Repaso de puertas (todas las fases)

Índice completo de preguntas en **[docs/PUERTAS.md](PUERTAS.md)**. Las respuestas aprobadas del equipo se documentan **aquí** para repaso rápido.

---

## Puerta Fase 0 → Fase 1 — Respuestas (aprobada)

1. **Tópico y JSON:** `lab/sensors/data`; campos `device_id`, `sensor_type`, `value`, `timestamp`.
2. **Mosquitto bridge:** concentra sensores en local y reenvía por mTLS a IoT Core.
3. **Certificados:** `AmazonRootCA1.pem`, `certificate.pem.crt`, `private.pem.key`, `public.pem.key`; secreto = `private.pem.key`.
4. **Reglas IoT:** dos en paralelo → DynamoDB (hot) y S3 (cold).
5. **DynamoDB inicial:** solo `device_id` → sobrescritura (un ítem por sensor).
6. **S3:** particiones `year/month/day` para Athena.
7. **Limpieza:** `make clean`.

---

## Puerta Fase 1 → Fase 2 — Respuestas (aprobada)

1. **Últimos 10:** sin sort key no hay N eventos; se eligió sort key `timestamp`.
2. **`POST /sensors` vs MQTT:** catálogo (nombre, ubicación, tipo, alta); MQTT solo telemetría.
3. **Histórico en MongoDB:** separación hot/cold; S3 + Lambda; no llenar DynamoDB con todo el historial.
4. **`MONGODB_URI`:** `.env` local; Terraform/ECS en AWS; nunca en Git.

---

## Puerta Fase 2 → Fase 3 — Respuestas (aprobada)

1. **Disparo Lambda:** `s3:ObjectCreated:*`, prefijo `data/` → colección `sensor_events`.
2. **Lambda en VPC:** MongoDB en EC2 con IP privada; puerto 27017 no expuesto a Internet.
3. **Idempotencia:** índice único `s3_key`; `DuplicateKeyError` si se reintenta el mismo archivo.
4. **DynamoDB:** sort key `timestamp`; cada lectura es un ítem; `Query` + `Limit` para current/recent.

---

## Puerta Fase 3 → Fase 4 — Respuestas (aprobada)

### Preguntas

1. ¿Qué valida Pydantic en `POST /sensors` y qué pasa si `device_id` ya existe?
2. ¿Qué endpoints usan DynamoDB y cuáles MongoDB? ¿Por qué?
3. ¿Dónde se documenta la API para quien no lee el código?
4. ¿Por qué `GET /history` puede fallar en local pero funcionar en ECS?

### Respuestas del equipo (para repaso)

1. **Pydantic** valida el **body**: tipos de datos, longitudes, campos requeridos y rechazo de campos extra (`extra=forbid`). Además se comprueba la **unicidad** de `device_id` en el catálogo; si ya está registrado → **HTTP 409 Conflict** (no se vuelve a insertar).

2. **MongoDB:** `GET/POST /sensors` (catálogo) y `GET /sensor/{id}/history` (histórico por sensor, vía Lambda desde S3). **DynamoDB:** `GET /sensor/{id}/current` y `/recent` (hot data; último evento y últimos N con sort key `timestamp`).

3. **Documentación pública:** **Swagger UI** en la URL de la API + `/docs` (local: `http://127.0.0.1:8000/docs`; en ECS: `http://<IP-o-DNS-del-ALB>/docs`). OpenAPI en `/openapi.json`. El código vive en `api/app/routers/` y `api/app/schemas.py`; no confundir con `api/app/services` (solo lógica interna).

4. **Mongo en VPC privada:** la URI apunta a IP privada del EC2 (`10.42.x.x`). Desde el Mac sin SSM/túnel no hay ruta; `health` puede quedar `degraded`. En **ECS** (misma VPC) sí funciona. Alternativa temporal en lab: regla **SG** que permita tu IP en el puerto 27017.

**Estado:** Fase 3 cerrada para avanzar a **Fase 4** (alertas IoT → Lambda → SQS → CloudWatch).

---

## Fase 4 — Alertas de urgencia

| Parámetro | Valor |
|-----------|--------|
| Umbral | `30` °C (`temperature_alert_threshold`, regla `value > 30`) |
| Regla SQL | `temperature` y `value > umbral` |
| Cola | `iot-edge-alerts-{env}` + DLQ |
| Lambdas | `alert-publisher`, `alert-consumer` |
| Rol | LabRole |

**Flujo:** IoT Rule 3 → publisher → SQS → consumer → log CRITICAL en CloudWatch.

---

## Puerta Fase 1 — Respuestas de comprensión (detalle Fase 1)

Usar esto para sustentación antes de pasar a Fase 2 (Lambda + MongoDB).

1. **¿Por qué el diseño actual no sirve para “últimos 10”?**  
   Solo partition key `device_id`, sin sort key → cada `PutItem` sobrescribe el ítem.

2. **¿Qué guarda `POST /sensors` que MQTT no guarda?**  
   Metadatos de catálogo (registro del sensor en `sensors`), no las lecturas en sí.

3. **¿Por qué histórico en MongoDB vía S3+Lambda?**  
   Ver tabla anterior; cumple arquitectura objetivo y roles hot/cold.

4. **¿Dónde va `MONGODB_URI`?**  
   Local: `.env` (ignorado por Git). AWS: variables de Lambda/ECS vía Terraform o Secrets Manager — **nunca** en el repositorio.

---

## Estado de la puerta Fase 1 → Fase 2

- Pregunta 1: validada por el equipo.
- Preguntas 2–3: documentadas arriba; confirmar que puedes explicarlas sin leer en voz alta.
- Pregunta 4: aceptada con matiz — `.env` solo local; en AWS usar Terraform/ECS.

**Siguiente hito (Fase 2):** módulos `networking` + `compute`, EC2 `t3.micro` con MongoDB autenticado, Lambda S3→Mongo en VPC.
