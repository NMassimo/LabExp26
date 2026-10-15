#!/usr/bin/env bash
# Keep generated simulator files outside the source checkout.
set -euo pipefail
LAB_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
if [[ ! -x "$LAB_ROOT/.venv/bin/python" || ! -x "$LAB_ROOT/.local/bin/otns" ]]; then
    echo "Run ./scripts/setup.sh first." >&2
    exit 1
fi
mkdir -p "$LAB_ROOT/results/example"
cd "$LAB_ROOT/results/example"
export OTNS="$LAB_ROOT/.local/bin/otns"
exec "$LAB_ROOT/.venv/bin/python" "$LAB_ROOT/otns/pylibs/examples/energy_control.py"
