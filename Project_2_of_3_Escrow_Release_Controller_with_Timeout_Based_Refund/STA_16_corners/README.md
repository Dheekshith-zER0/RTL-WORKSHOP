# Escrow Release Controller — 16-Corner STA

## Purpose

This directory contains supplementary static timing analysis (STA) results for the routed Escrow Release Controller using OpenSTA and 16 SKY130 HD Liberty timing models.

## Contents

* `summary.csv` — measured setup worst negative slack (WNS), total negative slack (TNS), and hold slack across 16 corners.
* `STA_16_Corners_Results.xlsx` — formatted results workbook with key findings and plots.
* `plots/` — setup WNS, setup TNS, and hold-slack charts.
* `scripts/` — 16 corner-specific Tcl scripts.
* `logs/` — compact per-corner log summaries.
* `run_sweep.sh` — script to run the timing sweep.
* `summary_before_tns.csv` — previous baseline CSV retained for comparison.

## Key Findings

Two corners show negative setup slack and nonzero negative setup TNS:

| Corner                          | Setup WNS (ns) | Setup TNS (ns) | Hold slack (ns) |
| ------------------------------- | -------------: | -------------: | --------------: |
| `sky130_fd_sc_hd__ss_n40C_1v28` |          -5.86 |         -40.12 |           +1.48 |
| `sky130_fd_sc_hd__ss_n40C_1v35` |          -0.86 |          -3.89 |           +1.63 |

The remaining 14 corners have setup TNS of 0.00 ns. All 16 reported hold-slack values are positive.

Negative setup WNS indicates a setup timing violation. Negative TNS indicates aggregate negative slack across violating endpoints. These results do not demonstrate setup timing closure across all corners.

## Plots

* `plots/setup_wns_16_corners.png` — setup WNS across all 16 corners.
* `plots/setup_tns_16_corners.png` — measured setup TNS across all 16 corners.
* `plots/hold_slack_16_corners.png` — hold slack across all 16 corners.

## Methodology and Limitations

* Timing tool: OpenSTA 2.4.0.
* Sixteen SKY130 HD Liberty timing models were analyzed.
* The routed SPEF from the existing physical-design run was reused across all Liberty models.
* These are preliminary STA results, not signoff-validated multi-corner timing results.
* OpenSTA reported Liberty warnings and a black-box warning for a physical-only tap cell. Review the run diagnostics before relying on these results for signoff.

The compact logs retain selected diagnostics and result summaries. Run `run_sweep.sh` in the configured Linux environment to regenerate full logs.

## Interpretation

The slow-process corners at `ss_n40C_1v28` and `ss_n40C_1v35` require setup timing investigation. Do not describe the design as having achieved timing closure across all 16 corners.
