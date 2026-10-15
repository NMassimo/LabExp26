#!/usr/bin/env bash
# Build the pinned simulator and Thread 1.4 nodes into this checkout.
set -euo pipefail
LAB_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
LAB_PYTHON=${LAB_PYTHON:-python3}
for tool in git go cmake ninja c++; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "Missing prerequisite: $tool. See README.md." >&2
        exit 1
    fi
done
"$LAB_PYTHON" -c 'import sys; assert sys.version_info >= (3, 10), "Python 3.10+ required"'
git -C "$LAB_ROOT" submodule update --init --recursive -- otns
"$LAB_PYTHON" "$LAB_ROOT/scripts/apply-patches.py"
mkdir -p "$LAB_ROOT/.local/bin"
(
    cd "$LAB_ROOT/otns"
    cp "$LAB_ROOT/locks/otns-go.sum" go.sum
    go build -o "$LAB_ROOT/.local/bin/otns" ./cmd/otns
)
(
    cd "$LAB_ROOT/otns/ot-rfsim"
    ./script/build_latest
)
if [[ ! -d "$LAB_ROOT/.venv" ]]; then
    "$LAB_PYTHON" -m venv "$LAB_ROOT/.venv"
fi
"$LAB_ROOT/.venv/bin/python" -m pip install -r "$LAB_ROOT/requirements.txt"
"$LAB_ROOT/.venv/bin/python" -m pip install --no-deps --no-build-isolation "$LAB_ROOT/otns/pylibs"
echo "Environment ready. Run ./scripts/check.sh and ./scripts/run-example.sh."
