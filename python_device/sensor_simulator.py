"""
Simulador de sensor IoT para el laboratorio base.

Publica lecturas JSON al tópico MQTT lab/sensors/data en el broker local (Mosquitto).
No se conecta a AWS; el edge gateway reenvía los mensajes a IoT Core.

Payload: device_id, sensor_type, value, timestamp (ver README.md de esta carpeta).
"""

import os
import time
import json
from datetime import datetime, timezone
import random
import paho.mqtt.client as mqtt

# --- Configuración desde variables de entorno (inyectadas por docker-compose) ---
MQTT_HOST = os.environ.get("MQTT_HOST", "localhost")
MQTT_PORT = int(os.environ.get("MQTT_PORT", 1883))
CLIENT_ID = os.environ.get("CLIENT_ID", f"sensor-{random.randint(1000,9999)}")
SENSOR_TYPE = os.environ.get("SENSOR_TYPE", "temperature")  # temperature, humidity, etc.
INTERVAL = int(os.environ.get("INTERVAL", 5))

# Tópico compartido por todos los sensores; el bridge lo replica en AWS con el mismo nombre
TOPIC = "lab/sensors/data"


def on_connect(client, userdata, flags, rc):
    """
    Callback de paho-mqtt al establecer conexión con el broker.

    rc == 0 indica éxito; cualquier otro código se registra como error de conexión.
    """
    if rc == 0:
        print(f"[{CLIENT_ID}] Conectado exitosamente al broker local MQTT en {MQTT_HOST}:{MQTT_PORT}")
    else:
        print(f"[{CLIENT_ID}] Error al conectar. Código: {rc}")


def generate_sensor_data():
    """
    Construye el payload JSON de una lectura simulada.

    El rango de value depende de SENSOR_TYPE. El device_id coincide con CLIENT_ID
    para que DynamoDB y la API puedan correlacionar por sensor.

    Returns:
        dict: device_id, sensor_type, value, timestamp (ISO 8601 UTC).
    """
    value = 0.0
    if SENSOR_TYPE == "temperature":
        value = round(random.uniform(20.0, 35.0), 2)
    elif SENSOR_TYPE == "humidity":
        value = round(random.uniform(40.0, 60.0), 2)
    elif SENSOR_TYPE == "pressure":
        value = round(random.uniform(980.0, 1020.0), 2)
    else:
        # Tipos futuros (proyecto final): rango genérico hasta definir reglas por tipo
        value = round(random.uniform(0.0, 100.0), 2)

    return {
        "device_id": CLIENT_ID,
        "sensor_type": SENSOR_TYPE,
        "value": value,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }


def main():
    """
    Punto de entrada: conecta al broker, publica en bucle cada INTERVAL segundos.

    Usa QoS 1 para que Mosquitto confirme recepción antes de seguir.
    Reintenta la conexión si el broker aún no está listo (orden de arranque Docker).
    """
    print(f"[{CLIENT_ID}] Iniciando sensor tipo '{SENSOR_TYPE}'...")

    client = mqtt.Client(client_id=CLIENT_ID)
    client.on_connect = on_connect

    # Red Docker interna: sin TLS; la seguridad hacia AWS la aplica el bridge en Mosquitto
    while True:
        try:
            client.connect(MQTT_HOST, MQTT_PORT, 60)
            break
        except Exception as e:
            print(f"[{CLIENT_ID}] Esperando al broker MQTT {MQTT_HOST}:{MQTT_PORT}... Error: {e}")
            time.sleep(2)

    client.loop_start()

    try:
        while True:
            payload = generate_sensor_data()
            print(f"[{CLIENT_ID}] Publicando: {payload}")

            client.publish(TOPIC, json.dumps(payload), qos=1)
            time.sleep(INTERVAL)

    except KeyboardInterrupt:
        print(f"\n[{CLIENT_ID}] Deteniendo sensor...")
    finally:
        client.loop_stop()
        client.disconnect()
        print(f"[{CLIENT_ID}] Desconectado.")


if __name__ == "__main__":
    main()
