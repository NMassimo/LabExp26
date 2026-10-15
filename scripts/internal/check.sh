#!/usr/bin/env bash
# Check patches, energy, Python control, GUI and example traffic.
set -euo pipefail
LAB_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
LAB_PYTHON="$LAB_ROOT/.venv/bin/python"
if [[ ! -x "$LAB_PYTHON" || ! -x "$LAB_ROOT/.local/bin/otns" ]]; then
    echo "Run ./scripts/setup.sh first." >&2
    exit 1
fi
LAB_GO_BIN=$("$LAB_PYTHON" "$LAB_ROOT/scripts/internal/ensure-go.py")
export PATH="$LAB_ROOT/.local/bin:$LAB_GO_BIN:$PATH"
"$LAB_PYTHON" "$LAB_ROOT/scripts/internal/apply-patches.py" --check
(
    cd "$LAB_ROOT/otns"
    go test ./energy ./cli ./dispatcher
    OTNS="$LAB_ROOT/.local/bin/otns" "$LAB_PYTHON" -m unittest discover \
        -s pylibs/unittests -p test_energy.py -v
)
"$LAB_PYTHON" "$LAB_ROOT/scripts/internal/check-gui.py"

# Keep generated simulator files outside the source checkout.
(
    mkdir -p "$LAB_ROOT/results/example"
    cd "$LAB_ROOT/results/example"
    OTNS="$LAB_ROOT/.local/bin/otns" "$LAB_PYTHON" "$LAB_ROOT/otns/pylibs/examples/energy_control.py"
)
echo "All course checks completed."
