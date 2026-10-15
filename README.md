# LAB EXPERIENCE IN COMMUNICATION NETWORKS AND INTERNET

Thread wireless networking laboratory for MSc students in Telecommunications
Engineering. The activity is designed for approximately **30 hours** of student
work using a local computer.

The goal is to develop an algorithm that selects each station's transmission
power to reduce total simulated radio energy while maintaining packet delivery.
Heuristics, numerical optimization and reinforcement learning can use the same
Python simulation interface. Evaluation topologies and traffic are supplied by
the instructor.

## Simulator and reproducibility

[OTNS](https://github.com/openthread/ot-ns) is included as a Git submodule at
commit **`1d61489561c22041b4877467c086721cfd0d2263`**. Its OpenThread submodule
and nested dependencies are pinned transitively. The same OTNS revision is
recorded in [otns.commit](otns.commit).

The [course patch](patches/0001-configurable-radio-energy.patch) adds configurable
radio energy accounting, current-time JSON snapshots and Python accessors. It is
applied to the upstream checkout during setup; OTNS itself is not forked or
committed with local changes.

## Requirements

- Linux or macOS. On Windows use WSL2 with Ubuntu 22.04 or newer and work inside
  the Linux filesystem.
- Git, Go **1.23+**, Python **3.10+** with `venv`/`pip`, CMake, Ninja and a C/C++
  compiler.
- Internet access for the initial checkout and dependency installation.

On Ubuntu, install the build tools with:

```sh
sudo apt update
sudo apt install git build-essential cmake ninja-build python3 python3-venv python3-pip
```

Install Go 1.23 or newer separately if your package manager provides an older
version. On macOS install the Xcode command-line tools and the corresponding
Git, Go, Python, CMake and Ninja packages, for example through Homebrew.

## Setup

Clone the course repository recursively, using its GitHub URL:

```sh
git clone --recurse-submodules <repository-url> lab-experience
cd lab-experience
./scripts/setup.sh
./scripts/check.sh
./scripts/run-example.sh
```

If you already cloned without `--recurse-submodules`, `setup.sh` initializes the
submodules. Setup applies the patch, builds OTNS and the Thread 1.4 FTD/MTD nodes,
and installs the Python package in **`.venv/`**. The simulator executable is
**`.local/bin/otns`**. No global OTNS or Python installation is overwritten.
Only the current Thread node version is built; legacy versions and a border
router are not required for this activity. The first build may take several minutes.

The setup script can be rerun. The patch script recognizes an already-applied
patch and refuses incompatible edits or an unexpected OTNS revision. If Python
is available under another name, set `LAB_PYTHON`, for example:

```sh
LAB_PYTHON=python3.12 ./scripts/setup.sh
```

The checks cover energy integration, power changes, fresh exports, per-node
accounting and Python control against actual OT-RFSIM node processes. They need
local sockets and are intended to run on your computer.

## Working with Python

Activate the environment and point Python at the local simulator:

```sh
source .venv/bin/activate
export OTNS="$PWD/.local/bin/otns"
cd otns
python pylibs/examples/energy_control.py
```

The example uses two routers, changes their TX powers and measures energy and
successful ping exchanges. The wrapper `scripts/run-example.sh` runs it from
any working directory and stores simulator-generated files in `results/example/`.

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
scripts/              setup, checks and example launcher
requirements.txt      pinned Python dependencies
locks/                Go dependency checksums
.local/               generated local executable (ignored)
.venv/                generated Python environment (ignored)
results/              generated experiment files (ignored)
```

For simulator changes, see [patch maintenance](patches/README.md).
Third-party license information is in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
