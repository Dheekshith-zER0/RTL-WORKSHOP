# Project 2 of 3 — 2-of-3 Escrow Release Controller with Timeout-Based Refund

## Project overview

This project implements and verifies a small escrow controller in synthesizable Verilog. Three participants can approve a release; the controller coordinates the approval decision and supports a timeout-based refund path when the release condition is not met. The work is organized as RTL/verification, physical design/evidence, and supplementary multi-corner static timing analysis (STA).

> **Status:** RTL simulation and the recorded physical-design checks passed in the documented run. The supplementary 16-Liberty-model STA sweep found setup violations in two slow/low-voltage models. Treat these results as preliminary analysis, not signoff timing closure.

## Repository map

| Path | Contents |
|---|---|
| `01_RTL_Design_and_Verification/` | RTL, testbench, architecture notes, simulation script/log and synthesis statistics |
| `02_Physical_Design_and_Reports/` | OpenLane configuration, routed DEF/SPEF, GDS artifacts, screenshots, timing/route/DRC/LVS/antenna evidence |
| `STA_16_corners/` | 16-model STA summary, report, WNS chart, reproducible sweep/report scripts and TNS/WNS outputs |

## Reproduce the RTL simulation

From this directory, with Icarus Verilog installed:

```bash
cd 01_RTL_Design_and_Verification
chmod +x sim.sh
./sim.sh
```

The checked-in simulation log records **ALL TESTS PASSED**. This is RTL-level verification; gate-level simulation is not claimed as verified.

## Physical-design evidence

The recorded OpenLane/SKY130 HD run reports:
- 67 standard cells after synthesis.
- Detailed routing: 0 reported violations; 1,804 µm routed wire length; 535 vias.
- Antenna check: 0 violated pins and 0 violated nets.
- Magic DRC: `COUNT: 0`.
- LVS evidence: a unique netlist match, with 87 devices and 87 nets in each compared circuit.

These are recorded results for the documented run, not a claim of foundry signoff. Review the reports and configuration under `02_Physical_Design_and_Reports/` for context.

## Supplementary STA — 16 SKY130HD Liberty models

The sweep uses a 10 ns clock, 2 ns input/output delays, propagated clocks, a routed netlist/parasitic set, and one standard-cell Liberty model per run. It compares model sensitivity on a common routed implementation.

Recorded setup worst slack:
- Worst: **−5.86 ns**, `sky130_fd_sc_hd__ss_n40C_1v28`.
- Second failing corner: **−0.86 ns**, `sky130_fd_sc_hd__ss_n40C_1v35`.
- Best: **+7.26 ns**, `sky130_fd_sc_hd__ff_100C_1v95`.

All 16 recorded hold worst-slack values are positive (+0.30 ns to +1.69 ns). Positive hold slack does not cancel setup violations. Every row remains marked `REVIEW`.

The same routed SPEF was reused across all 16 Liberty models, so the comparison isolates cell timing-model changes while holding parasitics fixed. This is a preliminary sensitivity study, not a re-route at each PVT corner and not signoff STA.

### TNS and timing coverage

The checked-in baseline summary did **not** capture total negative slack (TNS). Blank TNS fields mean **not measured**, not zero. Run `STA_16_corners/run_sweep.sh` in the prepared OpenSTA/PDK environment to produce fresh WNS/TNS values, constraint-coverage logs, both charts and an updated DOCX. Do not label TNS analysis complete until those outputs have been generated from the actual OpenSTA run.

Excluded CCS-noise variants:
- `sky130_fd_sc_hd__ff_n40C_1v95_ccsnoise.lib`
- `sky130_fd_sc_hd__ss_n40C_1v60_ccsnoise.lib`

These are model variants, not additional PVT corners.

### Known caveats to resolve or retain

- OpenSTA previously warned that `sky130_fd_sc_hd__tapvpwrvgnd_1` was unavailable and black-boxed a physical-only instance.
- Liberty warned that `default_fanout_load = 0.0`.
- Constraints must be checked for unconstrained endpoints and appropriate input/output coverage before any signoff claim.
- The supplementary STA run is not presented as an official OpenLane signoff metric.
- Gate-level simulation remains unverified.

## Recommended review order

1. Read `01_RTL_Design_and_Verification/README.md` and the architecture notes.
2. Inspect `02_Physical_Design_and_Reports/physical_design_summary.txt`, `magic_drc_report.txt`, `antenna_report.rpt`, routing completion and LVS logs.
3. Run the 16-model sweep and inspect `STA_16_corners/summary.csv`, generated TNS/WNS charts and `STA_16_Corner_Report.docx`.
4. Review constraint-coverage and warning sections before drawing timing-closure conclusions.

## Engineering conclusion

The project has documented RTL, simulation evidence, physical-design artifacts and an initial multi-corner STA study. The study highlights setup-timing risk at slow, low-voltage corners. The next engineering gate is to regenerate TNS from OpenSTA, inspect constraint coverage, and investigate failing setup paths. Do not report the design as timing-closed or signoff-ready until those checks are resolved and rerun.
