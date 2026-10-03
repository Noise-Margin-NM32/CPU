#!/bin/bash
# ==============================================================================
#  run_stress_benchmark.sh — Run FFT/IFFT & Matrix Multiplication Stress Test
#  on both 3-Stage Pipelined RV32IM CPU and PicoRV32
# ==============================================================================
set -e

RTL_DIR="../rtl"
PICO_DIR="/home/omkar/picorv32"

echo "================================================================================"
echo "          RISC-V BENCHMARK: 3-STAGE PIPELINED CPU vs PICORV32"
echo "================================================================================"

# 1. Compile C Benchmark
echo "[1/4] Compiling FFT/IFFT & 256x256 Matrix Mult Benchmark..."
make -C .. stress

# 2. Compile & Run 3-Stage Pipelined CPU Simulation
echo ""
echo "[2/4] Simulating on 3-Stage Pipelined RV32IM CPU Core..."
iverilog -g2012 -o stress_pipelined_sim \
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
    tb_stress_pipelined.v

vvp stress_pipelined_sim | tee pipelined_results.log

# 3. Compile & Run PicoRV32 Simulation
echo ""
echo "[3/4] Simulating on PicoRV32 CPU Core..."
iverilog -g2012 -o stress_picorv32_sim \
    -I "$PICO_DIR" \
    "$PICO_DIR"/picorv32.v \
    "$PICO_DIR"/picorv32_pcpi_mul.v \
    "$PICO_DIR"/picorv32_pcpi_div.v \
    tb_stress_picorv32.v

vvp stress_picorv32_sim | tee picorv32_results.log

echo ""
echo "[4/4] Benchmark Comparison Complete!"
