`timescale 1ns/1ps
module tb_stress_picorv32();
    reg clk = 1;
    reg resetn = 0;
    wire trap;

    always #5 clk = ~clk;

    integer cycle_count;
    integer instr_count;
    reg sim_done;

    wire        mem_valid;
    wire        mem_instr;
    reg         mem_ready;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [3:0]  mem_wstrb;
    reg  [31:0] mem_rdata;

    reg [31:0] memory [0:4095];
    integer i;

    // Picorv32 instance with full RV32IM configuration
    picorv32 #(
        .ENABLE_COUNTERS    (1),
        .ENABLE_COUNTERS64  (1),
        .ENABLE_REGS_16_31  (1),
        .ENABLE_REGS_DUALPORT(1),
        .BARREL_SHIFTER     (1),
        .TWO_STAGE_SHIFT    (0),
        .TWO_CYCLE_COMPARE  (0),
        .TWO_CYCLE_ALU      (0),
        .CATCH_MISALIGN     (1),
        .CATCH_ILLINSN      (1),
        .ENABLE_MUL         (1),
        .ENABLE_FAST_MUL    (0),
        .ENABLE_DIV         (1),
        .PROGADDR_RESET     (32'h00000000),
        .STACKADDR          (32'h00004000)
    ) uut_pico (
        .clk        (clk       ),
        .resetn     (resetn    ),
        .trap       (trap      ),
        .mem_valid  (mem_valid ),
        .mem_instr  (mem_instr ),
        .mem_ready  (mem_ready ),
        .mem_addr   (mem_addr  ),
        .mem_wdata  (mem_wdata ),
        .mem_wstrb  (mem_wstrb ),
        .mem_rdata  (mem_rdata )
    );

    // Memory subsystem with 1-cycle latency (matching realistic zero-wait SRAM)
    always @(posedge clk) begin
        mem_ready <= 0;
        if (mem_valid && !mem_ready) begin
            if (mem_addr < 16384) begin
                mem_ready <= 1;
                mem_rdata <= memory[mem_addr >> 2];
                if (mem_wstrb[0]) memory[mem_addr >> 2][ 7: 0] <= mem_wdata[ 7: 0];
                if (mem_wstrb[1]) memory[mem_addr >> 2][15: 8] <= mem_wdata[15: 8];
                if (mem_wstrb[2]) memory[mem_addr >> 2][23:16] <= mem_wdata[23:16];
                if (mem_wstrb[3]) memory[mem_addr >> 2][31:24] <= mem_wdata[31:24];
            end
        end
    end

    // Cycle & instruction counting
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            cycle_count <= 0;
            instr_count <= 0;
            sim_done    <= 0;
        end else if (!sim_done) begin
            cycle_count <= cycle_count + 1;
            if (mem_valid && mem_ready && mem_instr) begin
                instr_count <= instr_count + 1;
            end
        end
    end

    initial begin
        for (i = 0; i < 4096; i = i + 1) begin
            memory[i] = 32'h00000013;
        end
        $readmemh("../firmware/stress.hex", memory);
        #20;
        resetn <= 1; // Release reset

        fork
            begin
                wait(memory[254] == 32'hABCD1234);
                sim_done = 1;
                #20;
                $display("================================================================================");
                $display("   [PICORV32 CPU] — STRESS BENCHMARK COMPLETED SUCCESSFULLY!");
                $display("================================================================================");
                $display(">>> TASK 1: 4-Point Complex FFT & IFFT of [1, 2, 3, 4] <<<");
                $display("  Fourier Domain (FFT):");
                $display("    X[0] = %d + (%d)j  (Expected: 10 + 0j)", $signed(memory[0]), $signed(memory[1]));
                $display("    X[1] = %d + (%d)j  (Expected: -2 + 2j)", $signed(memory[2]), $signed(memory[3]));
                $display("    X[2] = %d + (%d)j  (Expected: -2 + 0j)", $signed(memory[4]), $signed(memory[5]));
                $display("    X[3] = %d + (%d)j  (Expected: -2 + -2j)", $signed(memory[6]), $signed(memory[7]));
                $display("  Reconstructed Domain (IFFT):");
                $display("    x'[0] = %d + (%d)j (Expected: 1 + 0j)", $signed(memory[8]), $signed(memory[9]));
                $display("    x'[1] = %d + (%d)j (Expected: 2 + 0j)", $signed(memory[10]), $signed(memory[11]));
                $display("    x'[2] = %d + (%d)j (Expected: 3 + 0j)", $signed(memory[12]), $signed(memory[13]));
                $display("    x'[3] = %d + (%d)j (Expected: 4 + 0j)", $signed(memory[14]), $signed(memory[15]));
                $display("  Task 1 Status: %s", (memory[16] == 1) ? "PASSED (100% Exact Reconstruction)" : "FAILED");
                $display("--------------------------------------------------------------------------------");
                $display(">>> TASK 2: 256x256 Matrix Multiplication Benchmark <<<");
                $display("  16x16 In-Memory Matrix Checksum: %d", $signed(memory[20]));
                $display("  256x256 Matrix Full Trace (65,536 MAC ops): %d", $signed(memory[21]));
                $display("  Corner Checkpoints:");
                $display("    C[0][0]       = %d", $signed(memory[22]));
                $display("    C[255][255]   = %d", $signed(memory[23]));
                $display("    C[128][128]   = %d", $signed(memory[24]));
                $display("  Task 2 Status: %s", (memory[25] == 1) ? "PASSED" : "FAILED");
                $display("--------------------------------------------------------------------------------");
                $display(">>> PERFORMANCE METRICS: PICORV32 CORE <<<");
                $display("  Total Clock Cycles : %0d cycles", cycle_count);
                $display("  Total Instructions : %0d instrs", instr_count);
                if (instr_count > 0) begin
                    $display("  Cycles Per Instruction (CPI) : %0f", (1.0 * cycle_count) / instr_count);
                    $display("  Instructions Per Cycle (IPC) : %0f", (1.0 * instr_count) / cycle_count);
                end
                $display("================================================================================");
                $finish;
            end
            begin
                #50000000; // Timeout after 5,000,000 clock cycles (50ms simulation time)
                $display("ERROR: PicoRV32 Simulation timed out!");
                $display("Current RAM[254]: 0x%h, Cycles: %0d", memory[254], cycle_count);
                $finish;
            end
        join
    end
endmodule
