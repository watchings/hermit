#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CACHE="${HERMES_RUNTIME_CACHE:?HERMES_RUNTIME_CACHE must point to a provisioned offline cache}"

exec python3 "$ROOT/tools/hermes_runtime/prepare_runtime.py" \
  --input "$CACHE" \
  --output "$ROOT/app/src/main/assets"
