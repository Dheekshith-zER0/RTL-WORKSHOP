# Final Submission — Complete Repository Walkthrough and Learning Summary

This document is the extended companion to [the 5–6 minute video script](./FINAL_SUBMISSION_VIDEO_SCRIPT.md). It explains the repository's progression, the purpose of the main folders, the key technical concepts, the experiments and the limitations that should be represented accurately in the final submission.

The video deliberately follows a result-first route. This document follows the technical progression so it can also serve as a longer reference.

## 1. Repository map

| Path | Purpose |
|---|---|
| [Week 1 — RTL](./Week_1_RTL) | RTL, testbenches, Icarus Verilog, GTKWave and introductory Yosys synthesis |
| [Week 2 — RTL](./Week_2_RTL) | Logic optimization, GLS, coding pitfalls, inferred latches, generate constructs and RCA |
| [Week 3 — Physical Design](./Week_3_Physical_Design) | Five modules covering the open-source ASIC flow, floorplanning, cell characterization/layout, timing/CTS, routing and DRC |
| [Week 4 — VSDBABYSOC](./Week_4_VSDBABYSOC) | ORFS stage-by-stage flow evidence, post-route SPEF and 16-corner STA |
| [BabySoC lab](./LABS_Baby_SOC) | PLL → RVMYTH → DAC; RTL simulation, Yosys synthesis and functional GLS |
| [Assignments](./Assignments) | Sequence-detector RTL-to-GLS assessment, multi-corner STA assessment, and a link to the Week 4 physical-design work |

The main story is a progression from describing digital behavior, to checking synthesized logic, to understanding physical implementation, and finally to timing analysis using physical parasitics.

---

## 2. Week 1 — RTL, simulation and introductory synthesis

**Main file:** [Week_1_RTL/README.md](./Week_1_RTL/README.md)

### Work represented in the folder

- Setup and use of the VSDSquadron workshop VM, with Icarus Verilog, GTKWave and Yosys.
- Navigation of the workshop repository and its Verilog and SKY130 library files.
- Design/testbench/simulator relationship: the testbench supplies stimulus, the simulator executes the RTL, and a VCD file records signal changes for waveform inspection.
- Simulation of the `good_counter` example, a 2-bit counter with synchronous reset and comparator-based behavior.
- Introduction to Yosys and the transformation from RTL through logic optimization and technology mapping to a gate-level netlist.
- Introduction to Liberty files, which describe standard cells and their characterized timing information.
- Comparison of synchronous reset, which takes effect at an active clock edge, with asynchronous reset, which can take effect independently of that edge.

### Concepts to be able to explain

**RTL simulation:** asks whether the modeled design behaves as expected for the stimulus applied by the testbench. A waveform is evidence of that behavior for the tested scenario, not a proof of all possible scenarios.

**Synthesis:** translates the behavioral/structural description into logic and maps that logic to cells supported by a target library. The resulting netlist is structurally different from the RTL.

**VCD and GTKWave:** the simulator produces the Value Change Dump file; GTKWave displays the signal history so the relationship between clock, reset, input and output can be inspected.

**Liberty:** timing and electrical characterization of available cells, distinct from the RTL itself.

### Takeaway

The first week establishes the basic path:

`RTL + testbench → Icarus Verilog → VCD/GTKWave → Yosys → gate-level netlist`

---

## 3. Week 2 — Optimization, GLS and coding pitfalls

**Main file:** [Week_2_RTL/README.md](./Week_2_RTL/README.md)

### Combinational and sequential optimization

The notes cover constant propagation and Boolean simplification for combinational logic, plus sequential constant propagation, state optimization, cloning and retiming.

- **Constant propagation:** known values can make downstream logic redundant.
- **Boolean optimization:** equivalent expressions can be simplified without changing their logic function.
- **State optimization:** redundant state-machine states can be reduced.
- **Cloning:** duplicating a high-fanout register can help with timing or routing.
- **Retiming:** moving registers across combinational logic can rebalance path delays while preserving overall behavior.

The counter and DFF examples provide concrete cases for seeing optimization in a synthesized result.

### Gate-level simulation and mismatch

GLS runs the testbench against the synthesized netlist rather than the original RTL. Functional or zero-delay GLS focuses on logic behavior; timing-annotated GLS incorporates cell/interconnect delay information.

The Week 2 examples demonstrate why RTL and synthesized logic can disagree when the source code does not describe combinational or sequential intent correctly.

- **Missing sensitivity-list signals:** in a manually specified combinational sensitivity list, omitting a signal can prevent RTL simulation from updating when that signal changes. A complete sensitivity list or an `always_comb` construct in a supported language flow helps avoid this class of problem; a continuous assignment is also suitable for simple combinational expressions.
- **Blocking (`=`) versus non-blocking (`<=`):** blocking assignments execute in statement order. Non-blocking assignments schedule updates together, which corresponds more closely to simultaneous register updates in clocked logic. Non-blocking assignments are the usual choice for sequential logic.
- **Incomplete if/case statements:** if a combinational output is not assigned on every possible path, the tool may infer a latch to preserve its previous value. That memory behavior is usually unintended in combinational logic.

### Generate constructs and ripple-carry adder

Generate/for constructs express repeated structures without manually writing every instance. The ripple-carry adder chains full adders, passing each carry-out to the next stage's carry-in. This is straightforward structurally, though carry propagation can become a timing bottleneck as width increases.

### Takeaway

Simulation success alone is not enough: coding style affects inferred hardware, and GLS comparisons help verify that synthesis preserves the intended behavior.

---

## 4. Week 3 — Physical-design concepts across five modules

**Folder:** [Week_3_Physical_Design](./Week_3_Physical_Design)

### Module 1 — Open-source EDA, OpenLane and RTL-to-GDSII

**File:** [Module 1 README](./Week_3_Physical_Design/Module_1/README.md)

This module introduces the ASIC ecosystem: RTL/IP, EDA tools, the PDK and the foundry. It uses a RISC-V core example and explains that a PDK contains process-specific information such as standard-cell libraries, timing data, physical abstracts, device models and design rules.

The flow includes synthesis, floorplanning and power planning, placement, CTS, routing, parasitic extraction, timing analysis, physical verification and GDSII generation. The notes distinguish logical equivalence from physical checks: DRC checks geometry against manufacturing rules, while LVS checks layout connectivity against the schematic/netlist. A flow reaching a final database should not be confused with proof that every sign-off check passes or that a GDSII stream was generated.

The practical section covers a Docker-based OpenLane environment and interactive flow launch.

### Module 2 — Floorplanning and standard cells

**File:** [Module 2 README](./Week_3_Physical_Design/Module_2/README.md)

- **Die:** overall chip area.
- **Core:** the region where standard-cell logic is placed.
- **Utilization:** ratio of occupied/target core area to the relevant area measure used by the flow; interpret the exact denominator according to the tool report.
- **Aspect ratio:** height divided by width.

Low utilization may waste area; very high utilization can leave too little room for routing and create congestion. Aspect ratio also affects the distribution of wire lengths and routing resources.

A standard cell is a characterized logic building block with a defined physical footprint. A larger IP or macro is a reusable functional block. The module also covers decoupling capacitors as local charge reservoirs, supply droop/bump, power meshes, pin placement, placement legalization and repeaters/buffers for long nets.

### Module 3 — Characterization, layout, Magic and ngspice

**File:** [Module 3 README](./Week_3_Physical_Design/Module_3/README.md)

This module connects transistor-level behavior to physical layout. CMOS inverter characterization can examine the voltage-transfer characteristic, switching threshold, propagation delay, rise/fall time and transient response. The fabrication sequence and SKY130 layers explain how a circuit becomes physical geometry.

Magic is used to inspect/edit layout and perform checks and extraction. Extracting a layout produces an electrical representation that can be simulated; comparing extracted SPICE behavior with the original circuit is a useful verification loop. Technology files tell the layout tool how layers and manufacturing rules are represented. DRC examines rules such as width, spacing and enclosure.

### Module 4 — Timing analysis and CTS

**File:** [Module 4 README](./Week_3_Physical_Design/Module_4/README.md)

The module introduces Liberty timing data, LEF physical information and SDC timing constraints. STA checks timing paths without needing to simulate every possible input sequence.

- **Setup:** data must arrive sufficiently before the capturing clock edge.
- **Hold:** data must remain stable for the required interval after that edge.
- **Clock latency:** time taken for the clock to reach a point.
- **Skew:** difference in clock arrival times at different sequential elements.
- **Uncertainty/jitter:** timing margin that accounts for clock variation and other uncertainty.

Before CTS, an ideal clock assumption can be used for early estimates. CTS builds a real buffered clock network; the clock arrival times then have latency and skew, so timing must be checked again.

### Module 5 — Routing, DRC and physical implementation

**File:** [Module 5 README](./Week_3_Physical_Design/Module_5/README.md)

Global routing plans approximate paths and produces routing guides. Detailed routing constructs actual wire geometry and vias on the permitted metal layers. TritonRoute is associated with detailed routing in the open-source flow. The module also covers maze routing/Lee's algorithm, power distribution, route guides, connectivity between guides and routing topology.

Actual interconnect resistance and capacitance affect timing. After routing, parasitic extraction provides a more realistic basis for post-route STA. DRC checks whether the geometry follows the process rules. The practical goal is iterative: route, inspect violations, correct issues, extract parasitics and re-check timing and physical constraints.

### Takeaway from Week 3

Physical design is not simply drawing the circuit. It must balance area, power delivery, routability, clock distribution, parasitics, timing and manufacturing rules.

---

## 5. BabySoC lab — RTL through functional GLS

**Primary detailed file:** [LABS_Baby_SOC/LABS_Baby_SOC/README.md](./LABS_Baby_SOC/LABS_Baby_SOC/README.md)  
**Short overview:** [LABS_Baby_SOC/README.md](./LABS_Baby_SOC/README.md)

The documented design connects three main blocks:

- **AVSDPLL (`pll`):** generates the processor clock.
- **RVMYTH (`core`):** processor core that drives the 10-bit `RV_TO_DAC[9:0]` bus.
- **AVSDDAC (`dac`):** converts the digital bus into the output `OUT`.

The sequence is pre-synthesis RTL simulation, Yosys synthesis, then post-synthesis functional GLS using the mapped netlist and standard-cell Verilog models. The same testbench and time window make waveform comparison useful. The documented ramp on `RV_TO_DAC` and the pulses on `OUT` match between the two runs.

The notes also flag `ENb_CP` as unknown (`x`) in both waveforms. Matching an unknown signal in both runs is not evidence that the signal is known or correct; it is an observation worth recording.

The synthesis notes distinguish `dfflibmap` (sequential-cell mapping) from `abc` (combinational logic mapping). They also note that synthesis can simplify or remove structures such as a clock-gating module if its control inputs do not affect the logic in the elaborated model.

**Limit:** the documented GLS is functional/unit-delay-oriented, not a full SDF timing simulation. Matching functional waveforms do not prove setup/hold closure.

---

## 6. Assignment 1 — Sequence detector RTL-to-GLS

**File:** [Assignment 1 README](./Assignments/Assignments/Assignment_1_Sequence_Detector/README.md)  
**RTL:** `src/sequence_detector.v` · **Testbench:** `src/tb.v`

The assignment implements a seven-bit serial sequence detector for `0010010`. The FSM state represents the length of the target prefix matched by the recent input history. A mismatch can return to a nonzero state when the suffix of the received bits still matches a prefix of the target; this permits overlapping matches and resembles the failure-transition idea in KMP string matching.

The documented testbench uses an 8 ns clock period and drives input bits on the falling edge so they are stable before the next rising-edge sample. The report records eight detections in the 180-bit stimulus sequence.

Yosys reports 20 total cells in the documented synthesis statistics. The RTL state is described with three bits, but the synthesized netlist shows a seven-bit one-hot state vector after FSM recoding. This is an area/speed trade-off: more state flip-flops can simplify next-state logic. The README also notes that the flip-flops remained generic Yosys cells in that particular run because library flip-flop mapping was not part of it.

The evidence includes RTL waveform, Yosys statistics, netlist/flip-flop views, GLS waveform and RTL-versus-GLS comparison. The important habit is to inspect what the tool actually produced instead of assuming the RTL encoding remains unchanged.

---

## 7. Assignment 2 — Multi-corner STA on a synthesized design

**File:** [Assignment 2 README](./Assignments/Assignments/Assignment_2_Multi_Corner_STA/README.md)

This assessment explores SKY130HD PVT (process, voltage and temperature) corners using OpenSTA. A Liberty filename identifies the characterization point; for example, `ss_n40C_1v28` denotes a slow-slow process corner at −40 °C and 1.28 V.

`Slack = Required Time − Arrival Time`

- Positive slack indicates that the analyzed path meets its timing requirement.
- Negative slack indicates a violation.
- **WNS** is the worst reported slack across the analyzed paths.
- **TNS** accumulates negative slack across violating endpoints.

The assessment README reports 18 corner entries plus a TT baseline; two assessment entries are CCS-noise variants that produced template warnings and are retained in the table but excluded from the comparison plots. The plotted set therefore contains 16 valid corners. The reported worst WNS is −62.56 ns at SS, −40 °C, 1.28 V, with TNS −13,957.60 ns. The SS results improve as voltage rises, but the cold, low-voltage SS corner remains negative even at 1.76 V. FF and TT corners in the plotted set report 0.00 ns WNS/TNS; zero means no negative slack was reported, not that the design has positive timing margin.

**Important scope distinction:** Assignment 2 analyzes the synthesized netlist with its SDC constraints. Week 4 analyzes a routed database with extracted SPEF. Their numerical results should not be compared as though they were the same run or the same physical stage.

---

## 8. Assignment 3 / Week 4 — Physical flow and post-route STA

**Main file:** [Week 4 README](./Week_4_VSDBABYSOC/README.md)  
**Full supporting report:** [PDF](./Week_4_VSDBABYSOC/vsdbabysoc_post_route_sta_report.pdf) · [DOCX](./Week_4_VSDBABYSOC/vsdbabysoc_post_route_sta_report.docx)

Week 4 contains two related but distinct experiments:

1. A stage-by-stage OpenROAD-flow-scripts walkthrough using the `gcd` reference design on `nangate45`.
2. Post-route timing analysis of `vsdbabysoc` on `sky130hd`.

### 8.1 Codespace and tool setup

The flow was run in the VSD-PD GitHub Codespace with an XFCE desktop and browser-based noVNC access. The README records the OpenROAD version as `v2.0-25794-g7cbd77e748` and describes inspecting logs, reports and intermediate databases under the ORFS flow directories.

### 8.2 Implementation checkpoints

The documented stage chain is synthesis → floorplan → placement → CTS → global route → detailed route → fill/final database. Each stage creates logs and databases that help locate where a change or issue first appears.

For the `nangate45/gcd` reference walkthrough, the README records design area/utilization progressing from approximately 708 µm² / 61% at floorplan to 850 µm² / 74% after detailed placement, 997 µm² / 86% after CTS, and 1034 µm² / 90% from global routing through fill. Added tap, clock and timing-repair cells help explain the increase. The CTS log warns that not all setup violations could be repaired; the global-route report records negative critical-path slack. The final database listing is not itself proof that a GDS file was streamed.

### 8.3 Post-route timing inputs

The VSDBABYSOC sweep used:
- Routed database: `results/sky130hd/vsdbabysoc/base/5_2_route.odb`
- Constraints: `results/sky130hd/vsdbabysoc/base/5_1_grt.sdc`
- Freshly extracted parasitics: `results/sky130hd/vsdbabysoc/base/5_2_route_fresh.spef`
- One standard-cell Liberty corner per run, sourced from the separate `skywater-pdk-libs-sky130_fd_sc_hd/timing/` repository
- The existing `avsddac.lib` and `avsdpll.lib` macro timing models, held constant across the sweep

The three-part Liberty files in the VSDBABYSOC repository's own `timing/` folder were not the source of the 16 standard-cell corners. The macro models were not swept, so this is a standard-cell corner sweep, not a full macro-and-cell characterization.

### 8.4 Results and graphs

The Week 4 README reports a clock period of 11.00 ns. At `tt_025C_1v80`, setup slack is 6.13 ns and hold slack is 0.32 ns. All 16 runs completed, but six corners have negative worst setup slack. The worst is `ss_n40C_1v28`, at −29.21 ns WNS and −14,131.26 ns setup TNS. Hold slack is positive at all recorded corners; hold TNS is 0.0 ns.

The README includes two SVG graphs:
- [WNS by Liberty corner](./Week_4_VSDBABYSOC/images/sta_wns_by_corner.svg)
- [Setup TNS by Liberty corner](./Week_4_VSDBABYSOC/images/sta_tns_by_corner.svg)

The x-axis contains the 16 unique standard-cell Liberty corners. The y-axis gives WNS or setup TNS in nanoseconds. Negative values represent setup violations. The original summary contained 32 log entries because each corner appeared in two log files with identical values; the analysis uses the 16 unique corners.

### 8.5 Routing and coverage caveats

The recorded VSDBABYSOC detailed-route output contains 28 DRC violations described as Metal 1 shorts around the DAC-related area/nets. No antenna net or pin violations were reported in the inspected log. The repository does not show evidence that the 28 shorts were subsequently fixed, so the layout must not be called DRC-clean.

The typical-corner slack does not erase the negative setup slack at six other corners. The report also records 30 unconstrained setup pins and 26 unconstrained hold pins; paths not covered by constraints cannot be validated through those slack values. The macros stayed at their existing characterization during the sweep.

### 8.6 Technical lessons

1. Each implementation stage has its own database and log; inspect the stage that produced the result.
2. Area and utilization can rise as tap cells, buffers and clock-tree cells are inserted.
3. A successful tool exit is not the same as timing closure.
4. Post-route timing depends on using a matching routed database, constraints, parasitics and libraries.
5. Setup and hold stress different operating corners; both must be checked.
6. WNS identifies the worst slack, while TNS indicates the aggregate scale of negative setup slack.
7. Unconstrained pins require separate attention.
8. Library provenance and fixed macro models define the scope of a multi-corner result.
9. A final ODB database is not the same as a generated GDSII file.
10. Unresolved DRC/timing issues should be reported accurately rather than hidden.

---

## 9. Challenges and resolutions — what can be claimed

The repository documents these challenges and responses:

- **Environment and flow navigation:** locating the ORFS `flow` directory and identifying the correct logs, reports and checkpoints by platform/design/stage.
- **Post-route input consistency:** generating a fresh SPEF from the latest routed database rather than relying on potentially stale parasitic data.
- **Repeated STA runs:** automating the 16-corner sweep with a Tcl script and shell loop, writing per-corner logs and collecting results in a summary.
- **Misreading PASS/OK:** interpreting actual WNS, hold slack and TNS rather than assuming the tool exit status meant timing passed.
- **Duplicate corner rows:** recognizing that 32 logs represented two logs per corner and reducing the comparison to 16 unique corners.
- **Library provenance:** identifying that the corner files came from a separate SKY130HD library repository.
- **Routing violations:** locating and documenting the reported Metal 1 shorts without claiming they were fixed.

The appropriate summary is that the investigation and documentation challenges were addressed, while timing and physical-design violations remain recorded limitations.

---

## 10. A short concept glossary

| Term | Meaning in this repository |
|---|---|
| RTL | Register-transfer-level description of digital behavior |
| Testbench | Code that applies stimulus and checks or observes a design |
| VCD | Value Change Dump file for signal-history inspection |
| GLS | Gate-level simulation of the synthesized netlist |
| Liberty | Standard-cell timing/electrical characterization |
| PDK | Process Design Kit: process-specific design and verification data |
| LEF | Physical abstract data used by implementation tools |
| SDC | Timing constraints, including clocks and path assumptions |
| STA | Static Timing Analysis of constrained timing paths |
| PVT | Process, voltage and temperature |
| WNS | Worst reported slack; negative indicates at least one timing violation |
| TNS | Aggregate negative slack across violating endpoints |
| Floorplan | Defines core/die organization and physical planning |
| Placement | Assigns legal physical locations to standard cells |
| CTS | Builds the clock distribution network |
| Global routing | Plans approximate routing paths and guides |
| Detailed routing | Creates actual metal geometries and vias |
| SPEF | Parasitic data for interconnect resistance/capacitance |
| DRC | Checks physical geometry against design rules |
| LVS | Checks layout connectivity against the schematic/netlist |
| ODB | OpenROAD database checkpoint |
| GDSII | Layout interchange format used for fabrication handoff |

---

## 11. Suggested final-video navigation

Use this path for a connected story rather than opening every file:

1. **Week 4 graphs:** introduce the result and the reason multi-corner timing matters.
2. **Week 1:** show a simple RTL waveform and the first synthesis step.
3. **Week 2:** show RTL/GLS comparison and an inferred-latch example.
4. **Week 3 Modules 1–5:** show the flow diagram, floorplan/power concepts, cell layout, timing/CTS and routing/DRC.
5. **BabySoC lab:** show PLL → RVMYTH → DAC and matching pre/post-synthesis functional waveforms.
6. **Assignment 1:** show the sequence detector and its verification evidence.
7. **Assignment 2:** show PVT corners and WNS/TNS results; distinguish it from the routed Week 4 analysis.
8. **Week 4 again:** show stage screenshots, routed database/SPEF inputs, corner table and the two graphs.
9. **Close:** summarize what was learned and acknowledge the unresolved timing, unconstrained-pin and routing findings.

The final video should demonstrate understanding, not claim that every physical sign-off condition was achieved.
