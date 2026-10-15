#!/usr/bin/env bash
# Launch the full simulator and its browser GUI with the local installation.
set -euo pipefail
LAB_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
if [[ ! -x "$LAB_ROOT/.local/bin/otns" || ! -x "$LAB_ROOT/.local/bin/grpcwebproxy" ]]; then
    echo "Run ./scripts/setup.sh first." >&2
    exit 1
fi
export PATH="$LAB_ROOT/.local/bin:$LAB_ROOT/.venv/bin:$PATH"
cd "$LAB_ROOT/otns"
exec "$LAB_ROOT/.local/bin/otns" "$@"
