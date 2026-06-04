#!/usr/bin/env bash
# Empaqueta alert_publisher (solo handler; boto3 viene en el runtime de Lambda).
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${DIR}/build"
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"
cp "${DIR}/handler.py" "${BUILD_DIR}/"
