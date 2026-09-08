#!/system/bin/sh
set -eu

IMAGE="${HERMIT_HERMES_IMAGE:-nesquena/hermes-webui}"
TAG="${HERMIT_HERMES_TAG:-latest}"
REGISTRY="https://ghcr.io"
RUNTIME_DIR="${1:?usage: download_runtime.sh <runtime-directory>}"
ROOTFS="$RUNTIME_DIR/usr/var/lib/proot-distro/installed-rootfs/ubuntu"
WORK="$RUNTIME_DIR/.hermes-runtime-download"
STAGE_ROOTFS="$WORK/rootfs"
TOKEN_FILE="$WORK/token"
MANIFEST_FILE="$WORK/manifest.json"
LAYERS_FILE="$WORK/layers"
PROOT_URL="${HERMIT_PROOT_URL:-https://dl-cdn.alpinelinux.org/alpine/edge/community/aarch64/proot-static-5.4.0-r2.apk}"

command -v curl >/dev/null 2>&1 || {
  echo "Hermit runtime setup requires curl" >&2
  exit 1
}
command -v jq >/dev/null 2>&1 || {
  echo "Hermit runtime setup requires jq" >&2
  exit 1
}
command -v tar >/dev/null 2>&1 || {
  echo "Hermit runtime setup requires tar" >&2
  exit 1
}

rm -rf "$WORK" "$ROOTFS"
mkdir -p "$STAGE_ROOTFS"

echo "[1/4] Requesting GHCR access token for $IMAGE:$TAG"
curl --fail --silent --show-error --location \
  "$REGISTRY/token?scope=repository:$IMAGE:pull&service=ghcr.io" |
  jq -er '.token' > "$TOKEN_FILE"
token="$(cat "$TOKEN_FILE")"
auth_header="Authorization: Bear""er $token"

echo "[2/4] Resolving the linux/arm64 image manifest"
curl --fail --silent --show-error --location \
  -H "$auth_header" \
  -H 'Accept: application/vnd.oci.image.index.v1+json, application/vnd.docker.distribution.manifest.list.v2+json, application/vnd.oci.image.manifest.v1+json, application/vnd.docker.distribution.manifest.v2+json' \
  "$REGISTRY/v2/$IMAGE/manifests/$TAG" > "$WORK/index.json"

if jq -e 'has("manifests")' "$WORK/index.json" >/dev/null; then
  IMAGE_DIGEST="$(jq -er '
    .manifests[]
    | select(.platform.os == "linux" and .platform.architecture == "arm64")
    | .digest
  ' "$WORK/index.json" | head -n 1)"
  curl --fail --silent --show-error --location \
    -H "$auth_header" \
    -H 'Accept: application/vnd.oci.image.manifest.v1+json, application/vnd.docker.distribution.manifest.v2+json' \
    "$REGISTRY/v2/$IMAGE/manifests/$IMAGE_DIGEST" > "$MANIFEST_FILE"
else
  IMAGE_DIGEST="$(sha256sum "$WORK/index.json" | cut -d ' ' -f 1)"
  cp "$WORK/index.json" "$MANIFEST_FILE"
fi
jq -er '.layers[].digest' "$MANIFEST_FILE" > "$LAYERS_FILE"

layer_count="$(wc -l < "$LAYERS_FILE" | tr -d ' ')"
layer_number=0
while IFS= read -r digest; do
  layer_number=$((layer_number + 1))
  blob="$WORK/${digest#sha256:}.tar"
  echo "[3/4] Downloading layer $layer_number/$layer_count (${digest#sha256:})"
  curl --fail --location --progress-bar \
    -H "$auth_header" \
    "$REGISTRY/v2/$IMAGE/blobs/$digest" -o "$blob"
  tar -tf "$blob" |
    while IFS= read -r entry; do
      case "$entry" in
        */.wh..wh..opq)
          rm -rf "$STAGE_ROOTFS/${entry%/.wh..wh..opq}" ;;
        */.wh.*)
          rm -f "$STAGE_ROOTFS/${entry%/*}/${entry##*/.wh.}" ;;
      esac
    done
  tar -xf "$blob" --no-same-owner --no-same-permissions -C "$STAGE_ROOTFS"
done < "$LAYERS_FILE"

echo "[4/4] Downloading static AArch64 PRoot"
curl --fail --location --progress-bar "$PROOT_URL" -o "$WORK/proot.apk"
mkdir -p "$WORK/proot"
tar -xzf "$WORK/proot.apk" -C "$WORK/proot"
mkdir -p "$RUNTIME_DIR/usr/bin" "$RUNTIME_DIR/hermes"
mkdir -p "$(dirname "$ROOTFS")"
mv "$STAGE_ROOTFS" "$ROOTFS"
cp "$WORK/proot/usr/bin/proot.static" "$RUNTIME_DIR/usr/bin/proot"
chmod 755 "$RUNTIME_DIR/usr/bin/proot"

printf '%s\n' "$IMAGE:$TAG" > "$RUNTIME_DIR/hermes/image"
printf '%s\n' "$IMAGE_DIGEST" > "$RUNTIME_DIR/hermes/image-digest"
rm -rf "$WORK"
echo "Hermit Hermes runtime is ready at $RUNTIME_DIR"
