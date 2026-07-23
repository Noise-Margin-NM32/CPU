# ISA Reference — 32-bit Pipelined RISC-V (RV32IM) CPU

This document provides a detailed reference for the 32-bit pipelined CPU instruction set, which implements a subset of the **RISC-V RV32I Base Integer Instruction Set** and the **RV32M Multiply/Divide Extension**.

---

## Instruction Formats

All instructions are **32 bits wide** and aligned on 4-byte boundaries. The CPU supports six basic instruction formats:

### 1. R-Type (Register-Register)
Used for computational operations between registers.
```
 31         25 24     20 19     15 14   12 11      7 6          0
┌─────────────┬─────────┬─────────┬───────┬─────────┬────────────┐
│   funct7    │   rs2   │   rs1   │funct3 │   rd    │   opcode   │
└─────────────┴─────────┴─────────┴───────┴─────────┴────────────┘
```

### 2. I-Type (Register-Immediate / Load / JALR)
Used for immediate computational operations, memory loads, and the JALR jump instruction.
```
 31                 20 19     15 14   12 11      7 6          0
┌─────────────────────┬─────────┬───────┬─────────┬────────────┐
│     imm[11:0]       │   rs1   │funct3 │   rd    │   opcode   │
└─────────────────────┴─────────┴───────┴─────────┴────────────┘
```

### 3. S-Type (Store)
Used for memory store operations.
```
 31         25 24     20 19     15 14   12 11      7 6          0
┌─────────────┬─────────┬─────────┬───────┬─────────┬────────────┐
│  imm[11:5]  │   rs2   │   rs1   │funct3 │imm[4:0] │   opcode   │
└─────────────┴─────────┴─────────┴───────┴─────────┴────────────┘
```

### 4. B-Type (Branch)
Used for conditional branch instructions.
```
 31 30      25 24     20 19     15 14   12 11  8  7  6          0
┌──┬──────────┬─────────┬─────────┬───────┬─────┬──┬────────────┐
│i1│imm[10:5] │   rs2   │   rs1   │funct3 │i[4] │i1│   opcode   │ (i1=imm[12], i1=imm[11])
└──┴──────────┴─────────┴─────────┴───────┴─────┴──┴────────────┘
```

### 5. U-Type (Upper Immediate)
Used for LUI and AUIPC instructions, which load 20-bit upper immediates.
```
 31                                     12 11      7 6          0
┌─────────────────────────────────────────┬─────────┬────────────┐
│               imm[31:12]                │   rd    │   opcode   │
└─────────────────────────────────────────┴─────────┴────────────┘
```

### 6. J-Type (Jump)
Used for the JAL unconditional jump instruction.
```
 31 30          21 20 19          12 11      7 6          0
┌──┬──────────────┬──┬──────────────┬─────────┬────────────┐
│i2│  imm[10:1]   │i1│  imm[19:12]  │   rd    │   opcode   │ (i2=imm[20], i1=imm[11])
└──┴──────────────┴──┴──────────────┴─────────┴────────────┘
```

---

## Registers

The CPU features a **32 × 32-bit register file** (`x0` to `x31`).

| Register Name | Alias | Purpose | Description |
|:---:|:---:|---|---|
| `x0` | `zero` | Hardwired Zero | Always reads as `0x00000000`. Writes are ignored. |
| `x1` | `ra` | Return Address | Saved return address for function calls. |
| `x2` | `sp` | Stack Pointer | Points to the top of the stack. |
| `x3` | `gp` | Global Pointer | Points to global variables. |
| `x4` | `tp` | Thread Pointer | Thread-local storage pointer. |
| `x5`–`x7` | `t0`–`t2` | Temporaries | Temporary registers. |
| `x8` | `s0` / `fp` | Saved Register / Frame Pointer | Callee-saved frame/saved register. |
| `x9` | `s1` | Saved Register | Callee-saved register. |
| `x10`–`x11` | `a0`–`a1` | Function Arguments / Return Values | Arguments passed to functions and return values. |
| `x12`–`x17` | `a2`–`a7` | Function Arguments | Additional arguments. |
| `x18`–`x27` | `s2`–`s11` | Saved Registers | Callee-saved registers. |
| `x28`–`x31` | `t3`–`t6` | Temporaries | Temporary registers. |

All general-purpose registers (except `x0`) are cleared to `0x00000000` on reset (`rst = 0`).

---

## Instruction Set Table

Below are the instructions supported by the CPU, grouped by functionality.

### 1. Integer Computational (R-Type)
*Opcode: `7'b0110011`*

| Mnemonic | funct3 | funct7 | Operation | Description |
|---|:---:|:---:|---|---|
| **ADD** | `3'b000` | `7'b0000000` | `rd = rs1 + rs2` | Add registers |
| **SUB** | `3'b000` | `7'b0100000` | `rd = rs1 - rs2` | Subtract registers |
| **SLL** | `3'b001` | `7'b0000000` | `rd = rs1 << rs2[4:0]` | Shift Left Logical |
| **SLT** | `3'b010` | `7'b0000000` | `rd = (rs1 < rs2) ? 1 : 0` | Set Less Than (Signed) |
| **SLTU** | `3'b011` | `7'b0000000` | `rd = (rs1 < rs2) ? 1 : 0` | Set Less Than (Unsigned) |
| **XOR** | `3'b100` | `7'b0000000` | `rd = rs1 ^ rs2` | Bitwise XOR |
| **SRL** | `3'b101` | `7'b0000000` | `rd = rs1 >> rs2[4:0]` | Shift Right Logical |
| **SRA** | `3'b101` | `7'b0100000` | `rd = rs1 >>> rs2[4:0]` | Shift Right Arithmetic (Sign-extended) |
| **OR** | `3'b110` | `7'b0000000` | `rd = rs1 \| rs2` | Bitwise OR |
| **AND** | `3'b111` | `7'b0000000` | `rd = rs1 & rs2` | Bitwise AND |

### 2. Immediate Computational (I-Type)
*Opcode: `7'b0010011`*

| Mnemonic | funct3 | funct7 | Operation | Description |
|---|:---:|:---:|---|---|
| **ADDI** | `3'b000` | — | `rd = rs1 + signExt(imm)` | Add Immediate |
| **SLLI** | `3'b001` | `7'b0000000` | `rd = rs1 << imm[4:0]` | Shift Left Logical Immediate |
| **SLTI** | `3'b010` | — | `rd = (rs1 < signExt(imm)) ? 1 : 0` | Set Less Than Immediate (Signed) |
| **SLTIU** | `3'b011` | — | `rd = (rs1 < signExt(imm)) ? 1 : 0` | Set Less Than Immediate (Unsigned) |
| **XORI** | `3'b100` | — | `rd = rs1 ^ signExt(imm)` | Bitwise XOR Immediate |
| **SRLI** | `3'b101` | `7'b0000000` | `rd = rs1 >> imm[4:0]` | Shift Right Logical Immediate |
| **SRAI** | `3'b101` | `7'b0100000` | `rd = rs1 >>> imm[4:0]` | Shift Right Arithmetic Immediate |
| **ORI** | `3'b110` | — | `rd = rs1 \| signExt(imm)` | Bitwise OR Immediate |
| **ANDI** | `3'b111` | — | `rd = rs1 & signExt(imm)` | Bitwise AND Immediate |

### 3. Load & Store Instructions
Loads use opcode `7'b0000011` (I-Type). Stores use opcode `7'b0100011` (S-Type).

| Mnemonic | Type | funct3 | Operation | Description |
|---|:---:|:---:|---|---|
| **LB** | Load | `3'b000` | `rd = signExt(Mem[rs1 + imm][7:0])` | Load Byte (Signed) |
| **LH** | Load | `3'b001` | `rd = signExt(Mem[rs1 + imm][15:0])` | Load Half-word (Signed) |
| **LW** | Load | `3'b010` | `rd = Mem[rs1 + imm][31:0]` | Load Word |
| **LBU** | Load | `3'b100` | `rd = {24'b0, Mem[rs1 + imm][7:0]}` | Load Byte Unsigned |
| **LHU** | Load | `3'b101` | `rd = {16'b0, Mem[rs1 + imm][15:0]}` | Load Half-word Unsigned |
| **SB** | Store | `3'b000` | `Mem[rs1 + imm][7:0] = rs2[7:0]` | Store Byte |
| **SH** | Store | `3'b001` | `Mem[rs1 + imm][15:0] = rs2[15:0]` | Store Half-word |
| **SW** | Store | `3'b010` | `Mem[rs1 + imm][31:0] = rs2[31:0]` | Store Word |

### 4. Branch & Jump Instructions
Branches use opcode `7'b1100011` (B-Type).
JAL uses opcode `7'b1101111` (J-Type). JALR uses opcode `7'b1100111` (I-Type, funct3=`3'b000`).

| Mnemonic | Type | funct3 | Condition / Operation | Description |
|---|:---:|:---:|---|---|
| **BEQ** | Branch | `3'b000` | `if (rs1 == rs2) PC = PC + imm` | Branch if Equal |
| **BNE** | Branch | `3'b001` | `if (rs1 != rs2) PC = PC + imm` | Branch if Not Equal |
| **BLT** | Branch | `3'b100` | `if (rs1 < rs2) PC = PC + imm` | Branch if Less Than (Signed) |
| **BGE** | Branch | `3'b101` | `if (rs1 >= rs2) PC = PC + imm` | Branch if Greater/Equal (Signed) |
| **BLTU** | Branch | `3'b110` | `if (rs1 < rs2) PC = PC + imm` | Branch if Less Than (Unsigned) |
| **BGEU** | Branch | `3'b111` | `if (rs1 >= rs2) PC = PC + imm` | Branch if Greater/Equal (Unsigned) |
| **JAL** | Jump | — | `rd = PC + 4; PC = PC + imm` | Jump and Link |
| **JALR** | Jump | `3'b000` | `rd = PC + 4; PC = (rs1 + imm) & ~1` | Jump and Link Register |

### 5. Upper Immediate Instructions
| Mnemonic | Type | Opcode | Operation | Description |
|---|:---:|:---:|---|---|
| **LUI** | U-Type | `7'b0110111` | `rd = {imm[31:12], 12'h000}` | Load Upper Immediate |
| **AUIPC** | U-Type | `7'b0010111` | `rd = PC + {imm[31:12], 12'h000}` | Add Upper Immediate to PC |

### 6. Multiply/Divide Extension (RV32M)
*Opcode: `7'b0110011` (R-Type)*

| Mnemonic | funct3 | funct7 | Operation | Description |
|---|:---:|:---:|---|---|
| **MUL** | `3'b000` | `7'b0000001` | `rd = lower32(rs1 × rs2)` | Multiply (Lower 32 bits) |
| **MULH** | `3'b001` | `7'b0000001` | `rd = upper32(signed(rs1) × signed(rs2))` | Multiply High Signed-Signed |
| **MULHSU**| `3'b010` | `7'b0000001` | `rd = upper32(signed(rs1) × unsigned(rs2))` | Multiply High Signed-Unsigned |
| **MULHU** | `3'b011` | `7'b0000001` | `rd = upper32(unsigned(rs1) × unsigned(rs2))` | Multiply High Unsigned-Unsigned |
| **DIV** | `3'b100` | `7'b0000001` | `rd = signed(rs1) / signed(rs2)` | Division (Signed) |
| **DIVU** | `3'b101` | `7'b0000001` | `rd = unsigned(rs1) / unsigned(rs2)` | Division (Unsigned) |
| **REM** | `3'b110` | `7'b0000001` | `rd = signed(rs1) % signed(rs2)` | Remainder (Signed) |
| **REMU** | `3'b111` | `7'b0000001` | `rd = unsigned(rs1) % unsigned(rs2)` | Remainder (Unsigned) |

---

## Pipeline Hazards & Execution

This CPU utilizes a **3-stage pipeline**:
1. **Instruction Fetch (IF)**: Uses the Program Counter (PC) to read instructions from the instruction memory.
2. **Instruction Decode (ID)**: Decodes instruction fields using the Control Unit, reads source values from the Register File asynchronously, and sign-extends immediates.
3. **Execute / Write-Back (EX/WB)**: Uses the ALU to perform computations, resolves conditional branches, reads/writes Data Memory (RAM), and writes the result back into the Register File.

### Data Hazards (RAW)
Because there are no hardware data-forwarding paths or hardware stall logic, **Read-After-Write (RAW) data dependencies** must be handled by the software toolchain (assembler or compiler scheduling).
* **Timing**: Write-back to the register file happens synchronously on the rising clock edge at the end of the EX/WB stage, whereas register reads happen asynchronously during the ID stage.
* **Resolution**: An instruction that reads a register written by the immediately preceding instruction will get the stale value. Therefore, **1 NOP instruction** must be inserted between a register write and its subsequent read in the next instruction.
* **Example**:
  ```asm
  addi x1, x0, 10
  nop               // Required NOP bubble
  add  x2, x1, x1   // Reads correct value of x1
  ```

### Control Hazards (Branches/Jumps)
Control hazard resolution is handled dynamically by hardware:
* **Resolution**: Conditional branches and jump target addresses are evaluated in the EX/WB stage. This requires **2 clock cycles** of execution.
* **Pipeline Flushing**: While a branch or jump is being resolved over these two cycles, the hardware automatically flushes the pipeline registers (setting `if_id_instr` to `32'h00000000`, which encodes a hardware NOP).
* **Branch Penalty**: There is a **2-cycle branch penalty** for taken branches and jumps, during which two dummy NOPs are automatically executed by the hardware. No compiler-inserted NOPs are required after branches or jumps.

---

## Memory Map

The processor uses a **Harvard memory architecture** with separated instruction and data spaces:

| Memory Region | Word Size | Depth | Address Width | Loading/Access Method |
|---|---|---|---|---|
| **Instruction ROM** | 32-bit | 256 words | 10-bit (byte-addressed `addr[9:2]`) | Initialized from `firmware/program.hex` via `$readmemh` |
| **Data RAM** | 32-bit | 256 words | 32-bit (byte-aligned writes via `byte_en`) | Asynchronous reads; Synchronous writes on `clk` posedge |
