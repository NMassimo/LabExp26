#!/usr/bin/env python3
"""Rebuild the course patch series from selected OTNS source files (maintainer use)."""
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
OTNS = ROOT / "otns"
PATHS = [
    "otns_main/otns_main.go", "cli/CmdRunner.go", "cli/README.md", "cli/ast.go", "cli/energy_test.go",
    "dispatcher/dispatcher.go", "energy/core.go", "energy/node.go",
    "energy/types.go", "energy/model.go", "energy/snapshot.go",
    "energy/energy_test.go", "energy/README.md", "etc/energy-lab-example.json",
    "etc/energy-lab-example.md", "pylibs/otns/cli/OTNS.py",
    "pylibs/examples/energy_control.py", "pylibs/unittests/test_energy.py",
]
INSTALL_PATHS = ["script/common.sh", "script/install-deps"]


def main():
    base = (ROOT / "otns.commit").read_text().strip()
    head = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=OTNS, text=True).strip()
    if head != base:
        sys.exit(f"Expected OTNS commit {base}.")
    for filename, title, paths in [
        ("0001-configurable-radio-energy.patch", "Configurable radio energy and Python snapshots", PATHS),
        ("0002-local-bootstrap-gui.patch", "Local Python environment and native GUI proxy", INSTALL_PATHS),
    ]:
        tracked, added = [], []
        for name in paths:
            result = subprocess.run(["git", "ls-files", "--error-unmatch", "--", name],
                                    cwd=OTNS, capture_output=True)
            (tracked if result.returncode == 0 else added).append(name)
        patch = f"OTNS base: {base}\nSubject: {title}\n\n".encode()
        patch += subprocess.check_output(
            ["git", "diff", "--binary", "--full-index", base, "--", *tracked], cwd=OTNS)
        for name in added:
            result = subprocess.run(["git", "diff", "--no-index", "--binary", "--full-index",
                                     "--", "/dev/null", name], cwd=OTNS, capture_output=True)
            if result.returncode != 1:
                sys.exit(f"Cannot export {name}: {result.stderr.decode()}")
            patch += result.stdout
        target = ROOT / "patches" / filename
        target.parent.mkdir(exist_ok=True)
        target.write_bytes(patch)
        print(f"Wrote {target.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
