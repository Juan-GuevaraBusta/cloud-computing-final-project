# edge_gateway — Broker MQTT y puente hacia AWS IoT Core

## Propósito

Aloja **Eclipse Mosquitto** como **Edge Gateway**: recibe mensajes MQTT de los sensores en la red local y los reenvía a **AWS IoT Core** mediante un **bridge** cifrado con **mTLS** (puerto 8883).

Los sensores no necesitan certificados AWS; solo el gateway se autentica en la nube.

## Flujo de datos

```
Sensores  --TCP 1883-->  Mosquitto (listener local)
                              |
                              └── bridge TLS 8883 -->  AWS IoT Core (tópico lab/sensors/data)
```

## Archivos

| Archivo | Responsabilidad | Estado |
|---------|-----------------|--------|
| `Dockerfile` | Copia `mosquitto.conf` y certificados al contenedor oficial `eclipse-mosquitto:2.0` | Base |
| `mosquitto.conf` | Configuración del broker y del bridge (generado por Terraform en `make aws-up`) | Generado (no versionar si contiene endpoint) |
| `certs/AmazonRootCA1.pem` | Certificado raíz de Amazon; valida que el servidor remoto es AWS | Generado por Terraform |
| `certs/certificate.pem.crt` | Certificado de cliente X.509 (identidad del gateway ante IoT Core) | Generado por Terraform |
| `certs/private.pem.key` | Clave privada del dispositivo; firma la conexión mTLS | Generado por Terraform — **secreto** |
| `certs/public.pem.key` | Clave pública asociada al certificado | Generado por Terraform |

## Certificados: qué es cada uno

| Archivo | Rol | ¿Subir a Git? |
|---------|-----|----------------|
| `AmazonRootCA1.pem` | Confía en el servidor de AWS (anti Man-in-the-Middle) | No (se regenera con Terraform) |
| `certificate.pem.crt` | “Pasaporte” del gateway (identidad + clave pública firmada por AWS) | No |
| `private.pem.key` | Secreto criptográfico del gateway | **Nunca** |
| `public.pem.key` | Par público del certificado; verificación local | No |

La carpeta `certs/` se limpia con `make clean`.

## Configuración del bridge (resumen)

Tras `make aws-up`, Terraform escribe `mosquitto.conf` con:

- Listener local `1883` (red Docker, sin TLS).
- Conexión `awsiot` al endpoint ATS de IoT Core en el puerto `8883`.
- Reenvío del tópico `lab/sensors/data` hacia la nube.
- Rutas a los PEM dentro del contenedor (`/mosquitto/certs/...`).

## Próximos cambios (proyecto final)

- Sin cambios estructurales previstos en el gateway; nuevos sensores solo publican al mismo tópico local.
- Mantener política IoT en AWS alineada con `lab/sensors/*`.

## Comandos útiles

```bash
make aws-up    # Genera certs + mosquitto.conf
make local-up  # Construye imagen con certs embebidos
make clean     # Destruye AWS y borra certs locales
```
