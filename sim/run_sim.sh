#!/bin/bash
# ============================================================
#  run_sim.sh  —  Assemble, compile, and simulate the RISC-V CPU
# ============================================================
set -e

RTL_DIR="../rtl"
SIM_OUT="cpu_sim"
VCD_OUT="cpu_sim.vcd"

echo "========================================="
echo " RISC-V Pipelined CPU — Simulation Runner"
echo "========================================="

# Compile Verilog
echo "[1/2] Compiling Verilog..."
iverilog -g2012 -o "$SIM_OUT" \
    "$RTL_DIR"/alu_int.sv \
    "$RTL_DIR"/multiplier.sv \
    "$RTL_DIR"/divider.sv \
    "$RTL_DIR"/alu.sv \
    "$RTL_DIR"/control_unit.v \
    "$RTL_DIR"/data_mem.v \
    "$RTL_DIR"/instruction_mem.v \
    "$RTL_DIR"/program_counter.v \
    "$RTL_DIR"/register_file.v \
    "$RTL_DIR"/top_piplined.v \
    top_tb.v

# Run Simulation
echo "[2/2] Running simulation..."
vvp "$SIM_OUT"

echo ""
echo "Done! VCD written to $VCD_OUT"
echo "Open with:  gtkwave $VCD_OUT &"
