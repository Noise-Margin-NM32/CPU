#!/bin/bash
# ============================================================
#  run_c_sim.sh — Compile C code and run simulation
# ============================================================
set -e

RTL_DIR="../rtl"
SIM_OUT="c_sim"
VCD_OUT="c_sim.vcd"

echo "========================================="
echo "   RISC-V CPU — C Code Simulation Runner"
# 1. Compile the C code using the root Makefile
echo "[1/3] Compiling C program..."
make -C .. clean
make -C ..

# 2. Compile Verilog simulation binary
echo "[2/3] Compiling Verilog..."
iverilog -g2012 -o "$SIM_OUT" \
    "$RTL_DIR"/alu.sv \
    "$RTL_DIR"/control_unit.v \
    "$RTL_DIR"/data_mem.v \
    "$RTL_DIR"/instruction_mem.v \
    "$RTL_DIR"/program_counter.v \
    "$RTL_DIR"/register_file.v \
    "$RTL_DIR"/top_piplined.v \
    tb_c.v

# 3. Run simulation
echo "[3/3] Running simulation..."
vvp "$SIM_OUT"

echo ""
echo "Done! VCD written to $VCD_OUT"
echo "Open with:  gtkwave $VCD_OUT &"
