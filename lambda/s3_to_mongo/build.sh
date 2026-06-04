#!/usr/bin/env bash
# Empaqueta handler.py + dependencias para AWS Lambda (linux x86_64 compatible).
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${DIR}/build"
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"
# Paquetes compatibles con Lambda Python 3.12 (Amazon Linux x86_64).
python3 -m pip install -r "${DIR}/requirements.txt" -t "${BUILD_DIR}" --quiet --upgrade \
  --platform manylinux2014_x86_64 \
  --implementation cp \
  --python-version 3.12 \
  --only-binary=:all:
cp "${DIR}/handler.py" "${BUILD_DIR}/"
