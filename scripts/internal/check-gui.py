#!/usr/bin/env python3
"""Verify GUI pages, JavaScript and a browser-protocol RPC without opening a browser."""
from pathlib import Path
import struct
import subprocess
import tempfile
import time
import urllib.error
import urllib.request

from otns.cli import OTNS

ROOT = Path(__file__).resolve().parents[2]


def get_ready(url, allow_empty=False):
    deadline = time.monotonic() + 15
    while True:
        try:
            with urllib.request.urlopen(url, timeout=2) as response:
                data = response.read()
                if response.status == 200 and (data or allow_empty):
                    return data
        except (urllib.error.URLError, TimeoutError):
            if time.monotonic() >= deadline:
                raise
        if time.monotonic() >= deadline:
            raise RuntimeError(f"GUI endpoint not ready: {url}")
        time.sleep(0.2)


def main():
    proxy_binary = ROOT / ".local/bin/grpcwebproxy"
    if not proxy_binary.is_file():
        raise RuntimeError("GUI proxy missing; run ./scripts/setup.sh")
    # OTNS writes runtime files in its current working directory.
    import os
    previous = Path.cwd()
    try:
        with tempfile.TemporaryDirectory(prefix="otns-gui-check-") as temp:
            os.chdir(temp)
            ns = OTNS(sim_id=40, otns_path=str(ROOT / ".local/bin/otns"),
                      otns_args=["-no-replay", "-pcap", "off", "-logfile", "off"])
            proxy = None
            try:
                ns.cmd('debug echo "GUI check"')
                for endpoint in ("/visualize?addr=localhost:9398", "/energyViewer?addr=localhost:9398",
                                 "/statsViewer?addr=localhost:9398", "/static/js/energyViewer.js"):
                    get_ready("http://localhost:9397" + endpoint)
                with open("proxy.log", "w+") as log:
                    proxy = subprocess.Popen([
                        str(proxy_binary), "--backend_addr=localhost:9399",
                        "--run_tls_server=false", "--allow_all_origins",
                        "--enable_health_endpoint",
                        "--server_bind_address=127.0.0.1", "--server_http_debug_port=9398",
                    ], stdout=log, stderr=subprocess.STDOUT)
                    get_ready("http://127.0.0.1:9398/_health", allow_empty=True)
                    command = b"energy snapshot"
                    message = b"\x0a" + bytes([len(command)]) + command
                    frame = b"\x00" + struct.pack(">I", len(message)) + message
                    request = urllib.request.Request(
                        "http://127.0.0.1:9398/visualize_grpc_pb.VisualizeGrpcService/Command",
                        data=frame, headers={"Content-Type": "application/grpc-web+proto",
                                             "X-Grpc-Web": "1", "Origin": "http://localhost:9397"})
                    with urllib.request.urlopen(request, timeout=10) as response:
                        body = response.read()
                    if b'"schema_version":1' not in body or b'"scope":"current_nodes"' not in body:
                        raise RuntimeError(f"GUI RPC did not reach patched OTNS: {body!r}")
                    # The topology viewer also needs server-streaming, not only unary RPCs.
                    request = urllib.request.Request(
                        "http://127.0.0.1:9398/visualize_grpc_pb.VisualizeGrpcService/Visualize",
                        data=b"\x00\x00\x00\x00\x00",
                        headers={"Content-Type": "application/grpc-web+proto", "X-Grpc-Web": "1"})
                    with urllib.request.urlopen(request, timeout=10) as response:
                        header = response.read(5)
                        if len(header) != 5 or header[0] != 0:
                            raise RuntimeError("GUI visualization stream did not return a data frame")
                        size = struct.unpack(">I", header[1:])[0]
                        if not 0 < size < 1024 * 1024 or len(response.read(size)) != size:
                            raise RuntimeError("Invalid visualization stream payload")
                    if proxy.poll() is not None:
                        raise RuntimeError("GUI proxy exited during the check")
                print("GUI check passed: pages, JavaScript, native proxy, energy RPC and visualization stream.")
            finally:
                if proxy is not None:
                    proxy.terminate()
                    try:
                        proxy.wait(timeout=5)
                    except subprocess.TimeoutExpired:
                        proxy.kill()
                        proxy.wait()
                ns.close()
    finally:
        os.chdir(previous)


if __name__ == "__main__":
    main()
