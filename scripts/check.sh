#!/usr/bin/env bash
# Check the energy implementation and its Python interface.
set -euo pipefail
LAB_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
LAB_PYTHON="$LAB_ROOT/.venv/bin/python"
if [[ ! -x "$LAB_PYTHON" || ! -x "$LAB_ROOT/.local/bin/otns" ]]; then
    echo "Run ./scripts/setup.sh first." >&2
    exit 1
fi
LAB_GO_BIN=$("$LAB_PYTHON" "$LAB_ROOT/scripts/ensure-go.py")
export PATH="$LAB_ROOT/.local/bin:$LAB_GO_BIN:$PATH"
"$LAB_PYTHON" "$LAB_ROOT/scripts/apply-patches.py" --check
(
    cd "$LAB_ROOT/otns"
    go test ./energy ./cli ./dispatcher
    OTNS="$LAB_ROOT/.local/bin/otns" "$LAB_PYTHON" -m unittest discover \
        -s pylibs/unittests -p test_energy.py -v
)
"$LAB_PYTHON" "$LAB_ROOT/scripts/check-gui.py"
