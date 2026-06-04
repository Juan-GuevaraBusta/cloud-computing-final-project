# python_device — Simuladores de sensores IoT

## Propósito

Contiene el código que **simula dispositivos IoT** en el entorno local (Docker). Cada contenedor publica lecturas periódicas al broker Mosquitto por MQTT, sin conectarse directamente a AWS.

## Flujo de datos

```
sensor_simulator.py  --MQTT (1883, sin TLS)-->  mosquitto (edge_gateway)
                                                      |
                                                      └── bridge mTLS --> AWS IoT Core
```

## Archivos

| Archivo | Responsabilidad | Estado |
|---------|-----------------|--------|
| `sensor_simulator.py` | Genera JSON de lectura y publica en `lab/sensors/data` | Base (laboratorio) |
| `Dockerfile` | Imagen Python 3.12 Alpine con dependencias MQTT | Base |
| `requirements.txt` | Dependencia `paho-mqtt` para el cliente MQTT | Base |

## Contrato del mensaje (JSON)

Cada publicación usa el tópico **`lab/sensors/data`** y un cuerpo JSON con estos campos:

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `device_id` | string | Identificador único del sensor (ej. `sensor-temp-01`) |
| `sensor_type` | string | Tipo lógico: `temperature`, `humidity`, etc. |
| `value` | number | Magnitud medida (°C, % humedad, etc. según el tipo) |
| `timestamp` | string | Marca de tiempo UTC en formato ISO 8601 |

> **Nota:** No existe un campo llamado `temperature` en el JSON. La temperatura es un **valor posible** de `sensor_type`; la lectura numérica va siempre en `value`.

## Variables de entorno (Docker Compose)

| Variable | Ejemplo | Uso |
|----------|---------|-----|
| `MQTT_HOST` | `mosquitto` | Host del broker local |
| `MQTT_PORT` | `1883` | Puerto MQTT sin TLS en la red Docker |
| `CLIENT_ID` | `sensor-temp-01` | Se usa como `device_id` en el payload |
| `SENSOR_TYPE` | `temperature` | Define rangos de simulación en `generate_sensor_data()` |
| `INTERVAL` | `5` | Segundos entre publicaciones |

## Próximos cambios (proyecto final)

- Añadir un nuevo `SENSOR_TYPE` en `generate_sensor_data()` para la sustentación.
- Nuevo servicio en `docker-compose.yml` con variables propias.
- Registro del sensor vía `POST /sensors` en la API (fase posterior).

## Comandos útiles

```bash
# Desde la raíz del repo, levanta todos los sensores y el gateway
make local-up
make logs
```
