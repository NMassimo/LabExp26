#!/usr/bin/env python3
"""Print a usable Go bin directory, installing a local compiler if needed."""
import hashlib
import json
from pathlib import Path
import platform
import re
import shutil
import subprocess
import sys
import tempfile
import urllib.request

ROOT = Path(__file__).resolve().parents[1]


def main():
    installed = shutil.which("go")
    if installed:
        result = subprocess.run([installed, "version"], capture_output=True, text=True)
        match = re.search(r"go(\d+)\.(\d+)", result.stdout)
        if result.returncode == 0 and match and tuple(map(int, match.groups())) >= (1, 23):
            print(Path(installed).parent)
            return
    lock = json.loads((ROOT / "locks/go-toolchain.json").read_text())
    system = platform.system().lower()
    arch = {"x86_64": "amd64", "aarch64": "arm64", "arm64": "arm64"}.get(platform.machine())
    key = f"{system}-{arch}"
    if key not in lock["sha256"]:
        sys.exit(f"No local Go installer for {key}; install Go 1.23+ and retry.")
    directory = ROOT / ".local/toolchains" / lock["version"]
    if not (directory / "bin/go").is_file():
        directory.parent.mkdir(parents=True, exist_ok=True)
        filename = f"{lock['version']}.{key}.tar.gz"
        print(f"Installing {lock['version']} locally for {key}...", file=sys.stderr)
        with tempfile.TemporaryDirectory(dir=directory.parent) as temp:
            archive = Path(temp) / filename
            digest = hashlib.sha256()
            with urllib.request.urlopen(f"https://go.dev/dl/{filename}", timeout=60) as response, archive.open("wb") as output:
                while chunk := response.read(1024 * 1024):
                    output.write(chunk)
                    digest.update(chunk)
            if digest.hexdigest() != lock["sha256"][key]:
                sys.exit("Go archive checksum mismatch; nothing installed.")
            subprocess.run(["tar", "-xzf", str(archive), "-C", temp], check=True)
            shutil.move(str(Path(temp) / "go"), directory)
    print(directory / "bin")


if __name__ == "__main__":
    main()
