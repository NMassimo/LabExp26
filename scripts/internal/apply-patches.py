#!/usr/bin/env python3
"""Apply the course patch series to the pinned OTNS checkout, without resets."""
import argparse
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
OTNS = ROOT / "otns"


def git(*args):
    return subprocess.run(["git", "-C", str(OTNS), *args],
                          text=True, capture_output=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true",
                        help="verify that all course patches are already applied")
    args = parser.parse_args()
    expected = (ROOT / "otns.commit").read_text().strip()
    if not (OTNS / ".git").exists():
        sys.exit("Initialize OTNS first: git submodule update --init --recursive")
    head = git("rev-parse", "HEAD")
    if head.returncode or head.stdout.strip() != expected:
        sys.exit(f"OTNS must be at commit {expected}; no files were changed.")
    patches = sorted((ROOT / "patches").glob("*.patch"))
    if not patches:
        sys.exit("No course patches found.")
    for patch in patches:
        if git("apply", "--reverse", "--check", str(patch)).returncode == 0:
            print(f"Applied: {patch.name}")
            continue
        if args.check:
            sys.exit(f"Missing or modified patch: {patch.name}; rerun ./scripts/setup.sh.")
        check = git("apply", "--check", "--whitespace=error", str(patch))
        if check.returncode:
            sys.exit(f"Cannot apply {patch.name}; keep/review local changes before retrying.\n{check.stderr}")
        applied = git("apply", "--whitespace=error", str(patch))
        if applied.returncode:
            sys.exit(applied.stderr)
        print(f"Applied: {patch.name}")


if __name__ == "__main__":
    main()
