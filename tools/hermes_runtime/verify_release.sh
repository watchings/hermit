#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CACHE="${HERMES_RUNTIME_CACHE:?HERMES_RUNTIME_CACHE must point to the extracted release cache}"
MANIFEST="${HERMES_RUNTIME_MANIFEST:-$CACHE/manifest.json}"
REQUIREMENTS="${HERMES_RUNTIME_REQUIREMENTS:-$CACHE/requirements-aarch64.lock}"
LICENSES="${HERMES_RUNTIME_LICENSES:-$CACHE/LICENSES.txt}"

test -f "$MANIFEST"
test -f "$REQUIREMENTS"
test -f "$LICENSES"
python3 "$ROOT/tools/hermes_runtime/prepare_runtime.py" \
  --input "$CACHE" \
  --output "$ROOT/.hermes-runtime-verify" \
  --manifest "$MANIFEST" \
  --requirements "$REQUIREMENTS" \
  --licenses "$LICENSES"
rm -rf "$ROOT/.hermes-runtime-verify"
