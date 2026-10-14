# Week 4 — VSDBABYSOC: RTL-to-Physical-Design Flow and Multi-Corner STA

## Contents

1. [Objective](#1-objective)
2. [Evidence map: what each screenshot shows](#2-evidence-map-what-each-screenshot-shows)
3. [Environment and tool setup](#3-environment-and-tool-setup)
4. [Synthesis](#4-synthesis)
5. [Physical implementation, stage by stage](#5-physical-implementation-stage-by-stage)
6. [Parasitic extraction](#6-parasitic-extraction)
7. [Post-route STA on VSDBABYSOC](#7-post-route-sta-on-vsdbabysoc)
8. [Results and observations](#8-results-and-observations)
9. [Technical learnings](#9-technical-learnings)
10. [Problems faced and how we addressed them](#10-problems-faced-and-how-we-addressed-them)
11. [Supporting documents](#11-supporting-documents)
12. [Conclusion](#12-conclusion)

---

## 1. Objective

This week covers the practical RTL-to-layout flow in OpenROAD-flow-scripts (ORFS), run in a browser-based GitHub Codespace, followed by post-route static timing analysis (STA) of the VSDBABYSOC design on SKY130HD.

The work moves through these checkpoints:

```
Synthesis → Floorplan → Placement → CTS → Global route → Detailed route → Fill → Final database
                                                                  │
                                                  Fresh SPEF extraction → Post-route STA (16 corners)
```

Results and learnings come first; problems and resolutions come after them (section 10).

## 2. Evidence map: what each screenshot shows

The screenshots come from two different runs, and I want that to be clear before the numbers.

| Figures | Design / platform | What they cover |
|---|---|---|
| 1–14 | `gcd` on `nangate45` (the reference design bundled with ORFS) | Environment setup and the full stage-by-stage flow: synthesis, floorplan, placement, CTS, routing, fill, database checkpoints |
| 15–19 | `vsdbabysoc` on `sky130hd` | Routed layout in the OpenROAD GUI, setup/hold slack histograms, and the 16-corner STA script and summary |

Every number quoted next to a figure below is read from that figure. Numbers that come from the written post-route STA report are labelled as such. Values that are not legible in a screenshot are not inferred.

## 3. Environment and tool setup

The flow was run in GitHub Codespaces from the `vsd-pd2` repository, which launches a ready-to-use OpenROAD environment with an XFCE desktop and browser-based noVNC access. All commands were run from `~/Desktop/OpenROAD-flow-scripts/flow`.

**Figure 1 — Codespace environment**

![Codespace setup](./images/01_codespace_setup.png)

The VSD-PD Codespace README (OpenROAD + noVNC cloud environment) open in the browser-based VS Code, with the OpenROAD GUI available through noVNC.

**Figure 2 — Terminal and working directory**

![Terminal environment](./images/02_terminal_environment.png)

A fresh terminal in `/workspaces/vsd-pd2`. From here the working directory is changed to the ORFS `flow` directory, where `make` drives every stage.

**Figure 3 — Tool version check**

![Tool versions](./images/03_tool_versions.png)

`openroad -version` reports **v2.0-25794-g7cbd77e748**, and `git log --oneline` shows the ORFS checkout commit. Recording the version matters because slack, wire length, and DRC counts can all change between OpenROAD builds.

## 4. Synthesis

**Figure 4 — Synthesis statistics**

![Synthesis statistics](./images/04_synthesis_statistics.png)

`cat reports/nangate45/gcd/base/synth_stat.txt` for the `gcd` design:

- Chip area for module `\gcd`: **659.946** (library area units)
- Area used by sequential elements: **158.27 (23.98 %)**
- 35 × `DFF_X1` account for all of the sequential area
- The largest combinational groups are 164 × `NAND2_X1`, 86 × `INV_X1`, and 60 × `OAI21_X1`

Reading the report: the cell-count column and the area column both appear twice (before and after cell mapping); for this report the two sets match, so no extra cells were added by the final mapping step.

## 5. Physical implementation, stage by stage

Each stage writes a numbered `.odb` checkpoint and a log, so the design can be inspected after any step. The area and utilization figures below come directly from each stage's `report_design_area` output.

| Stage | Design area (µm²) | Utilization | Source figure |
|---|---:|---:|---|
| Floorplan | 708 | 61 % | Figure 5 |
| Detailed placement | 850 | 74 % | Figure 6 |
| After CTS | 997 | 86 % | Figure 7 |
| Global route | 1034 | 90 % | Figure 8 |
| Detailed route | 1034 | 90 % | Figure 9 |
| Fill-cell insertion | 1034 | 90 % | Figure 11 |

Area grows between stages because each step adds cells or buffers (tap cells, timing-repair buffers, clock buffers), not because the design itself changes.

### 5.1 Floorplanning

**Figure 5 — Floorplan**

![Floorplan](./images/05_floorplan.png)

The floorplan log lists the stage outputs (`2_1_floorplan`, `2_2_floorplan_macro`, `2_3_floorplan_tapcell`, `2_4_floorplan_pdn`) and ends with `report_design_area`: **708 µm² at 61 % utilization**. The per-layer via-resistance table printed above it is the RC setup that later parasitic estimates rely on.

### 5.2 Placement

**Figure 6 — Detailed placement**

![Placement](./images/06_placement.png)

The detailed-placement log reports:

- Zero cells in no-regions, zero row-alignment problems, zero site-alignment problems, **zero overlaps** between adjacent cells
- Half-perimeter wirelength (HPWL) improved from **3590.3 µm to 3162.7 µm (−11.9 %)** during detailed-placement optimization
- `optimize_mirroring` mirrored 47 instances
- Resulting design area **850 µm², 74 % utilization**

### 5.3 Clock-tree synthesis (CTS)

**Figure 7 — Clock-tree synthesis and timing repair**

![Clock tree synthesis](./images/07_clock_tree_synthesis.png)

After CTS the log shows repair-timing activity:

- **19 buffers inserted**, 167 instances resized, 34 pins swapped, 1 instance cloned
- A warning that not all setup violations could be repaired (`RSZ-2…`, "Unable to repair all setup violations"), while hold reported no violations
- Placement displacement after legalization: 819.9 µm total, 10.3 µm maximum
- Design area **997 µm², 86 % utilization**

The setup warning here is worth remembering, because the global-route timing report (Figure 12) still shows negative slack for this design.

### 5.4 Global routing

**Figure 8 — Global routing**

![Global routing](./images/08_global_routing.png)

`5_1_grt.log` shows incremental global routing with congestion reports and a repair-antennas step that found **0 net violations and 0 pin violations**. Design area is **1034 µm² at 90 % utilization**. The file listing at the bottom confirms the routing outputs `5_1_grt.odb` and `5_2_route.log` were produced.

### 5.5 Detailed routing

**Figure 9 — Detailed routing**

![Detailed routing](./images/09_detailed_routing.png)

Tail of `5_2_route.log`:

- Total vias: **4415**, split as metal1 = 2074, metal2 = 1869, metal3 = 290, metal4 = 135, metal5 = 47 (metal6 and above unused)
- Zero wire length on metal9 and metal10
- Antenna check: **0 net violations, 0 pin violations**
- `detailed_route` took about 30 s and wrote `5_2_route.odb`

### 5.6 Metal fill and fill cells

**Figure 10 — Metal fill stage**

![Metal fill](./images/10_metal_fill.png)

The `6_1_fill` stage log shows the routed database being read, constraints and RC settings sourced, and `6_1_fill.odb` written. The flow directory listing shows the complete set of numbered logs from `1_1_yosys_canonicalize` through `6_report`.

**Figure 11 — Fill-cell insertion**

![Fill cell insertion](./images/11_fill_cell_insertion.png)

`5_3_fillcell.log`: `filler_placement` was run with `FILLCELL_X1/X2/X4/X8/X16/X32` and **placed 178 filler instances**, with design area unchanged at **1034 µm², 90 % utilization**. Filler cells maintain well and implant continuity; they add no logic.

### 5.7 Global-route timing and power report

**Figure 12 — Global-route report**

![Global-route report](./images/12_design_metrics.png)

`cat reports/nangate45/gcd/base/5_global_route.rpt` for `gcd`:

- Critical-path source clock latency (min): 0.0000; target clock latency (min): 0.0733
- Critical path delay: **0.4358**
- Critical path slack: **-0.2358** (negative)
- Slack divided by critical-path delay: **-54.107389**
- Power: total **1.15e-02 W**, split as sequential 13.3 %, combinational 82.0 %, clock 4.8 %, macro and pad 0 %. Internal power is 53.1 % of the total, switching 46.6 %, and leakage 0.3 %.

Values are copied as printed; the report does not show units in this view. The negative slack agrees with the CTS warning in section 5.3.

### 5.8 Database checkpoints and final layout

**Figure 13 - Stage database listing**

![Database checkpoints](./images/13_database_checkpoints.png)

A `find` over `results/nangate45/gcd/base/` lists every `.odb` checkpoint and its size, from `1_synth.odb` (637,028 bytes) through `6_final.odb` (**1,382,631 bytes**). The size stays flat across `5_3_fillcell`, `5_route`, `6_1_fill`, and `6_final`, as expected since later stages only add fill. This listing shows a complete chain of stage databases; **no `.gds` file appears in this output**, so it is not evidence that GDS streaming was completed.

**Figure 14 - Final layout in OpenROAD GUI**

![Final layout](./images/14_final_layout.png)

The completed `6_final` database for `gcd` opened in the OpenROAD GUI via noVNC, with the metal1 to metal6 layer controls visible and the routed layout displayed.

## 6. Parasitic extraction

For post-route STA on VSDBABYSOC, fresh parasitics were extracted from the latest routed database instead of reusing older final-stage files that might not match the latest route. The inputs to every STA run were:

| Input | File |
|---|---|
| Routed database | `results/sky130hd/vsdbabysoc/base/5_2_route.odb` |
| Constraints | `results/sky130hd/vsdbabysoc/base/5_1_grt.sdc` |
| Parasitics | `results/sky130hd/vsdbabysoc/base/5_2_route_fresh.spef` |
| Standard-cell timing | One of 16 SKY130HD Liberty corner files per run |
| Macro timing | `designs/sky130hd/vsdbabysoc/lib/avsddac.lib` and `avsdpll.lib` |

## 7. Post-route STA on VSDBABYSOC

### 7.1 Routed layout

**Figure 15 — VSDBABYSOC routed design in OpenROAD GUI**

![VSDBABYSOC routed GUI](./images/15_vsdbabysoc_routed_gui.png)

The routed `vsdbabysoc` design with the large pink block labelled `dac` and the PLL region at the top. The Scripting pane shows the `read_liberty` commands that load the `avsddac.lib` and `avsdpll.lib` macro models, which is how the macros were included in timing analysis.

### 7.2 Typical-corner timing

The `gcd` global-route timing and power report is Figure 12 (section 5.7); it is a different design from VSDBABYSOC.

The VSDBABYSOC typical-corner numbers come from the written post-route STA report (section 11), not from this screenshot:

- Clock period: **11.00 ns**
- Worst setup slack: **6.13 ns**; worst hold slack: **0.32 ns**
- Setup TNS and hold TNS: **0.0 ns**

### 7.3 Slack histograms

**Figure 16 — Setup slack histogram**

![Setup slack histogram](./images/16_setup_slack_histogram.png)

**Figure 17 — Hold slack histogram**

![Hold slack histogram](./images/17_hold_slack_histogram.png)

Both are endpoint-slack charts for clock `clk` in the OpenROAD GUI. The setup chart shows **30 unconstrained pins** and the hold chart shows **26**. Unconstrained pins are not checked by any timing constraint, so a positive slack figure alone does not prove every path is covered.

### 7.4 Sixteen-corner experiment

**Figure 18 — Corner-sweep script**

![STA corner script](./images/18_sta_corner_script.png)

The script `/tmp/run_sta16.sh` loops over the corners. For each one it reads one standard-cell Liberty file, then the DAC and PLL macro Liberty files, then the routed `.odb`, the `.sdc`, `setRC.tcl`, and the `.spef`. It then runs `report_checks` for max and min paths and `report_worst_slack` for max and min, and saves a per-corner log. The terminal below it prints `OK` for each corner as it completes.

**Figure 19 — Summary CSV**

![Corner sweep summary](./images/19_corner_sweep_summary.png)

`summary.csv` reports `Completed: 32 corner logs`. That is 16 corners, each with two log files (a plain log and an `.openroad` log), so each corner appears twice in the CSV. The columns are corner, worst setup slack, worst hold slack, WNS, TNS, and status. All rows say `PASS`, which is the **tool-run status**, not a timing verdict.

**Library scope.** The 16 corners come from the separate SKY130 standard-cell library repository (`skywater-pdk-libs-sky130_fd_sc_hd/timing/`). They are **not** the three-part Liberty files from the VSDBABYSOC repository's own `timing/` folder. The DAC and PLL models were held at their existing characterization in every run, so this is a 16-corner standard-cell sweep, not a full multi-corner characterization of the macros.

| Corner | Setup slack (ns) | Hold slack (ns) | Setup TNS (ns) | Setup result |
|---|---:|---:|---:|---|
| ff_100C_1v65 | 7.22 | 0.26 | 0 | Positive |
| ff_100C_1v95 | 8.07 | 0.20 | 0 | Positive |
| ff_n40C_1v56 | 5.99 | 0.30 | 0 | Positive |
| ff_n40C_1v65 | 6.72 | 0.26 | 0 | Positive |
| ff_n40C_1v76 | 7.36 | 0.23 | 0 | Positive |
| ff_n40C_1v95 | 8.07 | 0.20 | 0 | Positive |
| ss_100C_1v40 | −3.55 | 0.92 | −390.07 | **Negative** |
| ss_100C_1v60 | 1.24 | 0.65 | 0 | Positive |
| ss_n40C_1v28 | −29.21 | 1.80 | −14131.26 | **Negative** |
| ss_n40C_1v35 | −16.31 | 1.34 | −6593.49 | **Negative** |
| ss_n40C_1v40 | −10.87 | 1.12 | −3379.48 | **Negative** |
| ss_n40C_1v44 | −7.69 | 0.99 | −1900.72 | **Negative** |
| ss_n40C_1v60 | −0.45 | 0.67 | −5.89 | **Negative** |
| ss_n40C_1v76 | 2.91 | 0.50 | 0 | Positive |
| tt_025C_1v80 | 6.13 | 0.32 | 0 | Positive |
| tt_100C_1v80 | 6.22 | 0.32 | 0 | Positive |

Values are rounded to two decimals from the recorded output. Hold TNS is 0.0 ns at all 16 corners.

## 8. Results and observations

**Timing across corners**

- All 16 runs completed, yet **six corners have negative worst setup slack**: ss_100C_1v40, ss_n40C_1v28, ss_n40C_1v35, ss_n40C_1v40, ss_n40C_1v44, and ss_n40C_1v60.
- The worst case is **−29.21 ns at ss_n40C_1v28**, with setup TNS of −14131.26 ns.
- At the slow-slow, −40 °C corner, setup slack improves steadily as the supply voltage rises: −29.21 ns (1.28 V), −16.31 (1.35 V), −10.87 (1.40 V), −7.69 (1.44 V), −0.45 (1.60 V), +2.91 ns (1.76 V). Lower voltage means slower cells.
- Hold behaves the other way round. Hold slack is smallest at the fast corners (0.20 ns at ff_100C_1v95 and ff_n40C_1v95) and largest at slow corners (1.80 ns at ss_n40C_1v28). All hold slacks are positive.

**Routing**

- The recorded VSDBABYSOC detailed-route output reported **28 DRC violations**, identified as **Metal 1 shorts** around the DAC-related area and nets. No antenna net/pin violations were reported. Approximate routed wire length was **227,853 µm**, via count **50,026**, and reported utilization **19 %**. These figures are from the recorded run output cited in the STA report; the screenshot of that log is not part of this evidence set. Figure 9 is the `gcd` routing log, not VSDBABYSOC.
- The evidence does not show that the 28 shorts were later removed, so the design is **not described as DRC-clean**.

**Caveats that apply to the whole analysis**

- Positive typical-corner slack and six failing slow corners are separate findings and are reported together.
- 30 setup and 26 hold unconstrained pins remain in the GUI charts.
- The macros were not swept across corners.

## 9. Technical learnings

1. The flow is a chain of checkpoints (synthesis, floorplan, placement, CTS, routing, fill), and each writes its own database and log. Each one answers a different question, and the numbered `.odb` files let me inspect any stage.
2. Area and utilization rise through the flow (61 % → 74 % → 86 % → 90 % for `gcd`) because timing-repair buffers, clock buffers, and tap cells are added at each step.
3. A log line can contradict a clean-looking layout. CTS reported that some setup violations could not be repaired, and the global-route report still shows negative slack. A complete layout image is not proof of timing closure.
4. Post-route STA is only meaningful when the database, SDC, SPEF, and Liberty files all describe the same run, which is why fresh SPEF was extracted.
5. Setup and hold are stressed at opposite corners: setup fails at slow, low-voltage corners; hold is tightest at fast, high-voltage corners. Sign-off needs both ends.
6. A script "completing" (`OK`, `PASS`) is a tool status, not a timing result. Slack and TNS have to be read from the numbers.
7. Slack figures do not cover unconstrained pins, so the unconstrained-pin count has to be checked alongside WNS and TNS.
8. Library provenance and scope must be stated: the 16 corners came from a separate SKY130 repository, and the macros stayed at fixed characterization.
9. A stage listing of `.odb` files is not a GDS deliverable. The final-database chain and the GDS stream are different checks.

## 10. Problems faced and how we addressed them

The obstacles below were worked through enough to complete the runs and the analysis. That does not mean every underlying design-quality issue was resolved.

### 10.1 Environment and flow navigation

**Challenge:** Getting the Codespace running and finding the right flow, platform, design, and report paths.

**Approach:** Checked the tool version (Figure 3), changed into the ORFS `flow` directory, and used `ls` and `tail` on `logs/<platform>/<design>/base/` to find each stage's outputs.

**Outcome:** The flow ran end to end and every stage's log and database could be inspected.

### 10.2 Consistency of post-route timing inputs

**Challenge:** Older final-stage files could be stale relative to the latest routed database, so the layout and timing evidence might not match.

**Approach:** Generated a fresh SPEF from the latest routed database (`5_2_route_fresh.spef`) and used it in every STA run.

**Outcome:** The typical-corner report corresponds to the latest route.

### 10.3 Repeating STA across 16 corners

**Challenge:** Running timing by hand for many Liberty corners is slow and error-prone, and hard to compare.

**Approach:** Wrote a Tcl script driven by a shell loop (Figure 18) that saves a log per corner and collects results into `summary.csv` (Figure 19).

**Outcome:** All 16 corners ran and produced comparable numbers. The sweep exposed six setup-negative corners.

### 10.4 Reading "OK" as "timing passed"

**Challenge:** The run status printed `OK` / `PASS` for every corner, which is easy to mistake for a timing pass.

**Approach:** Read worst setup slack, worst hold slack, and TNS for each corner and judged the numbers rather than the exit status.

**Outcome:** The write-up separates "analysis completed" from "timing met". Six corners remain setup-negative.

### 10.5 Duplicate rows in the summary

**Challenge:** `summary.csv` reported 32 corner logs, with each corner appearing twice.

**Approach:** Checked that the duplicate rows have identical values and trace to two log files per corner.

**Outcome:** The results are reported as 16 unique corners.

### 10.6 Routing DRC violations

**Challenge:** The VSDBABYSOC detailed-route output contained 28 Metal 1 shorts.

**Approach:** Inspected the route log and DRC report to find the violation type and the affected DAC-area nets.

**Outcome:** The issue is located and documented, but the evidence does not show it was eliminated, so no DRC-clean claim is made.

### 10.7 Library-set scope

**Challenge:** The corner libraries came from a different repository than the three-part Liberty set inside the VSDBABYSOC repo's `timing/` folder.

**Approach:** Recorded the exact source of the 16 corner files and stated that the repo's own Liberty set was not used for the sweep.

**Outcome:** Method and limits are stated, and the result is not presented as full multi-corner characterization of the macros.

### 10.8 Mixed evidence from two designs

**Challenge:** The step-by-step flow screenshots were captured on the bundled `nangate45/gcd` design, while the sign-off-style analysis is on VSDBABYSOC.

**Approach:** Added the evidence map in section 2 and labelled each figure with its design.

**Outcome:** No `gcd` number is presented as a VSDBABYSOC number.

## 11. Supporting documents

- [`vsdbabysoc_post_route_sta_report.pdf`](./vsdbabysoc_post_route_sta_report.pdf): full post-route STA report with all 16 corners at full precision, the unconstrained-pin note, and the routing and sign-off caveats.
- [`vsdbabysoc_post_route_sta_report.docx`](./vsdbabysoc_post_route_sta_report.docx): editable version of the same report.

## 12. Conclusion

This week connected the major stages of an RTL-to-layout flow, with a stage-by-stage walkthrough on the `nangate45/gcd` reference design and a post-route multi-corner timing analysis of VSDBABYSOC on SKY130HD.

The flow and all 16 corner runs completed. The analysis also exposed real concerns: six corners with negative setup slack (worst −29.21 ns at ss_n40C_1v28), 28 recorded Metal 1 shorts near the DAC, and unconstrained pins that positive slack numbers do not cover. These are open engineering tasks. They are not hidden by the fact that the tools ran to completion.

The main skills gained were validating each checkpoint against its own report, keeping routed database, constraints, SPEF, and Liberty files consistent, automating a corner sweep, and reporting the results as they are.
