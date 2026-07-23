# 32-bit Pipelined RISC-V (RV32IM) CPU — RTL Design in Verilog

A fully functional **32-bit CPU** implemented in Verilog, featuring a **3-stage pipeline** (IF → ID → EX/WB), a subset of the standard **RISC-V RV32I Base Integer ISA** combined with the **RV32M Multiply/Divide Extension**, a **Harvard memory architecture**, and an extensive self-verifying testbench environment.

---

## Architecture Overview

```
                    ┌──────────────────────────────────────────────┐
                    │               top_piplined.v                 │
                    │                                              │
      ┌──────────┐  │  ┌────────┐  IF/ID  ┌──────────┐  ID/EX      │
      │  Clock   │──┼─▶│   PC   │────────▶│Control   │───────┐     │
      │  Reset   │  │  │(32-bit)│         │  Unit    │       │     │
      └──────────┘  │  └────────┘         └──────────┘       ▼     │
                    │       │                    │       ┌────────┐│
                    │       ▼                   ▼        │  ALU   ││
                    │  ┌────────┐         ┌──────────┐   │(32-bit)││
                    │  │  ROM   │         │ Reg File │   └────────┘│
                    │  │(Instr) │         │(32×32-bit)       │     │
                    │  └────────┘         └──────────┘       ▼     │
                    │                          │         ┌────────┐│
                    │                          └────────▶│  RAM   ││
                    │                                    │(256×32)││
                    │                                    └────────┘│
                    └──────────────────────────────────────────────┘
```

### Pipeline Stages

| Stage | Name | Modules Involved | Description |
|---|---|---|---|
| 1 | **IF** (Fetch) | `program_counter`, `instruction_mem` | Increments PC or loads jump address; fetches 32-bit instructions from Instruction ROM. |
| 2 | **ID** (Decode) | `control_unit`, `register_file` | Decodes instruction fields, sign-extends immediates, and reads source registers asynchronously. |
| 3 | **EX/WB** (Execute/Write-back) | `alu`, `data_mem`, write-back | Computes arithmetic/logical operations, performs load/store operations, handles branch/jump targets, and writes back to registers synchronously on clock edges. |

Pipeline registers between stages: `IF/ID` and `ID/EX`.

---

## Repository Layout

```
8bit_CPU_pipline/
├── rtl/                  # Synthesisable Verilog/SystemVerilog Source
│   ├── top_piplined.v    # Top-level: wires together all pipeline stages
│   ├── control_unit.v    # Instruction decoder — generates control signals
│   ├── alu.sv            # 32-bit ALU (ADD, SUB, shifts, logicals, MUL/DIV extension)
│   ├── program_counter.v # 32-bit Program Counter (with load/branch support)
│   ├── register_file.v   # 32 × 32-bit register file (async read, sync write, x0=0)
│   ├── data_mem.v        # 256 × 32-bit data RAM (async read, sync write, byte enables)
│   └── instruction_mem.v # 256 × 32-bit instruction ROM (loads hex code via $readmemh)
│
├── sim/                  # Simulation Environment
│   ├── top_tb.v          # Extensive 45-instruction self-verifying testbench
│   ├── cpu_sim           # Compiled simulation binary
│   ├── cpu_sim.vcd       # Simulation waveform trace file (for GTKWave)
│   └── run_sim.sh        # One-shot simulation runner script
│
├── programs/             # Program Sources
│   ├── demo.asm          # Legacy ALU assembly demo
│   └── counter_loop.asm  # Legacy countdown loop assembly demo
│
├── tools/                # Legacy Tools
│   └── assembler.py      # Legacy Python assembler (for custom 8-bit ISA)
│
├── docs/                 # Documentation
│   └── ISA_reference.md  # Full RISC-V RV32IM instruction set reference
│
└── .gitignore
```

---

## Instruction Set Summary

The processor supports **45 instructions** spanning the RV32I base integer ISA and the RV32M extension:

1. **Arithmetic**: `ADD`, `SUB`, `ADDI`
2. **Logical**: `AND`, `OR`, `XOR`, `ANDI`, `ORI`, `XORI`
3. **Shifts**: `SLL`, `SRL`, `SRA`, `SLLI`, `SRLI`, `SRAI`
4. **Comparisons**: `SLT`, `SLTU`, `SLTI`, `SLTIU`
5. **Memory Access**: Loads (`LB`, `LH`, `LW`, `LBU`, `LHU`) and Stores (`SB`, `SH`, `SW`)
6. **Branching**: `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU`
7. **Jumps & JAL/JALR**: `JAL`, `JALR`
8. **Upper Immediates**: `LUI`, `AUIPC`
9. **Multiply/Divide (M-Extension)**: `MUL`, `MULH`, `MULHSU`, `MULHU`, `DIV`, `DIVU`, `REM`, `REMU`

For instruction formats, opcodes, and field encodings, see [`docs/ISA_reference.md`](docs/ISA_reference.md).

---

## Getting Started

### Prerequisites

| Tool | Purpose | Installation |
|---|---|---|
| **Icarus Verilog** | Verilog compiler/simulator | `sudo apt install iverilog` |
| **GTKWave** *(optional)* | Waveform visualizer | `sudo apt install gtkwave` |

### Simulating the CPU

To run the automated Verilog compilation and verify the CPU design against the 45-instruction test suite:

```bash
# 1. Navigate to the simulation directory
cd sim

# 2. Run the simulation script
./run_sim.sh
```

This compiles all Verilog files in `rtl/` alongside `sim/top_tb.v`, runs the simulation using `vvp`, outputs a verification report of the passed and failed tests, and generates `cpu_sim.vcd`.

### Waveform Analysis

To visually inspect the pipeline registers, control signals, registers, and execution timeline:

```bash
gtkwave cpu_sim.vcd &
```

---

## Design and Hazard Notes

* **Harvard Architecture**: Instruction memory (ROM) and data memory (RAM) exist in separate address spaces. Instruction ROM reads instructions as 32-bit words, while Data RAM supports byte, half-word, and word reads and writes.
* **Data Hazards (RAW)**:
  * Since the register file write happens synchronously on the rising clock edge at the end of the EX/WB stage and register reads happen asynchronously during the ID stage, a 1-cycle data hazard exists.
  * **Resolution**: Software/toolchains must insert **1 NOP** instruction between any instruction writing to a register and a subsequent instruction reading from that same register.
* **Control Hazards**:
  * Jumps and taken branches take two clock cycles to resolve target addresses and PC updates in the EX/WB stage.
  * **Resolution**: The hardware automatically flushes the pipeline registers (clearing the `if_id_instr` register to NOPs) when `branch_taken` or `jump` is asserted. There is a **2-cycle branch penalty**, but no compiler-inserted NOPs are required after branches/jumps.
* **Reset**: All internal pipeline registers, PC, and general-purpose registers (except `x0`) are cleared asynchronously when `rst = 0`.

---

## License

This project is licensed under the MIT License. Feel free to use it for learning, coursework, and hardware design prototyping.
