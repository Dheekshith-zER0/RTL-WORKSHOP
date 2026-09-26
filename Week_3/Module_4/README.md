# Module 4 – Pre-Layout Timing Analysis and Clock Tree Synthesis

## Overview

This module moves from physical cells to timing-aware physical design. It covers timing libraries, Liberty delay tables, LEF and routing information, SDC constraints, OpenSTA, setup/hold analysis, clock uncertainty, and clock tree synthesis (CTS).

## 1. Timing as a Physical-Design Constraint

A design can be logically correct and still fail timing. Physical implementation changes:

- wire delay
- cell delay
- clock latency
- clock skew
- setup and hold margins

Static Timing Analysis (STA) evaluates these relationships without requiring exhaustive simulation of every input sequence.

## 2. Timing Libraries and Delay Tables

Liberty timing libraries contain characterized information about standard cells, including:

- input capacitance
- timing arcs
- cell delay
- transition behaviour
- setup and hold constraints
- power information

Delay tables model how cell delay and output transition vary with input slew and output load.

## 3. LEF, Tracks and Physical Cell Information

LEF files describe physical information needed by place-and-route tools, including:

- cell dimensions
- pin locations
- routing layers
- obstruction information
- manufacturing-grid data
- routing tracks

Logical timing data and physical information must agree for meaningful implementation.

## 4. SDC Constraints and Clock Definition

Synopsys Design Constraints (SDC) define the timing environment. Typical constraints include:

- clock period
- clock waveform
- input/output delays
- clock uncertainty
- timing exceptions

A representative clock constraint is conceptually:

`create_clock -period T -name clk [get_ports clk]`

<img src="https://raw.githubusercontent.com/afraajabeen-creator/RTL_Design_Workshop/main/PD_MODULE_4/images/delay%20tables.png" width="700" alt="Liberty delay tables"/>

## 5. Pre-Layout STA Using OpenSTA

OpenSTA can analyse the design before detailed physical implementation. A typical flow loads:

1. standard-cell Liberty files
2. synthesized netlist
3. SDC constraints
4. timing corners

The reports identify critical paths, arrival times, required times and slack.

<img src="https://raw.githubusercontent.com/Sangathram/RTL_Workshop/main/Physical_Design_PD/Module%204/Images/OpenSTA_Prelayout_Timing_Analysis.png" width="700" alt="OpenSTA pre-layout timing analysis"/>

## 6. Setup and Hold

For setup timing, data must reach the receiving flip-flop before the active clock edge with sufficient margin.

For hold timing, data must remain stable for the required interval after the active edge.

A simplified setup relationship is:

**Data arrival + setup time ≤ required arrival time**

Slack is the difference between the required and actual arrival times.

## 7. Clock Jitter and Uncertainty

The clock seen by different sequential elements is affected by variation and implementation effects. Clock uncertainty is used to reserve timing margin for effects such as jitter and modelling uncertainty.

<img src="https://raw.githubusercontent.com/afraajabeen-creator/RTL_Design_Workshop/main/PD_MODULE_4/images/setup%20timing%20analysis(with%20ideal%20clock).png" width="700" alt="Setup timing analysis"/>

## 8. Clock Tree Synthesis

CTS constructs a clock distribution network between the clock source and sequential endpoints.

The objectives include:

- controlled clock skew
- acceptable insertion delay
- balanced clock distribution
- manageable buffering
- signal integrity
- power-aware clock distribution

## 9. H-Tree Distribution and Clock Integrity

An H-tree is a balanced clock-distribution topology that can provide geometrically similar paths to groups of endpoints. Practical clock networks may combine topology, buffers and routing strategies to satisfy skew and latency requirements.

## 10. CTS Implementation

A CTS script configures the clock-tree construction process, including clock buffers and implementation parameters.

<img src="https://raw.githubusercontent.com/Sangathram/RTL_Workshop/main/Physical_Design_PD/Module%204/Images/Create_clock.png" width="700" alt="Clock creation"/>

## 11. Ideal Clock vs Real Clock

Before CTS, clocks are often treated as ideal for early timing analysis. After CTS, the clock network has physical latency and skew.

Therefore timing analysis must account for the actual clock propagation through the implemented tree.

## 12. Timing Impact of CTS

CTS can change both setup and hold timing because clock arrival times are no longer identical. Timing must therefore be re-evaluated after clock-tree construction and subsequent optimization.

## 13. Practical Flow

1. Load Liberty timing libraries.
2. Load LEF and physical information.
3. Define clocks and timing constraints with SDC.
4. Run pre-layout STA.
5. Identify critical paths.
6. Build the clock tree.
7. Analyse skew and insertion delay.
8. Re-run timing with the implemented clock network.
9. Optimize remaining timing violations.

![Clock jitter](https://raw.githubusercontent.com/Sohail123-spec/RTL_Design_Workshop/main/Physical_Design/Module%204/Images/Jitter_Variation.png)

## Key Takeaways

- Liberty describes characterized timing behaviour of standard cells.
- LEF provides physical information required by implementation tools.
- SDC defines the timing environment.
- OpenSTA performs static timing analysis.
- Setup, hold, skew, latency and uncertainty are central timing concepts.
- CTS transforms an ideal clock into a physically distributed clock network.

### Tools and Technologies

`OpenSTA` · `TritonCTS` · `Liberty` · `LEF` · `SDC` · `Magic` · `Sky130` · `OpenROAD` · `OpenLane`
