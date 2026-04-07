#!/usr/bin/env bash
# Build weclaw with Docker and install the binary to a system path.
# Usage:
#   ./scripts/docker-pack.sh
#   DEST=/usr/local/bin/weclaw ./scripts/docker-pack.sh
#   IMAGE=weclaw:local DEST=/usr/bin/weclaw ./scripts/docker-pack.sh

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="${IMAGE:-weclaw:local}"
CONTAINER_PATH="/usr/local/bin/weclaw"
DEST="${DEST:-/usr/bin/weclaw}"

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "error: required command not found: $1" >&2
    exit 1
  }
}

need_cmd docker

echo "==> docker build -t ${IMAGE} ${ROOT}"
docker build -t "${IMAGE}" "${ROOT}"

CID=""
CID="$(docker create "${IMAGE}")"
cleanup() {
  [[ -n "${CID}" ]] && docker rm -f "${CID}" >/dev/null 2>&1 || true
}
trap cleanup EXIT

TMP="$(mktemp)"
docker cp "${CID}:${CONTAINER_PATH}" "${TMP}"
chmod +x "${TMP}"

DEST_DIR="$(dirname "${DEST}")"
if [[ ! -d "${DEST_DIR}" ]]; then
  echo "==> mkdir -p ${DEST_DIR}"
  if [[ -w "$(dirname "${DEST_DIR}")" ]] 2>/dev/null; then
    mkdir -p "${DEST_DIR}"
  else
    sudo mkdir -p "${DEST_DIR}"
  fi
fi

if [[ -w "${DEST_DIR}" ]]; then
  mv -f "${TMP}" "${DEST}"
else
  echo "==> installing to ${DEST} (sudo)"
  sudo mv -f "${TMP}" "${DEST}"
fi

echo "==> installed: ${DEST}"
"${DEST}" version || true
