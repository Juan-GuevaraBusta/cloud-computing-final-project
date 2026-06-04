#!/bin/bash
# Bootstrap EC2: instala Docker y levanta MongoDB 7 con usuario administrador.
set -eux
exec > /var/log/mongodb-bootstrap.log 2>&1

dnf install -y docker
systemctl enable docker
systemctl start docker

docker pull mongo:7

docker run -d \
  --name mongodb \
  --restart unless-stopped \
  -p 27017:27017 \
  -e MONGO_INITDB_ROOT_USERNAME="${mongodb_username}" \
  -e MONGO_INITDB_ROOT_PASSWORD="${mongodb_password}" \
  -e MONGO_INITDB_DATABASE="${mongodb_database}" \
  mongo:7

echo "MongoDB listo en puerto 27017"
