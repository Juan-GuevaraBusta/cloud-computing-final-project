# Puertas de conocimiento (repaso para sustentación)

Antes de pasar de fase, debes poder responder estas preguntas **sin leer apuntes**. Las respuestas modelo están al final de cada sección.

Enlaces: [Fases del proyecto](FASES.md) · [Decisiones de arquitectura](DECISIONES.md)

---

## Fase 0 → Fase 1 (Laboratorio base)

### Preguntas

1. ¿Qué tópico MQTT publican los sensores y qué campos trae el JSON?
2. ¿Por qué Mosquitto es un *bridge* y no el sensor conectado directo a AWS?
3. ¿Cuáles son los cuatro archivos en `edge_gateway/certs/` y cuál es secreto?
4. Cuando llega un mensaje a IoT Core, ¿cuántas reglas se ejecutan y hacia dónde va cada una?
5. ¿Por qué DynamoDB (diseño inicial solo `device_id`) no guarda historial completo?
6. ¿Cómo se organizan las rutas de los archivos en S3 y para qué sirve?
7. ¿Qué comando destruye AWS y limpia certificados locales?

### Respuestas modelo

1. Tópico `lab/sensors/data`. Campos: `device_id`, `sensor_type`, **`value`**, `timestamp` (no existe campo `temperature`; la temperatura es un tipo y el número va en `value`).
2. Mosquitto concentra sensores en la red local y reenvía por **mTLS** a IoT Core; los sensores no llevan certificados AWS.
3. `AmazonRootCA1.pem`, `certificate.pem.crt`, `private.pem.key`, `public.pem.key`. Secreto: **`private.pem.key`** (firma la conexión mTLS del gateway).
4. Dos reglas en paralelo: **DynamoDB** (hot) y **S3** (cold/histórico archivado).
5. Solo partition key `device_id` → cada evento **sobrescribe** el ítem (device shadow / último valor).
6. Particiones `data/year=.../month=.../day=.../` para consultas analíticas (Athena).
7. `make clean`.

---

## Fase 1 → Fase 2 (Decisiones)

### Preguntas

1. ¿Por qué el diseño DynamoDB solo con `device_id` no sirve para “últimos 10 eventos”?
2. ¿Qué guarda `POST /sensors` que el flujo MQTT no guarda automáticamente?
3. ¿Por qué el histórico largo va a MongoDB vía S3+Lambda y no solo a DynamoDB?
4. ¿Dónde va `MONGODB_URI` y por qué no en Git?

### Respuestas modelo

1. Sin sort key, la clave es solo `device_id` y cada `PutItem` reemplaza el anterior; no hay N eventos por sensor.
2. **Catálogo** en MongoDB (`sensors`): metadatos (nombre, ubicación, tipo, alta, activo). MQTT solo ingiere **telemetría**.
3. Separación hot/cold; S3 ya archiva todo; DynamoDB para actual/recientes; MongoDB para histórico completo (`/history`); coste y enunciado del proyecto.
4. Local: archivo **`.env`** (en `.gitignore`). AWS: variables en Lambda/ECS vía Terraform o Secrets Manager.

---

## Fase 2 → Fase 3 (S3 → Lambda → MongoDB)

### Preguntas

1. ¿Qué dispara la Lambda `s3_to_mongo` y en qué prefijo del bucket?
2. ¿Por qué la Lambda está en VPC?
3. ¿Dónde se guarda el histórico y cómo se evita duplicar el mismo archivo S3?
4. ¿Qué cambió en `SensorData-lab` respecto al lab base?

### Respuestas modelo

1. Evento **`s3:ObjectCreated:*`** en el bucket de sensores, prefijo **`data/`**. Lee el JSON y lo inserta en MongoDB colección **`sensor_events`**.
2. MongoDB corre en EC2 con IP **privada**; puerto **27017** no expuesto a Internet; la Lambda debe estar en la **misma VPC** para conectarse.
3. Base MongoDB **`iot`**, colección **`sensor_events`**. Idempotencia con índice único **`s3_key`**; reintento → `DuplicateKeyError` → se ignora. El `timestamp` del sensor identifica la **lectura**, no el archivo S3.
4. Se añadió sort key **`timestamp`**: cada lectura es un ítem nuevo; **`GET /current`** y **`GET /recent`** usan `Query` + `Limit` (y orden descendente).

---

## Fase 3 → Fase 4 (API FastAPI) — pendiente al terminar Fase 3

### Preguntas (completar al cerrar la API)

1. ¿Qué valida Pydantic en `POST /sensors` y qué error devuelve si el `device_id` ya existe?
2. ¿Qué endpoint usa DynamoDB y cuál MongoDB? ¿Por qué?
3. ¿Dónde se documentan los endpoints para quien consume la API sin leer el código?
4. ¿Por qué `GET /history` puede fallar en local pero funcionar en ECS?

### Respuestas modelo (guía)

1. Tipos, longitudes, campos requeridos; rechazo de campos extra (`model_config` extra=forbid). Duplicado → **409 Conflict**.
2. `/current` y `/recent` → DynamoDB (hot/recientes). `/history`, `/sensors` → MongoDB (catálogo e histórico S3).
3. **Swagger UI** en `/docs` y OpenAPI en `/openapi.json` (FastAPI automático).
4. MongoDB en IP privada de VPC; local requiere túnel/VPN; ECS en la misma VPC sí alcanza el EC2.

**Respuestas aprobadas del equipo:** ver [DECISIONES.md — Puerta Fase 3 → Fase 4](DECISIONES.md#puerta-fase-3--fase-4--respuestas-aprobada).

---

## Fase 4 → Fase 5 (ECS) — pendiente

### Preguntas

1. ¿Qué condición SQL usa la regla 3 y qué dispara?
2. ¿Por qué hay SQS entre las dos Lambdas?
3. ¿Dónde se ve la alerta final de urgencia?
4. ¿Qué umbral de temperatura usamos y dónde se configura?

### Respuestas modelo

1. `sensor_type = 'temperature' AND value > umbral` en `lab/sensors/data` → Lambda publicadora.
2. Desacoplar y reintentos; la regla IoT no espera el log en CloudWatch.
3. CloudWatch Logs del **alert_consumer** (`URGENCIA IoT`).
4. Default **30°C** en `terraform/variables.tf` → `temperature_alert_threshold` (SQL: `value > 30`).

---

## Cómo repasar

1. Lee solo las **preguntas** de la fase.
2. Responde en voz alta o por escrito.
3. Compara con **respuestas modelo**.
4. Si fallas más de una, vuelve al README de la carpeta técnica relacionada (`python_device`, `terraform`, `lambda`, `api`).
