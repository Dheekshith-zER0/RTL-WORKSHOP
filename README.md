# Week 1 – RTL Design, Simulation and Introduction to Yosys

This week was mainly a revision and hands-on run-through of the basic RTL design and synthesis flow. Going through the videos and repeating the lab exercises myself helped me connect concepts I'd studied before with their actual implementation using the VSD tools — from setting up the workshop VM, to running simulations on the provided RTL, to seeing a design get synthesized down to standard cells.

---

## 1. Environment Setup

Started by logging into the VSDSquadron workshop VM (Oracle VirtualBox) and getting the toolchain ready — Icarus Verilog, GTKWave, and Yosys.

<p align="center">
  <img src="images/vm_login.jpg" width="600" alt="VSDSquadron workshop VM login"/>
</p>

---

## 2. Repository & Library Setup

Cloned the `vsd-rtl` workshop repo and worked through its folder structure (`my_lib`, `lib`, `verilog_files`) to locate the SKY130 standard-cell library and the Verilog primitive models needed later for synthesis.

<p align="center">
  <img src="images/lib_setup_terminal.jpg" width="600" alt="Cloning vsd-rtl and navigating the library folders"/>
</p>

Also had to install `iverilog` on the VM before I could compile anything — a good reminder that the simulator isn't bundled by default.

<p align="center">
  <img src="images/iverilog_install.jpg" width="600" alt="Installing Icarus Verilog"/>
</p>

---

## 3. Design, Testbench and Simulator Basics

Revised the basic concepts of a **design database**, and how a **design** (the Verilog description of the circuit) and a **testbench** (which drives it with stimulus and checks the outputs) come together:

```text
Design
   +
Testbench
   ↓
Simulator
   ↓
Simulation Results
```

Worked with **Icarus Verilog** as the simulator — compiling the design and testbench together, then running the resulting executable to produce a `.vcd` file.

```bash
iverilog <design>.v <testbench>.v
./a.out
gtkwave <testbench>.vcd
```

---

## 4. RTL Simulation — `good_counter`

Picked the `good_counter` module from `verilog_files/` as the hands-on example: a 2-bit up-counter with a synchronous reset and a comparator (`comp`) that rolls it back to `00` once it hits `10`.

<p align="center">
  <img src="images/good_counter_code.jpg" width="600" alt="good_counter.v and tb_good_counter.v"/>
</p>

Simulated it and opened the resulting `tb_good_counter.vcd` in **GTKWave** to actually watch `clk`, `reset`, `cnt[1:0]` and `comp` change over time instead of just reading terminal output.

<p align="center">
  <img src="images/gtkwave_output.jpg" width="600" alt="GTKWave waveform of tb_good_counter"/>
</p>

This made it clear how the RTL description, testbench, simulator, VCD file and waveform viewer all fit together as one pipeline rather than separate tools.

---

## 5. Introduction to Yosys and Synthesis

Learned that simulation and synthesis answer different questions — simulation asks *"does my RTL behave correctly?"*, synthesis asks *"how can this RTL become actual hardware logic?"*

```text
RTL Design → Yosys → Generic Logic → Technology Mapping → Standard Cells → Gate-Level Netlist
```

Loaded the SKY130 standard-cell **Liberty (`.lib`)** file into Yosys, which describes the available cells (AND, NAND, inverters, buffers, muxes, flip-flops) and their timing behavior:

```bash
read_liberty -lib <library>.lib
read_verilog <design>.v
synth -top <top_module>
dfflibmap -liberty <library>.lib
```

Also ran into a clock-gating cell while loading the library and learned it's described differently from a normal Boolean `function` cell.

---

## 6. Synchronous vs Asynchronous Reset

Studied how reset behavior differs between the two flip-flop types:

- **Synchronous reset** — only takes effect on the active clock edge. Conceptually a mux selecting between `D` and `0`, controlled by `RESET`, feeding a DFF: `Y = ~RESET · D`.
- **Asynchronous reset** — takes effect immediately, independent of the clock edge.

Connecting this back to the RTL (`if(reset) cnt <= 0;` inside a clocked `always` block) helped tie the description to the actual hardware behavior.

---

## 7. Overall Takeaway & Contribution

```text
RTL Design → Testbench → Icarus Verilog → VCD File → GTKWave → Functional Check
    → Yosys → RTL Synthesis → Standard Cell Mapping → Gate-Level Netlist
```

Before this week, most of these were separate definitions. Actually setting up the VM, running the simulation, watching the waveform, and pushing the same design through Yosys made it click as one connected RTL-to-gate-level flow.

**Contributor / Git Blame:**

| File | Author | Commit |
|---|---|---|
| All files in this repo | `Dheekshith-zER0` | `37a8564` — "Week 1 RTL design and synthesis work" |

All RTL files, the synthesized netlist, and the captured VCD are kept in [`verilog_files/`](./verilog_files) as evidence of the work, alongside this README documenting what was actually learned from them.
