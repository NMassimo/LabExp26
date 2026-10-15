#!/usr/bin/env bash
# Install patched OTNS, all node versions and the GUI, then run course checks.
set -euo pipefail
LAB_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
case "$(uname -s)" in
    Darwin)
        Darwin=1; Linux=0
        if ! command -v brew >/dev/null 2>&1; then
            echo "Install Homebrew (https://brew.sh) and rerun this script." >&2
            exit 1
        fi
        ;;
    Linux) Darwin=0; Linux=1 ;;
    *) echo "Use Linux, macOS or Ubuntu under WSL2." >&2; exit 1 ;;
esac
command -v git >/dev/null 2>&1 || { echo "Git is required to clone the repository." >&2; exit 1; }
git -C "$LAB_ROOT" submodule update --init --recursive -- otns
# Reuse upstream package-manager helpers before Python is available.
source "$LAB_ROOT/otns/script/utils.sh"
install_package python3 --apt python3 --brew python3
LAB_PYTHON=${LAB_PYTHON:-python3}
if ! "$LAB_PYTHON" -c 'import sys; sys.exit(sys.version_info < (3, 10))'; then
    if [[ $Darwin == 1 ]]; then
        brew install python3
        LAB_PYTHON="$(brew --prefix)/bin/python3"
    else
        echo "Python 3.10+ is required; use Ubuntu 22.04+ or set LAB_PYTHON." >&2
        exit 1
    fi
fi
if ! "$LAB_PYTHON" -c 'import venv, ensurepip' >/dev/null 2>&1; then
    install_package virtualenv --apt python3-venv --brew python3
fi
"$LAB_PYTHON" "$LAB_ROOT/scripts/apply-patches.py"
LAB_GO_BIN=$("$LAB_PYTHON" "$LAB_ROOT/scripts/ensure-go.py")
mkdir -p "$LAB_ROOT/.local/bin"
export GOBIN="$LAB_ROOT/.local/bin"
export OTNS_PYTHON_VENV="$LAB_ROOT/.venv"
export OTNS="$GOBIN/otns"
if [[ ! -d "$OTNS_PYTHON_VENV" ]]; then
    "$LAB_PYTHON" -m venv "$OTNS_PYTHON_VENV"
fi
export PATH="$OTNS_PYTHON_VENV/bin:$GOBIN:$LAB_GO_BIN:$PATH"
python -m pip install -r "$LAB_ROOT/requirements.txt"
(
    cd "$LAB_ROOT/otns"
    cp "$LAB_ROOT/locks/otns-go.sum" go.sum
    ./script/bootstrap
)
"$LAB_ROOT/scripts/check.sh"
"$LAB_ROOT/scripts/run-example.sh"
echo "Setup and checks completed. Start the GUI with ./scripts/run-otns.sh."
