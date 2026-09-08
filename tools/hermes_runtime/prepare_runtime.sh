#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CACHE="${HERMES_RUNTIME_CACHE:?HERMES_RUNTIME_CACHE must point to a provisioned offline cache}"
MANIFEST="${HERMES_RUNTIME_MANIFEST:-$ROOT/tools/hermes_runtime/manifest.json}"
REQUIREMENTS="${HERMES_RUNTIME_REQUIREMENTS:-$ROOT/tools/hermes_runtime/requirements-aarch64.lock}"
LICENSES="${HERMES_RUNTIME_LICENSES:-$ROOT/tools/hermes_runtime/LICENSES.txt}"

exec python3 "$ROOT/tools/hermes_runtime/prepare_runtime.py" \
  --input "$CACHE" \
  --output "$ROOT/app/src/main/assets" \
  --manifest "$MANIFEST" \
  --requirements "$REQUIREMENTS" \
  --licenses "$LICENSES"
