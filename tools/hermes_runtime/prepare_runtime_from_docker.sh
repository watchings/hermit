#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUTPUT="$ROOT/app/src/main/assets"
WORK="$ROOT/.hermes-docker-runtime"
PYTHON_IMAGE="${PYTHON_IMAGE:-python:3.12-bookworm}"
WEBUI_IMAGE="${WEBUI_IMAGE:-ghcr.io/nesquena/hermes-webui:latest}"
TERMUX_PACKAGES_URL="${TERMUX_PACKAGES_URL:-https://packages.termux.dev/apt/termux-main}"

rm -rf "$WORK" "$OUTPUT/usr" "$OUTPUT/hermes"
mkdir -p "$WORK" "$OUTPUT/usr/var/lib/proot-distro/installed-rootfs/ubuntu"

docker pull --platform=linux/arm64 "$PYTHON_IMAGE"
docker pull --platform=linux/arm64 "$WEBUI_IMAGE"

python_container_id="$(docker run --detach --platform=linux/arm64 \
  --entrypoint /bin/bash "$PYTHON_IMAGE" -lc 'sleep infinity')"
webui_container_id="$(docker create --platform=linux/arm64 "$WEBUI_IMAGE")"
trap 'docker rm --force "$python_container_id" "$webui_container_id" >/dev/null' EXIT

docker export "$python_container_id" | tar -x -C "$OUTPUT/usr/var/lib/proot-distro/installed-rootfs/ubuntu"
termux_index="$WORK/termux-packages.gz"
curl --fail --location --proto '=https' --tlsv1.2 \
  "$TERMUX_PACKAGES_URL/dists/stable/main/binary-aarch64/Packages.gz" \
  -o "$termux_index"
termux_package="$(
  gzip -dc "$termux_index" |
    awk '
      /^Package: proot$/ { found=1 }
      found && /^Filename:/ { print $2; exit }
    '
)"
termux_sha256="$(
  gzip -dc "$termux_index" |
    awk '
      /^Package: proot$/ { found=1 }
      found && /^SHA256:/ { print $2; exit }
    '
)"
test -n "$termux_package"
test "${#termux_sha256}" -eq 64
curl --fail --location --proto '=https' --tlsv1.2 \
  "$TERMUX_PACKAGES_URL/$termux_package" -o "$WORK/proot.deb"
printf '%s  %s\n' "$termux_sha256" "$WORK/proot.deb" | sha256sum --check
mkdir -p "$WORK/termux"
ar p "$WORK/proot.deb" data.tar.xz | tar -xJ -C "$WORK/termux"
install -Dm755 \
  "$WORK/termux/data/data/com.termux/files/usr/bin/proot" \
  "$OUTPUT/usr/bin/proot"
file "$OUTPUT/usr/bin/proot" | grep -Eiq 'aarch64|arm64'

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
    "source": "$TERMUX_PACKAGES_URL/$termux_package",
    "sha256": "$termux_sha256",
    "type": "precompiled-termux-aarch64"
  }
}
EOF
cp "$ROOT/tools/hermes_runtime/LICENSES.txt" "$OUTPUT/hermes/LICENSES.txt"
printf 'Source dependencies are installed in the pulled AArch64 Hermes WebUI image.\n' \
  > "$OUTPUT/hermes/requirements-aarch64.lock"
