#!/usr/bin/env bash
# Launch the full simulator and its browser GUI with the local installation.
set -euo pipefail
LAB_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
LAB_RUN_DIR="$LAB_ROOT/otns"
LAB_OTNS_ARGS=(-energy-model "$LAB_ROOT/otns/etc/energy-lab-example.json")
LAB_RESULTS_SET=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        --results)
            if [[ $# -lt 2 || $LAB_RESULTS_SET == 1 ]]; then
                echo "Usage: $0 [--results NAME] [OTNS options]" >&2
                exit 1
            fi
            case "$2" in
                ""|.|..|*/*|*\\*)
                    echo "Results name must be a single directory name, without / or \\." >&2
                    exit 1
                    ;;
            esac
            LAB_RUN_DIR="$LAB_ROOT/results/$2"
            LAB_RESULTS_SET=1
            shift 2
            ;;
        --help)
            echo "Usage: $0 [--results NAME] [OTNS options]"
            echo "The laboratory radio energy profile is loaded automatically."
            echo "Save runtime files in results/NAME (default: otns/)."
            echo "Use -h for OTNS options. Existing output files may be overwritten."
            exit 0
            ;;
        --) shift; LAB_OTNS_ARGS+=("$@"); break ;;
        *) LAB_OTNS_ARGS+=("$1"); shift ;;
    esac
done
if [[ ! -x "$LAB_ROOT/.local/bin/otns" || ! -x "$LAB_ROOT/.local/bin/grpcwebproxy" ]]; then
    echo "Run ./scripts/setup.sh first." >&2
    exit 1
fi
export PATH="$LAB_ROOT/.local/bin:$LAB_ROOT/.venv/bin:$LAB_ROOT/otns/ot-rfsim/ot-versions:$LAB_ROOT/otns/build/bin:$PATH"
mkdir -p "$LAB_RUN_DIR"
cd "$LAB_RUN_DIR"
echo "OTNS working directory: $LAB_RUN_DIR" >&2
exec "$LAB_ROOT/.local/bin/otns" "${LAB_OTNS_ARGS[@]}"
