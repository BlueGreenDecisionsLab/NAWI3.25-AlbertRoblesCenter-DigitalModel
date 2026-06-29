# ARC Digital model (`ARC_DTm`)

A Simulink-based digital twin model of an advanced water treatment facility, coupled with an on-site hybrid power system (solar generation + battery storage) operating under time-of-use (TOU) electricity pricing. The model lets you simulate the full treatment train alongside its energy supply, then sweep operational and economic scenarios to evaluate cost, energy, and process performance.

The digital model links two domains in a single Simulink model:

Treatment train — an advanced potable/reuse-style process chain:
- UF — ultrafiltration
- RO — reverse osmosis
- UVAOP — UV advanced oxidation process
- Pumps — feed/transfer hydraulics across the train

Energy system — the plant's power supply and dispatch:
- On-site solar generation
- Battery storage scenarios
- TOU rate scheduling and demand charges
- Hybrid power control logic (`HybridPowerControls_EPRI.fmu`)

## Repository structure

### Core model
| Item | Description |
|------|-------------|
| `ARC_DTm.slx` | **Main Simulink digital model** |
| `HybridPowerControls_EPRI.fmu` | Co-simulation FMU for hybrid power control logic |
| `Pumps/`, `UF/`, `ReverseOsmosis/`, `UVAOP/` | Subsystem assets for each unit process |
| `mask_imgs/` | Block mask icon images used in the Simulink model |

### Run & analysis scripts
| Item | Description |
|------|-------------|
| `_RUNSIM.mlx` |Primary run script (MATLAB Live Script) — configures and executes a simulation |
| `_RUNSIM_ParameterSweep.m` | Drives multi-scenari oparameter sweep of the model |
| `postSimAnalysis.m` | Post-simulation processing, metrics, and plotting |

### Configuration (inputs)
| Item | Description |
|------|-------------|
| `_PARAMETERS.xlsx` | List of model parameters |
| `_TOURates.xlsx` | Time-of-use electricity rate schedules |
| `OperationalScenarios.xlsx` | Operational scenario definitions for sweeps |
| `SolarSimulationData/` | Solar generation profiles / input data |
| `_data/`, `Data Preparation/` | Source data and preprocessing for model inputs |

### Outputs
| Item | Description |
|------|-------------|
| `Results/` | Simulation result outputs |
| `sweep_results/` | Outputs from parameter sweep runs |


## Requirements

- **MATLAB / Simulink** (with the toolboxes used by the model with FMI import for the `.fmu`)
- **Microsoft Excel**–readable `.xlsx` inputs (read by the run scripts)



## Running a simulation

Open and run **`_RUNSIM.mlx`** to execute a single configured simulation.

### Scenario sweeps

To explore many configurations (solar levels, TOU cases, demand-charge pairs, battery states, operational cases), run **`_RUNSIM_ParameterSweep.m`**, which loads scenario definitions from the Excel inputs and writes results to `sweep_results/`.

---

## Notes

- Configuration is **data-driven**: most behavior is set in the `.xlsx` inputs rather than in code, so new scenarios can be added without editing the model.
