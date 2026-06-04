# Broker Mosquitto con bridge mTLS hacia AWS IoT Core.
# Requiere mosquitto.conf y certs/ generados por: make aws-up (Terraform).

FROM eclipse-mosquitto:2.0
COPY mosquitto.conf /mosquitto/config/mosquitto.conf
COPY certs /mosquitto/certs
