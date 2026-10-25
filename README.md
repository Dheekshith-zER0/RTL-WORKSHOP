# RTL-WORKSHOP

My VSD RTL design, synthesis, physical-design and static-timing workshop work, organized by week and assignment.

## Project index

- **Project 2 of 3 — Escrow Release Controller with Timeout-Based Refund:** [project README](./Project_2_of_3_Escrow_Release_Controller_with_Timeout_Based_Refund/README.md). Includes RTL verification, OpenLane/SKY130HD physical-design evidence, routed artifacts, and a supplementary 16-model STA study.
- **Week 4 — VSDBABYSOC:** [Week 4 documentation](./Week_4_VSDBABYSOC/README.md). Separate ORFS walkthrough and post-route multi-corner STA exercise.
- **Assignments:** [assignment index](./Assignments/Assignments/README.md).

## Reading the results

A completed flow or a script status of PASS does not itself prove timing closure. Review setup WNS, setup TNS, hold slack, constraint coverage, DRC/LVS and antenna evidence separately. Where a report identifies a limitation or an unmeasured metric, do not replace it with an assumed pass or fabricated value.

For the escrow project, see `Project_2_of_3_Escrow_Release_Controller_with_Timeout_Based_Refund/STA_16_corners/README.md` for reproducible sweep and report-generation instructions.
