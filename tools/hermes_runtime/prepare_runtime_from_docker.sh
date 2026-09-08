#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUTPUT="$ROOT/app/src/main/assets"
WORK="$ROOT/.hermes-docker-runtime"
PYTHON_IMAGE="${PYTHON_IMAGE:-python:3.12-bookworm}"
WEBUI_IMAGE="${WEBUI_IMAGE:-ghcr.io/nesquena/hermes-webui:latest}"
PROOT_PACKAGE_URL="${PROOT_PACKAGE_URL:-https://dl-cdn.alpinelinux.org/alpine/edge/community/aarch64/proot-static-5.4.0-r2.apk}"

rm -rf "$WORK" "$OUTPUT/usr" "$OUTPUT/hermes"
mkdir -p "$WORK" "$OUTPUT/usr/var/lib/proot-distro/installed-rootfs/ubuntu"

docker pull --platform=linux/arm64 "$PYTHON_IMAGE"
docker pull --platform=linux/arm64 "$WEBUI_IMAGE"

python_container_id="$(docker run --detach --platform=linux/arm64 \
  --entrypoint /bin/bash "$PYTHON_IMAGE" -lc 'sleep infinity')"
webui_container_id="$(docker create --platform=linux/arm64 "$WEBUI_IMAGE")"
trap 'docker rm --force "$python_container_id" "$webui_container_id" >/dev/null' EXIT

docker export "$python_container_id" | tar -x -C "$OUTPUT/usr/var/lib/proot-distro/installed-rootfs/ubuntu"
curl --fail --location --proto '=https' --tlsv1.2 \
  "$PROOT_PACKAGE_URL" -o "$WORK/proot-static.apk"
mkdir -p "$WORK/alpine"
tar -xzf "$WORK/proot-static.apk" -C "$WORK/alpine"
install -Dm755 \
  "$WORK/alpine/usr/bin/proot.static" \
  "$OUTPUT/usr/bin/proot"
file "$OUTPUT/usr/bin/proot" | grep -Eiq 'aarch64|arm64'
file "$OUTPUT/usr/bin/proot" | grep -Eiq 'static'

mkdir -p "$OUTPUT/hermes"
mkdir -p "$WORK/webui"
docker export "$webui_container_id" | tar -x -C "$WORK/webui"
cp -a "$WORK/webui/apptoo" "$OUTPUT/hermes/webui"
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
  },
  "proot": {
    "source": "$PROOT_PACKAGE_URL",
    "type": "precompiled-static-alpine-aarch64"
  }
}
EOF
cp "$ROOT/tools/hermes_runtime/LICENSES.txt" "$OUTPUT/hermes/LICENSES.txt"
printf 'Source dependencies are installed in the pulled AArch64 Hermes WebUI image.\n' \
  > "$OUTPUT/hermes/requirements-aarch64.lock"
