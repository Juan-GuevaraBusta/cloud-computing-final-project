# Imagen mínima para ejecutar sensor_simulator.py en Docker Compose.
# Una instancia del contenedor = un sensor simulado (CLIENT_ID y SENSOR_TYPE por env).

FROM python:3.12-alpine

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY sensor_simulator.py .

# -u: logs sin buffer para ver publicaciones en tiempo real con make logs
CMD ["python", "-u", "sensor_simulator.py"]
