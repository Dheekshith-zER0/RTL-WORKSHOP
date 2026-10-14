# Week 4 — VSDBABYSOC: RTL-to-Physical-Design Flow and Multi-Corner STA

## 1. Objective

This week documents the practical implementation and analysis of VSDBABYSOC using OpenROAD-flow-scripts. The work progressed from establishing a browser-based Codespace environment through synthesis, physical implementation, parasitic extraction, and static timing analysis (STA). Results and learning are presented before problems and resolutions.

## 2. Environment and design setup

The work was carried out in GitHub Codespaces using the OpenROAD-flow-scripts flow directory and SKY130HD platform, targeting the VSDBABYSOC design. The environment and tool versions were checked, flow scripts and configuration inspected, and generated logs, results, and reports reviewed.

## 3. Synthesis

Synthesis translated the configured RTL into a gate-level representation using the selected standard-cell library. Use the synthesis statistics screenshot to report the visible metrics; do not infer values that are not legible in the evidence.

## 4. Physical implementation

The implementation checkpoints covered floorplanning, placement, clock-tree synthesis (CTS), global routing, detailed routing, metal fill, GDS-related checks, and final layout inspection. A completed stage or final layout image does not itself prove that all timing and design-rule checks passed.

## 5. Parasitic extraction

Fresh parasitic data was extracted from the latest routed database and used for post-route timing analysis. This avoided relying on stale final-stage files that might not match the latest route. The routed database, SDC constraints, SPEF, and Liberty models should refer to a consistent run.

## 6. Static timing analysis

### 6.1 Typical-corner post-route result

- Clock period: **11.00 ns**
- Worst setup slack: **6.13 ns**
- Worst hold slack: **0.32 ns**
- WNS: **0.00 ns**
- TNS: **0.00 ns**

These values are from the recorded typical-corner run with fresh parasitics.

### 6.2 Sixteen-corner experiment

STA was run against 16 standard-cell Liberty corner files from the separate `skywater-pdk-libs-sky130_fd_sc_hd/timing/` directory. The script loaded one standard-cell corner at a time along with the VSDBABYSOC DAC and PLL Liberty models, routed database, flow SDC, and fresh SPEF.

**Library scope:** The 16-corner experiment used the separate SKY130 standard-cell library repository. It did **not** use the three-part Liberty files from the timing folder of the VSDBABYSOC repository itself. DAC and PLL models were loaded separately; this should not be represented as full multi-corner characterization of those macros.

| Corner | Worst setup slack (ns) | Worst hold slack (ns) | Setup assessment |
|---|---:|---:|---|
| ff_100C_1v65 | 7.22 | 0.26 | Positive |
| ff_100C_1v95 | 8.07 | 0.20 | Positive |
| ff_n40C_1v56 | 5.99 | 0.30 | Positive |
| ff_n40C_1v65 | 6.72 | 0.26 | Positive |
| ff_n40C_1v76 | 7.36 | 0.23 | Positive |
| ff_n40C_1v95 | 8.07 | 0.20 | Positive |
| ss_100C_1v40 | -3.55 | 0.92 | Negative |
| ss_100C_1v60 | 1.24 | 0.65 | Positive |
| ss_n40C_1v28 | -29.21 | 1.80 | Negative |
| ss_n40C_1v35 | -16.31 | 1.34 | Negative |
| ss_n40C_1v40 | -10.87 | 1.12 | Negative |
| ss_n40C_1v44 | -7.69 | 0.99 | Negative |
| ss_n40C_1v60 | -0.45 | 0.67 | Negative |
| ss_n40C_1v76 | 2.91 | 0.50 | Positive |
| tt_025C_1v80 | 6.13 | 0.32 | Positive |
| tt_100C_1v80 | 6.22 | 0.32 | Positive |

All 16 scripts completed at the tool-execution level. Six corners nevertheless had negative setup slack, with the worst reported value approximately −29.21 ns at ss_n40C_1v28. Successful execution is not equivalent to timing closure. Values are rounded from recorded outputs.

## 7. Results and observations

The recorded detailed-route results included **28 reported DRC violations**, identified as Metal 1 shorts; no antenna net/pin violations were reported in the inspected route log. Approximate routed wire length was **227,853 µm**, via count was **50,026**, and reported utilization was **19%**.

The DRC report identified shorts around the DAC-related area/nets. The evidence does not establish that all 28 violations were subsequently removed, so the design must not be described as DRC-clean. Typical-corner positive slack and six slow-corner setup failures are different findings and should be presented together.

## 8. Technical learnings

1. The flow consists of distinct checkpoints: synthesis, floorplanning, placement, CTS, routing, extraction, and STA; each answers different questions.
2. Logs and reports matter as much as a layout image. A visually complete layout is not proof of timing closure or DRC cleanliness.
3. Routed database, constraints, SPEF, and Liberty models must be consistent for meaningful post-route STA.
4. A positive typical-corner slack does not guarantee positive slack at every process, voltage, and temperature corner.
5. Tool execution status and design timing status are different: scripts can finish while timing violations remain.
6. Library provenance must be explicit. The 16 standard-cell corners came from a separate SKY130 library repository, not the VSDBABYSOC repository's three-part timing Liberty set.
7. Physical-design sign-off is multidimensional: timing, DRC, parasitic extraction, and final layout checks must be evaluated separately.

## 9. Problems faced and how we addressed them

The workflow and tooling obstacles below were worked through sufficiently to complete the implementation and analysis runs. This does not mean every underlying design-quality issue was eliminated.

### 9.1 Environment and flow navigation

**Challenge:** Establishing the Codespace environment and locating the correct flow, design, configuration, and report paths.

**How we addressed it:** Checked the environment and tool versions, navigated to the OpenROAD-flow-scripts flow directory, and inspected relevant design/platform files and generated outputs.

**Outcome:** We were able to run the flow and inspect its artifacts.

### 9.2 Consistency of post-route timing inputs

**Challenge:** Older final-stage files could be stale relative to the latest routed database, risking a mismatch between layout and timing evidence.

**How we addressed it:** Generated fresh SPEF data from the latest routed database and used it for the documented post-route STA run.

**Outcome:** The typical-corner report used fresh parasitics corresponding to the latest routed database.

### 9.3 Repeating STA across multiple corners

**Challenge:** Manually repeating timing analysis across many library corners would be error-prone and hard to compare.

**How we addressed it:** Automated the run with a Tcl script and shell loop, saving per-corner logs and outputs.

**Outcome:** All 16 runs completed, and the results exposed six corners with negative setup slack. This was a timing finding, not a script failure.

### 9.4 Interpreting timing status

**Challenge:** A run marked OK could be mistaken for a timing pass.

**How we addressed it:** Extracted worst setup slack, worst hold slack, and TNS for each corner and evaluated the numeric results instead of relying only on process exit status.

**Outcome:** The report distinguishes successful execution from timing compliance. Six corners remain setup-negative in the recorded experiment.

### 9.5 Routing DRC violations

**Challenge:** The detailed-route report contained 28 reported Metal 1 shorts.

**How we addressed it:** Inspected the route log and DRC report to identify the violation category and affected DAC-area nets.

**Outcome:** The issue was localized for investigation and documented. The available evidence does not prove that all shorts were eliminated; therefore, no clean-DRC claim is made.

### 9.6 Library-set scope

**Challenge:** The standard-cell libraries used in the corner sweep differed from the three-part Liberty set in the VSDBABYSOC repository's timing folder.

**How we addressed it:** Recorded the exact source and scope of the 16 standard-cell corner files and stated that the repository's three-part timing Liberty files were not used in this experiment.

**Outcome:** The methodology and its limitations are explicit, and the result is not misrepresented as a complete multi-corner analysis of every macro.

## 10. Screenshot evidence

Keep screenshots in this week's `images/` directory and embed each near the stage it demonstrates. Suggested descriptive names: `01_codespace_setup.png`, `02_terminal_flow.png`, `03_tool_versions.png`, `04_synthesis_stats.png`, `05_floorplan.png`, `06_placement.png`, `07_clock_tree_synthesis.png`, `08_global_routing.png`, `09_detailed_routing.png`, `10_metal_fill.png`, `11_design_metrics.png`, `12_gds_check.png`, `13_timing_reports.png`, and `14_final_layout.png`. Add the multi-corner summary and DRC report screenshots where available.

## 11. Conclusion

This exercise connected the major stages of an RTL-to-physical-design workflow and produced synthesis, implementation, routing, parasitic-extraction, and timing-analysis evidence for VSDBABYSOC. The key achievement was learning to validate checkpoints with the appropriate reports, keep analysis inputs consistent, automate multi-corner STA, and interpret results honestly.

The recorded workflow and 16-corner analysis completed, while exposing sign-off concerns: 28 reported routing DRC violations and negative setup slack at six corners. These remain engineering tasks rather than being hidden by successful tool execution.