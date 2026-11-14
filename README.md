# LAB EXPERIENCE IN COMMUNICATION NETWORKS AND INTERNET

Thread wireless networking laboratory for MSc engineering students of Politecnico di Milano.

## Simulator and reproducibility

[OTNS](https://github.com/openthread/ot-ns) is included as a Git submodule at
commit **`1d61489561c22041b4877467c086721cfd0d2263`**. Its OpenThread submodule
and nested dependencies are pinned transitively. The same OTNS revision is
recorded in [otns.commit](otns.commit).

The [course patch series](patches/README.md) adds configurable radio energy,
JSON/Python snapshots and integration of the upstream bootstrap with a local
Python environment and native GUI proxy. Patches are applied to the upstream
checkout during setup; OTNS itself stays at the pinned commit.

## Setup

Prerequisites to run the setup:

- **Linux:** Ubuntu 22.04+ with Git, a browser and access to `sudo`/APT.
- **Windows:** WSL2 with Ubuntu 22.04+, Git and `sudo`/APT. Keep the checkout in
  the Linux filesystem. The browser can run on Windows.
- **macOS:** Git/Xcode command-line tools, Homebrew and a browser. The setup
  supports Intel and Apple Silicon.
- Internet access and sufficient disk space for the Go, C/C++ and node builds.

## One-command setup

To setup the simulator for the first time simply run these commands:

```sh
git clone https://github.com/NMassimo/LabExp26.git
cd LabExp26
./scripts/setup.sh
```

The script initializes the pinned submodules, applies course patches and
runs the **upstream OTNS bootstrap**. It installs the required build tools,
prepares Python, builds OTNS plus all standard node versions (including the
border router), installs the native GUI proxy and runs the upstream version
tests, course checks and a traffic example.

The simulator and GUI proxy are installed in **`.local/bin/`** and Python
packages in **`.venv/`**. If Go 1.23+ is unavailable, a local Go toolchain is
downloaded with a verified SHA-256 checksum. OTNS/Python installations elsewhere
on the machine are not overwritten. System build dependencies may be installed
through the platform package manager and may request administrator access.

The first complete build may take several minutes. The script can be rerun:
existing dependencies/build outputs are reused and patches are not applied twice.
For a particular Python installation, set `LAB_PYTHON`, for example:

```sh
LAB_PYTHON=python3.12 ./scripts/setup.sh
```

## Start OTNS with its GUI

After setup:

```sh
./scripts/run-otns.sh
```

This opens the GUI in the default browser and starts the OTNS CLI. If browser
opening is unavailable (for example in WSL2), open
[the local GUI](http://localhost:8997/visualize?addr=localhost:8998) manually while
OTNS is running. The launcher automatically loads the laboratory energy profile
(`otns/etc/energy-lab-example.json`) before the simulation starts.

By default, runtime files are written inside `otns/`: `current.pcap` in its
root and node logs/flash files in `tmp/`. To use a named directory under
`results/` instead:

```sh
./scripts/run-otns.sh --results experiment-01
```

This creates `results/experiment-01/` and uses it as OTNS's working directory,
regardless of where the launcher is called from. The name must be a single
directory name. Reusing a name reuses that directory; `current.pcap` and other
runtime files may be overwritten. Relative input and export paths are resolved
from this directory too.

OTNS options can also be passed, for example
`./scripts/run-otns.sh --results experiment-01 -web=false`.
Use `./scripts/run-otns.sh --help` for launcher help and `-h` for OTNS options.

## Checks

Setup runs the checks automatically. To rerun them independently:

```sh
./scripts/setup.sh --check
```

They verify energy integration, power changes, exports and Python control using
OT-RFSIM processes. The GUI check verifies all three GUI pages, JavaScript
assets, the native proxy, an energy-snapshot RPC and the visualization stream over gRPC-Web without
opening a browser. Checks require local sockets and should run sequentially.

## Working with Python

Activate the environment and point Python at the local simulator:

```sh
source .venv/bin/activate
export OTNS="$PWD/.local/bin/otns"
cd otns
python pylibs/examples/energy_control.py
```

The example uses two routers, changes their TX powers and measures energy and
successful ping exchanges. Setup and `setup.sh --check` also run this example,
storing simulator-generated files in `results/example/`.

The central API is:

```python
ns.energy_model("etc/energy-lab-example.json")
ns.node_cmd(node_id, "txpower -10")

start = ns.energy_snapshot()
ns.go(120)  # run the configured traffic during the measurement window
end = ns.energy_snapshot()
energy_j = end["total_j"] - start["total_j"]
```

Load the energy profile explicitly. Snapshot energies are cumulative **joules**,
with a network sum and values per node and radio state. Keep the node set fixed
while subtracting snapshots. The GUI and network-history text export show the
mean per node in mJ, so use snapshots for optimization rewards.

## Energy model and experiment design

The laboratory profile approximates the **TI CC2652R at 3 V**. Use its ten TX
settings: **−20, −15, −10, −5, 0, +1, +2, +3, +4, +5 dBm**. The energy table
does not restrict simulated RF power automatically; your algorithm must keep
its actions in this set.

Idle listening is RX; Sleep means radio off. The model estimates radio-state
energy, not a complete board or battery. At low TX settings electrical TX power
can be lower than listening power, so hop count alone is not an energy metric.
Measure network energy, delivered packets and latency over common windows.

Use `MutualInterference` for experiments where transmission power must affect
connectivity. Fix seeds for reproducibility, separate network formation from
measurement, and give routing time to react after changing powers. Evaluate
delivery against the traffic that should have been sent, including failed or
unaccepted requests; disconnected nodes must not obtain a better score merely
by sending less traffic.

- [Energy profile, state mapping and Python API](docs/energy-model.md)
- [OTNS CLI reference](https://github.com/openthread/ot-ns/blob/1d61489561c22041b4877467c086721cfd0d2263/cli/README.md)

After setup, additional API documentation and the example source are available
in `otns/energy/README.md` and `otns/pylibs/examples/energy_control.py`.

## Repository layout

```text
otns/                 pinned upstream submodule
otns.commit           expected OTNS revision
patches/              course modifications to OTNS
scripts/setup.sh      install everything and run checks (--check: checks only)
scripts/run-otns.sh    start OTNS with its GUI
scripts/internal/     implementation helpers (called automatically)
tools/                instructor tools for patch maintenance
requirements.txt      pinned Python dependencies
locks/                Go dependency and toolchain checksums
.local/               generated local executable (ignored)
.venv/                generated Python environment (ignored)
results/              generated experiment files (ignored)
```

For simulator changes, see [patch maintenance](patches/README.md).
Third-party license information is in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
