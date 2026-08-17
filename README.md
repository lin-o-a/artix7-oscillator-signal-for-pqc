# Artix-7 Internal Clock Isolation & Timing Closure for On-Chip Fault Injection

This repository contains the Verilog source code, XDC constraints, and Vivado implementation results for configuring an internal silicon oscillator on a Xilinx Artix-7 FPGA. This setup is designed to isolate on-chip clock domains for physical security evaluations, specifically assessing internal glitching vulnerabilities and testing defensive countermeasures against power and clock fault injection attacks on Post-Quantum Cryptography (PQC) implementations (e.g., ML-KEM).

---

## Technical Overview

When evaluating physical security countermeasures, relying on external GPIO pins or external clock lines can introduce unwanted board-level noise or external dependencies. Utilizing internal silicon oscillators allows for complete on-chip clock domain isolation. 

On the Xilinx Artix-7 target, the internal configuration ring oscillator (`CFGMCLK`) can be accessed via the `STARTUPE2` primitive. However, internal oscillator outputs require explicit global buffering and timing constraints to achieve proper timing closure in Vivado IDE.

---

## Problem: Unconstrained Internal Clocking (`TIMING-17`)

Without explicit global buffering and timing rules:
* The raw internal oscillator signal defaults to routing through general-purpose, unbuffered logic interconnects rather than dedicated low-skew clock lines.
* Vivado’s Static Timing Analyzer (STA) cannot evaluate setup/hold paths for downstream registers.
* The synthesis and implementation toolchain throws **1,006 methodology warnings**, including **998 critical `TIMING-17` warnings** (`Non-clocked sequential cell`).

Furthermore, because the design lacks a target clock frequency constraint, Vivado bypasses timing-driven placement and reverts to **cost-driven placement**, dropping logic flip-flops near physical hardware sites at the bottom of the die (`X0Y0` / `X1Y0`).

---

## Solution: Global Buffering & STA Constraint Definition

To achieve proper clock distribution across all register `.CLK` pins (including target PQC logic and the Integrated Logic Analyzer debug core):

1. **Hardware Routing (Verilog):** Route the raw configuration clock output (`CFGMCLK`) from `STARTUPE2` through a Global Clock Buffer (`BUFG`). This forces the signal onto the FPGA’s dedicated, low-skew **Global Clock Tree**.
2. **Timing Constraint (`.xdc`):** Explicitly define the primary clock period (~65 MHz / 15.385 ns) for Static Timing Analysis.

### 1. Verilog Implementation (`hdl/top.v`)

```verilog
wire raw_cfgmclk;
wire internal_clk;

// Instantiation of STARTUPE2 primitive to access the internal ~65 MHz oscillator
STARTUPE2 #(
    .PROG_USR("FALSE"),
    .SIM_CCLK_FREQ(0.0)
) startup_inst (
    .CFGMCLK(raw_cfgmclk), // Internal configuration clock output
    .CFGCLK(),
    .EOS(),
    .PREQ(),
    .CLK(1'b0),
    .GSR(1'b0),
    .GTS(1'b0),
    .KEYCLEARB(1'b1),
    .PACK(1'b0),
    .USRCCLKO(1'b0),
    .USRCCLKTS(1'b0),
    .USRDONEO(1'b1),
    .USRDONETS(1 me1'b1)
);

// Route the raw clock onto the Global Clock Network
BUFG bufg_inst (
    .I(raw_cfgmclk),
    .O(internal_clk)
);

# Repository Structure
├── README.md               # Project documentation and summary
├── constraints/
│   └── pins.xdc            # XDC timing constraints and physical I/O properties
├── hdl/
│   └── top.v               # Top-level Verilog file with STARTUPE2 and BUFG
└── docs/
    ├── unconstrained.png   # Device view showing cost-driven placement
    ├── constrained.png     # Device view showing timing-driven placement
    └── other 
