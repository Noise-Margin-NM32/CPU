#!/bin/bash
# ==============================================================================
#  run_fft_benchmark.sh — Run 4-Point FFT & IFFT Benchmark
#  on both 3-Stage Pipelined RV32IM CPU and PicoRV32 (Dhrystone Harness)
# ==============================================================================
set -e

RTL_DIR="../rtl"
PICO_DIR="/home/omkar/picorv32"

echo "================================================================================"
echo "          4-POINT FFT & IFFT BENCHMARK: 3-STAGE CPU vs PICORV32"
echo "================================================================================"

# 1. Compile C Benchmark
echo "[1/3] Compiling 4-Point FFT & IFFT Benchmark..."
make -C .. fft

# 2. Compile & Run 3-Stage Pipelined CPU Simulation
echo ""
echo "[2/3] Simulating on 3-Stage Pipelined RV32IM CPU Core..."
iverilog -g2012 -o fft_pipelined_sim \
    "$RTL_DIR"/alu_int.sv \
    "$RTL_DIR"/alu.sv \
    "$RTL_DIR"/control_unit.v \
    "$RTL_DIR"/data_mem.v \
    "$RTL_DIR"/divider.sv \
    "$RTL_DIR"/instruction_mem.v \
    "$RTL_DIR"/multiplier.sv \
    "$RTL_DIR"/program_counter.v \
    "$RTL_DIR"/register_file.v \
    "$RTL_DIR"/top_piplined.v \
    tb_pipelined_fft.v

vvp fft_pipelined_sim

# 3. Compile & Run PicoRV32 Simulation
echo ""
echo "[3/3] Simulating on PicoRV32 CPU Core..."
iverilog -g2012 -o fft_picorv32_sim \
    -I "$PICO_DIR" \
    "$PICO_DIR"/picorv32.v \
    "$PICO_DIR"/picorv32_pcpi_mul.v \
    "$PICO_DIR"/picorv32_pcpi_div.v \
    tb_pico_fft.v

vvp fft_picorv32_sim

echo ""
echo "================================================================================"
echo "                      BENCHMARK EXECUTION COMPLETE"
echo "================================================================================"
