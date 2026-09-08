#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUTPUT="$ROOT/app/src/main/assets"
WORK="$ROOT/.hermes-docker-runtime"
PYTHON_IMAGE="${PYTHON_IMAGE:-python:3.12-bookworm}"
WEBUI_IMAGE="${WEBUI_IMAGE:-ghcr.io/nesquena/hermes-webui:latest}"

rm -rf "$WORK" "$OUTPUT/usr" "$OUTPUT/hermes"
mkdir -p "$WORK" "$OUTPUT/usr/var/lib/proot-distro/installed-rootfs/ubuntu"

docker pull --platform=linux/arm64 "$PYTHON_IMAGE"
docker pull --platform=linux/arm64 "$WEBUI_IMAGE"

container_id="$(docker run --detach --platform=linux/arm64 \
  --entrypoint /bin/bash "$WEBUI_IMAGE" -lc \
  'apt-get update && apt-get install --no-install-recommends -y proot && rm -rf /var/lib/apt/lists/* && sleep infinity')"
trap 'docker rm --force "$container_id" >/dev/null' EXIT

docker export "$container_id" | tar -x -C "$OUTPUT/usr/var/lib/proot-distro/installed-rootfs/ubuntu"
install -Dm755 \
  "$OUTPUT/usr/var/lib/proot-distro/installed-rootfs/ubuntu/usr/bin/proot" \
  "$OUTPUT/usr/bin/proot"

mkdir -p "$OUTPUT/hermes"
cp -a "$OUTPUT/usr/var/lib/proot-distro/installed-rootfs/ubuntu/apptoo" \
  "$OUTPUT/hermes/webui"
docker image inspect "$PYTHON_IMAGE" --format '{{.Id}}' > "$OUTPUT/hermes/python-image-id"
docker image inspect "$WEBUI_IMAGE" --format '{{.Id}}' > "$OUTPUT/hermes/webui-image-id"
cat > "$OUTPUT/hermes/runtime.json" <<EOF
{
  "schemaVersion": 1,
  "runtime": "hermes-webui",
  "provisioningStatus": "docker-pull",
  "target": {
    "os": "linux",
    "architecture": "aarch64",
    "userspace": "ubuntu",
    "launcher": "proot"
  },
  "images": {
    "python": "$PYTHON_IMAGE",
    "webui": "$WEBUI_IMAGE"
  }
}
EOF
cp "$ROOT/tools/hermes_runtime/LICENSES.txt" "$OUTPUT/hermes/LICENSES.txt"
printf 'Source dependencies are installed in the pulled AArch64 Hermes WebUI image.\n' \
  > "$OUTPUT/hermes/requirements-aarch64.lock"
