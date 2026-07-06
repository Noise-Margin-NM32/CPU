#!/bin/bash
# ============================================================
#  run_sim.sh  —  Assemble, compile, and simulate the 8-bit CPU
# ============================================================
set -e

ASM_FILE="${1:-../programs/demo.asm}"
PROG_TXT="../rtl/program.txt"
TOOLS_DIR="../tools"
RTL_DIR="../rtl"
SIM_OUT="cpu_sim"
VCD_OUT="cpu_sim.vcd"

echo "========================================="
echo " 8-bit Pipelined CPU — Simulation Runner"
echo "========================================="

# 1. Assemble
# echo ""
# echo "[1/3] Assembling: $ASM_FILE"
# python3 "$TOOLS_DIR/assembler.py" "$ASM_FILE" "$PROG_TXT"

# 2. Compile Verilog
echo "[2/3] Compiling Verilog..."
iverilog -g2012 -o "$SIM_OUT" \
    "$RTL_DIR"/alu.sv \
    "$RTL_DIR"/control_unit.v \
    "$RTL_DIR"/data_mem.v \
    "$RTL_DIR"/instruction_mem.v \
    "$RTL_DIR"/program_counter.v \
    "$RTL_DIR"/register_file.v \
    "$RTL_DIR"/top_piplined.v \
    top_tb.v

# 3. Simulate
echo "[3/3] Running simulation..."
vvp "$SIM_OUT"

echo ""
echo "Done! VCD written to $VCD_OUT"
echo "Open with:  gtkwave $VCD_OUT &"
