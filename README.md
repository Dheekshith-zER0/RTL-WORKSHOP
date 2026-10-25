# RTL Design & Synthesis Workshop

> **Final project submission — video links**
>
> - **Internal Submission Video:** [Watch the internal submission](https://drive.google.com/file/d/1m7nVfDJPEhI3tJ1B-1kgDrhY3-lQG6Eo/view?usp=drive_link)
> - **Project Submission Video:** [Watch the project submission](https://drive.google.com/file/d/1lTyBPYFNMrefYQZbERJziFjJBmFp8p6A/view?usp=drive_link)
>
> **Final project:** [2-of-3 Escrow Release Controller with Timeout-Based Refund](./Project_2_of_3_Escrow_Release_Controller_with_Timeout_Based_Refund/)
> - **Internal submission files:** [Open `FINAL_INTERNAL_SUBMISSION`](./FINAL_INTERNAL_SUBMISSION/)

This repository documents RTL design, simulation, synthesis and physical-design work completed during the VSD RTL Design and Synthesis Workshop. The final submission project is linked above; the remaining folders contain supporting workshop labs, assignments and learning evidence.

## Submission directories

- [**Final internal submission →**](./FINAL_INTERNAL_SUBMISSION/) — internal report and supporting submission material.
- [**Final project →**](./Project_2_of_3_Escrow_Release_Controller_with_Timeout_Based_Refund/) — escrow controller RTL, verification, physical-design results and supplementary timing analysis.

## Final project: Escrow Release Controller

[**Open the complete project directory →**](./Project_2_of_3_Escrow_Release_Controller_with_Timeout_Based_Refund/)

The project includes synthesizable Verilog RTL and testbench, simulation evidence, synthesis results, physical-design artifacts, routed outputs, DRC/LVS/antenna evidence, and a supplementary 16-model SKY130HD STA study. Start with the [project README](./Project_2_of_3_Escrow_Release_Controller_with_Timeout_Based_Refund/README.md) for architecture, run instructions, measured results and limitations.

### Current STA caveat

The escrow STA baseline shows negative setup WNS at `sky130_fd_sc_hd__ss_n40C_1v28` (−5.86 ns) and `sky130_fd_sc_hd__ss_n40C_1v35` (−0.86 ns). The baseline did not capture TNS; missing values are intentionally blank, not zero. The [STA README](./Project_2_of_3_Escrow_Release_Controller_with_Timeout_Based_Refund/STA_16_corners/README.md) documents the reproducible sweep and report-generation scripts. Do not claim timing closure until measured TNS and constraint coverage have been reviewed and the negative setup paths addressed.

## Workshop contents

| Section | Topics |
|---|---|
| [Week 1 — RTL](./Week_1_RTL) | RTL and testbench basics, Icarus Verilog, GTKWave, introductory Yosys synthesis, reset behavior |
| [Week 2 — RTL](./Week_2_RTL) | Logic optimization, GLS, simulation/synthesis mismatch, blocking vs. non-blocking assignments, latch inference, generate constructs, ripple-carry adder |
| [Week 3 — Physical Design](./Week_3_Physical_Design) | Open-source EDA, OpenLane, RTL-to-GDSII concepts, floorplanning, standard-cell characterization, timing, CTS, routing, DRC |
| [Week 4 — VSDBabySoC](./Week_4_VSDBABYSOC) | OpenROAD flow, synthesis, placement, CTS, routing, parasitic extraction, post-route STA, multi-corner analysis and debugging |
| [VSDBabySoC Lab](./LABS_Baby_SOC) | PLL → RVMYTH → DAC, pre-synthesis simulation, Yosys synthesis, gate-level netlist, GLS, RTL vs. GLS comparison |
| [Assignments](./Assignments) | Sequence-detector RTL-to-GLS, multi-corner STA of VSDBabySoC, and Assignment 3 materials |

## How to read the results

A completed flow or a script status of PASS does not itself prove timing closure. Review setup WNS, setup TNS, hold slack, constraint coverage, DRC/LVS and antenna evidence separately. Where a report identifies a limitation or an unmeasured metric, do not replace it with an assumed pass or fabricated value.

## Repository notes

- Each section contains its own notes and supporting evidence.
- Screenshots are stored with the relevant project or week's materials.
- Measured results are documented alongside their reports, with limitations noted where applicable.
