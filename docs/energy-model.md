# Radio energy and Python control

The simulator integrates electrical power over simulated radio-state durations.
Frame events provide the effective TX power; ACKs and retries are included.
Energy is cumulative, and changing TX power affects subsequent intervals.

## Laboratory profile

Load `otns/etc/energy-lab-example.json` after applying the course patch. The
profile approximates the TI CC2652R at 3 V using typical datasheet currents.

| TX setting (dBm) | Electrical power (mW) |
|---:|---:|
| −20 | 13.8 |
| −15 | 14.7 |
| −10 | 15.9 |
| −5 | 17.7 |
| 0 | 21.0 |
| +1 | 21.9 |
| +2 | 22.8 |
| +3 | 24.6 |
| +4 | 25.8 |
| +5 | 27.6 |

RX uses 20.7 mW; Sleep uses 0.00282 mW; Disabled uses 0.00045 mW.
Reference: [TI CC2652R datasheet, revision J](https://www.ti.com/lit/ds/symlink/cc2652r.pdf),
sections 8.5–8.6 and table 8-1. The conversion is `P[mW] = 3 V × I[mA]`.
The published PA table is characterized in BLE operation; applying it to Thread
on the same multiprotocol chip is a teaching approximation. Standby/shutdown
currents provide low-power proxies for radio-off states. CPU activity, board
peripherals and transition energy are outside this model.

Use the ten listed TX settings. Interpolation is linear in dBm between table
points. Outside the table the energy model clamps to the endpoint, while the RF
simulator still uses the requested transmission power. Therefore the algorithm
must enforce the allowed action set.

## State meanings

- **RX:** receiver on, including idle listening, reception and relevant
  channel-assessment/ACK-wait intervals.
- **TX:** physical transmission of a data, control or ACK frame.
- **Sleep:** radio off, represented by standby consumption.
- **Disabled:** radio disabled, represented by shutdown consumption.

The text export labels Sleep as `Idle (mJ)`; this does not mean idle listening.
The MCU's own Idle mode is not tracked separately.

Low-power TX may consume less than RX. For always-listening routers, replacing
listening time with TX time can reduce the state-based energy. Do not add a
second RX charge per received packet. Evaluate complete network energy rather
than treating every extra hop as a fixed positive energy cost.

## Python API

From the `otns` working directory:

```python
from otns.cli import OTNS

ns = OTNS(otns_args=["-seed", "42"])
try:
    ns.energy_model("etc/energy-lab-example.json")
    ns.radiomodel = "MutualInterference"
    ns.add("router", x=0, y=0, txpower=0)
    ns.add("router", x=100, y=0, txpower=0)
    ns.go(120)

    start = ns.energy_snapshot()
    ns.ping(1, 2, datasize=32, count=20, interval=1)
    ns.go(30)
    end = ns.energy_snapshot()
    energy_j = end["total_j"] - start["total_j"]
    replies = ns.pings()
finally:
    ns.close()
```

`ns.energy_model()` reads the current model; providing a filename loads it.
`ns.node_cmd(node_id, "txpower -10")` changes one node's transmission power.
`ns.energy_snapshot()` closes open intervals at the current simulation time
without advancing it. Snapshot fields include:

| Field | Meaning |
|---|---|
| `time_us` | Simulation timestamp in microseconds |
| `total_j` | Sum of energy for currently present nodes, in joules |
| `disabled_j`, `sleep_j`, `tx_j`, `rx_j` | Network energy by state |
| `nodes` | Sorted per-node values, including `node_id` and `state_times_us` |
| `model_name`, `model_revision` | Consumption model and configuration revision |
| `schema_version` | Snapshot schema version, currently 1 |
| `scope` | `current_nodes` |

Use differences of snapshots over a fixed node set. Deleting a node removes its
contribution from the current-node sum; recreating it starts new counters.
Configure the profile before measurements. The GUI and network-history text
exports report means per node in mJ, while JSON snapshots report network sums
in joules.

The corresponding global CLI commands are:

```text
energy model "etc/energy-lab-example.json"
energy snapshot
energy save "experiment"
```
