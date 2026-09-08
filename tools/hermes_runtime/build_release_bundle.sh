#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORK="$ROOT/.hermes-runtime-build"
IMAGE="hermes-runtime:build"
ASSET="$WORK/hermes-runtime-aarch64.tar.gz"

rm -rf "$WORK" "$ROOT/release-cache"
mkdir -p "$WORK/rootfs/ubuntu-aarch64" "$WORK/proot/bin" "$ROOT/release-cache"
container_id="$(docker create "$IMAGE")"
trap 'docker rm "$container_id" >/dev/null' EXIT

docker export "$container_id" | tar -x -C "$WORK/rootfs/ubuntu-aarch64"
install -Dm755 "$WORK/rootfs/ubuntu-aarch64/usr/bin/proot" "$WORK/proot/bin/proot"
mkdir -p "$WORK/hermes"
cp -a "$WORK/rootfs/ubuntu-aarch64/opt/hermes-agent" "$WORK/hermes/agent"
cp -a "$WORK/rootfs/ubuntu-aarch64/opt/hermes-webui" "$WORK/hermes/webui"
cp -a "$WORK/rootfs/ubuntu-aarch64/opt/hermes-python" "$WORK/hermes/python"
cp "$ROOT/tools/hermes_runtime/requirements-aarch64.lock" "$WORK/requirements-aarch64.lock"
cp "$ROOT/tools/hermes_runtime/LICENSES.txt" "$WORK/LICENSES.txt"

HERMES_AGENT_REVISION="${HERMES_AGENT_REVISION:?HERMES_AGENT_REVISION is required}"
HERMES_WEBUI_REVISION="${HERMES_WEBUI_REVISION:?HERMES_WEBUI_REVISION is required}"
export HERMES_AGENT_REVISION HERMES_WEBUI_REVISION WORK
python3 - <<'PY'
import hashlib
import json
import os
from pathlib import Path

work = Path(os.environ["WORK"])

def digest(path: Path) -> str:
    if path.is_file():
        h = hashlib.sha256()
        with path.open("rb") as stream:
            for chunk in iter(lambda: stream.read(1024 * 1024), b""):
                h.update(chunk)
        return h.hexdigest()
    h = hashlib.sha256()
    for child in sorted(p for p in path.rglob("*") if p.is_file()):
        h.update(str(child.relative_to(path)).encode())
        h.update(digest(child).encode())
    return h.hexdigest()

artifacts = [
    ("proot", "proot/bin/proot", "usr/bin/proot", "file"),
    ("ubuntu-aarch64-rootfs", "rootfs/ubuntu-aarch64", "usr/var/lib/proot-distro/installed-rootfs/ubuntu", "directory"),
    ("hermes-agent", "hermes/agent", "usr/var/lib/proot-distro/installed-rootfs/ubuntu/opt/hermes-agent", "directory"),
    ("hermes-webui", "hermes/webui", "usr/var/lib/proot-distro/installed-rootfs/ubuntu/opt/hermes-webui", "directory"),
    ("python-dependencies", "hermes/python", "usr/var/lib/proot-distro/installed-rootfs/ubuntu/opt/hermes-python", "directory"),
]
artifact_records = [
    {"name": name, "source": source, "target": target, "kind": kind, "sha256": digest(work / source)}
    for name, source, target, kind in artifacts
]
manifest = {
    "schemaVersion": 1,
    "runtime": "hermes-agent",
    "provisioningStatus": "built-by-docker-qemu",
    "target": {"os": "linux", "architecture": "aarch64", "userspace": "ubuntu", "launcher": "proot"},
    "artifacts": artifact_records,
    "dependencyLocks": {
        "cpython": {
            "version": (work / "hermes/python/python-version").read_text(encoding="utf-8").strip(),
            "source": "docker.io/library/python:3.12-bookworm",
            "sha256": digest(work / "rootfs/ubuntu-aarch64/usr/local/bin/python3"),
        },
        "proot": {
            "version": "distribution-package",
            "source": "debian:bookworm",
            "revision": "apt-installed-in-runtime-image",
            "sha256": digest(work / "proot/bin/proot"),
        },
        "hermesAgent": {
            "source": "https://github.com/NousResearch/hermes-agent",
            "revision": os.environ["HERMES_AGENT_REVISION"],
            "sha256": digest(work / "hermes/agent"),
        },
        "hermesWebui": {
            "source": "https://github.com/nesquena/hermes-webui",
            "revision": os.environ["HERMES_WEBUI_REVISION"],
            "sha256": digest(work / "hermes/webui"),
        },
    },
}
(work / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
PY

tar -C "$WORK" -czf "$ASSET" manifest.json requirements-aarch64.lock LICENSES.txt \
  proot rootfs hermes
sha256sum "$ASSET" > "$ASSET.sha256"
cp "$ASSET" "$ROOT/release-cache/"
cp "$ASSET.sha256" "$ROOT/release-cache/"
cp "$WORK/manifest.json" "$ROOT/release-cache/"
cp "$WORK/requirements-aarch64.lock" "$ROOT/release-cache/"
cp "$WORK/LICENSES.txt" "$ROOT/release-cache/"
