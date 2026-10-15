# Final Submission Video Script — RTL Design and Physical Design Workshop

**Target length:** 5–6 minutes at a calm pace (roughly 700–780 spoken words)  
**Style:** humble, conversational, evidence-led. Do not read every file or claim that unresolved timing/DRC issues were fixed.

## Navigation plan (follow this order on screen)

1. Start at the **Week 4 STA graphs** — a result-first hook.
2. Jump back to **Week 1** — show where the flow began.
3. Move to **Week 2** — show how coding style and verification affect correctness.
4. Open **Week 3, Modules 1–5** — move from the ASIC flow concept to layout, timing and routing.
5. Visit the **VSDBabySoC lab** and **Assignments 1–2** — show the bridge from RTL/GLS to measured timing.
6. Return to **Week 4** — finish with the complete implementation stages, results, limitations and lessons.
7. End at the root README and the two Week 4 graphs.

This is intentionally not a folder-by-folder recital. The return to Week 4 ties the earlier concepts together.

---

## 0:00–0:30 — Open with the result

**On screen:** Open `Week_4_VSDBABYSOC/README.md`, scroll to “WNS and TNS by Liberty Corner,” and show both graphs.

**Say:**

“Hello, this is my final walkthrough of the RTL Design and Synthesis Workshop. Rather than reading the repository in folder order, I’ll start with the result that connects several weeks of learning: the post-route timing analysis of VSDBABYSOC. These two graphs compare worst setup slack and total negative slack across 16 SKY130HD standard-cell library corners. They show why checking one typical corner is not enough. I’ll briefly trace how I reached this point, then return to the full flow and the lessons from the results.”

## 0:30–1:10 — Week 1: establish the RTL-to-netlist foundation

**On screen:** Open `Week_1_RTL/README.md`; briefly show the `verilog_files` folder, `good_counter` example and GTKWave screenshot.

**Say:**

“I started with the basic RTL workflow. I used Icarus Verilog to compile a design with its testbench, ran the simulation, and inspected the VCD waveform in GTKWave. The good-counter example helped me connect clock and reset behavior to the waveform instead of relying only on source code. I then introduced Yosys and the SKY130 Liberty library to see how RTL is synthesized and mapped to standard cells. One important distinction was that simulation checks behavior, while synthesis translates the description into hardware.”

## 1:10–1:50 — Week 2: correctness depends on coding and verification

**On screen:** Open `Week_2_RTL/README.md`; show the bad-mux RTL/GLS comparison, an inferred-latch example, and the generate/RCA section.

**Say:**

“In Week 2, I looked at what can go wrong between RTL and synthesized logic. A missing sensitivity-list signal can cause an RTL simulation to disagree with the synthesized netlist. I compared RTL and gate-level simulation waveforms, reviewed why non-blocking assignments are appropriate for sequential logic, and saw how incomplete if or case statements can infer unintended latches. I also looked at generate constructs and a ripple-carry adder. The main lesson was to verify the hardware implied by the code, not just whether the code compiles.”

## 1:50–2:40 — Week 3: connect logic to physical implementation

**On screen:** Open `Week_3_Physical_Design`; briefly visit Module 1, then Modules 2–5 by their headings and selected diagrams.

**Say:**

“Week 3 moved from digital logic toward physical design. Module 1 introduced the open-source ASIC ecosystem, the PDK, OpenLane and the RTL-to-GDSII flow. Module 2 covered die and core area, utilization, aspect ratio, standard cells, decoupling capacitors and power planning. Module 3 connected transistor behavior and CMOS inverter characterization with ngspice to physical standard-cell layout, Magic, extraction and design-rule checking. Module 4 covered Liberty timing data, LEF, SDC constraints, setup and hold, clock uncertainty and clock-tree synthesis. Module 5 covered the difference between global and detailed routing, vias, routing rules and DRC. Together, these modules explained why a logically correct netlist still needs timing and physical checks.”

## 2:40–3:35 — BabySoC lab and Assignment 1: verify function

**On screen:** Visit `LABS_Baby_SOC/LABS_Baby_SOC/README.md`, then `Assignments/Assignments/Assignment_1_Sequence_Detector/README.md`. Show the BabySoC block diagram and one sequence-detector waveform or synthesis statistic.

**Say:**

“The BabySoC lab connected a PLL, the RVMYTH processor and a DAC. I compared pre-synthesis RTL simulation with post-synthesis functional gate-level simulation, using the same testbench and examining the processor-to-DAC bus and output waveform. The matching behavior was useful evidence that synthesis preserved the observed function, although functional GLS alone does not prove timing closure.

“In Assignment 1, I applied the same idea to a seven-bit sequence detector for the pattern zero-zero-one-zero-zero-one-zero. I examined its finite-state-machine behavior, tested overlapping detections, synthesized it with Yosys and compared RTL with gate-level results. I also noted that synthesis recoded the state machine to one-hot form in the reported netlist.”

## 3:35–4:15 — Assignment 2: why multiple corners matter

**On screen:** Open `Assignments/Assignments/Assignment_2_Multi_Corner_STA/README.md`; show the PVT explanation, results table and existing WNS/TNS plots.

**Say:**

“Assignment 2 introduced static timing analysis across process, voltage and temperature corners. Slack is required time minus arrival time. WNS shows the worst path, while TNS shows the sum of negative slack across violating endpoints. In this assessment, the slow-slow corners showed negative slack while the fast-fast and typical corners in the plotted set reported zero negative slack. The important lesson was that a typical-corner result can hide failures elsewhere. This assignment used the synthesized netlist and its constraints, so its numbers should not be treated as the same experiment as Week 4’s post-route analysis.”

## 4:15–5:25 — Return to Week 4: full implementation and post-route STA

**On screen:** In `Week_4_VSDBABYSOC/README.md`, scroll through the flow diagram, implementation screenshots, SPEF inputs, corner table and graphs.

**Say:**

“Week 4 brought the physical-design stages together. I used a GitHub Codespace running OpenROAD-flow-scripts and documented synthesis, floorplanning, placement, clock-tree synthesis, global routing, detailed routing, fill and the available final database checkpoints. The stage-by-stage walkthrough uses the ORFS gcd reference design on Nangate45; the multi-corner post-route timing experiment is on VSDBABYSOC using SKY130HD. These are separate parts of the work, so I’ve kept that distinction clear.

“For the VSDBABYSOC timing runs, I used the routed database, SDC constraints and a freshly extracted SPEF so the timing analysis included route parasitics. I swept 16 unique standard-cell Liberty corners from the separate SKY130HD library repository, while keeping the DAC and PLL macro timing libraries unchanged. The two graphs summarize the resulting WNS and setup TNS.

“At the typical corner, the reported setup slack was 6.13 nanoseconds and hold slack was 0.32 nanoseconds. However, six corners had negative setup slack. The worst was minus 29.21 nanoseconds at ss-n40C-1v28, with setup TNS of minus 14,131.26 nanoseconds. The route report also recorded 28 Metal 1 short violations near the DAC area, and the analysis noted unconstrained pins. I have documented these as unresolved limitations rather than describing the run as timing-clean or DRC-clean.”

## 5:25–5:55 — Close with learning, not a claim of perfection

**On screen:** Show the “Results and Observations,” “Technical Learnings,” and “Problems Faced and How I Addressed Them” sections, then return to the root README.

**Say:**

“My main learning is that each stage answers a different question: simulation checks behavior, synthesis maps logic, physical design creates the layout, and post-route STA checks timing with extracted parasitics. I also learned to distinguish a script completing successfully from a design meeting timing, to check library provenance, and to report limitations honestly. The repository contains the weekly notes, lab evidence, assignment reports, screenshots and the detailed Week 4 analysis. Thank you for reviewing my work.”

---

## Recording reminders

- Aim for a steady pace; rehearse once with a timer and trim pauses rather than rushing.
- Keep the browser zoom high enough that folder names, tables and graph labels are readable.
- Use the README headings as navigation cues; do not open every screenshot individually.
- Keep your face camera in a small, adjustable corner overlay, but move it away from the graphs and tables.
- Do not claim all DRC violations or setup failures were fixed. The repository records them as unresolved.
- If short on time, shorten Week 3 definitions first; preserve the Week 4 methodology, results and limitations.
