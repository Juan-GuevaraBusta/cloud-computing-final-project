#!/usr/bin/env bash
# Empaqueta todas las Lambdas del proyecto.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "${ROOT}/s3_to_mongo/build.sh"
bash "${ROOT}/alert_publisher/build.sh"
bash "${ROOT}/alert_consumer/build.sh"
