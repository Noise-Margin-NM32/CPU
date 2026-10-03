`timescale 1ns/1ps
module tb_stress_pipelined();
    reg clk, rstn;
    top_piplined uut (.clk(clk), .rstn(rstn));

    always #5 clk = ~clk;

    integer cycle_count;
    integer instr_count;
    reg sim_done;

    // Track retired instructions
    // An instruction retires when it passes Stage 3 without being a bubble or stall
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            cycle_count <= 0;
            instr_count <= 0;
            sim_done    <= 0;
        end else if (!sim_done) begin
            cycle_count <= cycle_count + 1;
            // Count retired valid instructions:
            // ex_mem register is non-zero and not bubble
            if (uut.ex_mem_enable && !uut.insert_bubble && (uut.if_id_instr != 32'h00000013 || uut.ex_mem_instr_type != 0)) begin
                instr_count <= instr_count + 1;
            end
        end
    end

    initial begin
        clk = 0; rstn = 0;
        $readmemh("../firmware/stress.hex", uut.ROM.rom);
        #20;
        rstn = 1; // Release reset

        fork
            begin
                wait(uut.mem.ram[254] == 32'hABCD1234);
                sim_done = 1;
                #20;
                $display("================================================================================");
                $display("   [3-STAGE PIPELINED RV32IM CPU] — STRESS BENCHMARK COMPLETED SUCCESSFULLY!");
                $display("================================================================================");
                $display(">>> TASK 1: 4-Point Complex FFT & IFFT of [1, 2, 3, 4] <<<");
                $display("  Fourier Domain (FFT):");
                $display("    X[0] = %d + (%d)j  (Expected: 10 + 0j)", $signed(uut.mem.ram[0]), $signed(uut.mem.ram[1]));
                $display("    X[1] = %d + (%d)j  (Expected: -2 + 2j)", $signed(uut.mem.ram[2]), $signed(uut.mem.ram[3]));
                $display("    X[2] = %d + (%d)j  (Expected: -2 + 0j)", $signed(uut.mem.ram[4]), $signed(uut.mem.ram[5]));
                $display("    X[3] = %d + (%d)j  (Expected: -2 + -2j)", $signed(uut.mem.ram[6]), $signed(uut.mem.ram[7]));
                $display("  Reconstructed Domain (IFFT):");
                $display("    x'[0] = %d + (%d)j (Expected: 1 + 0j)", $signed(uut.mem.ram[8]), $signed(uut.mem.ram[9]));
                $display("    x'[1] = %d + (%d)j (Expected: 2 + 0j)", $signed(uut.mem.ram[10]), $signed(uut.mem.ram[11]));
                $display("    x'[2] = %d + (%d)j (Expected: 3 + 0j)", $signed(uut.mem.ram[12]), $signed(uut.mem.ram[13]));
                $display("    x'[3] = %d + (%d)j (Expected: 4 + 0j)", $signed(uut.mem.ram[14]), $signed(uut.mem.ram[15]));
                $display("  Task 1 Status: %s", (uut.mem.ram[16] == 1) ? "PASSED (100% Exact Reconstruction)" : "FAILED");
                $display("--------------------------------------------------------------------------------");
                $display(">>> TASK 2: 256x256 Matrix Multiplication Benchmark <<<");
                $display("  16x16 In-Memory Matrix Checksum: %d", $signed(uut.mem.ram[20]));
                $display("  256x256 Matrix Full Trace (65,536 MAC ops): %d", $signed(uut.mem.ram[21]));
                $display("  Corner Checkpoints:");
                $display("    C[0][0]       = %d", $signed(uut.mem.ram[22]));
                $display("    C[255][255]   = %d", $signed(uut.mem.ram[23]));
                $display("    C[128][128]   = %d", $signed(uut.mem.ram[24]));
                $display("  Task 2 Status: %s", (uut.mem.ram[25] == 1) ? "PASSED" : "FAILED");
                $display("--------------------------------------------------------------------------------");
                $display(">>> PERFORMANCE METRICS: 3-STAGE PIPELINED CORE <<<");
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
                #20000000; // Timeout after 2,000,000 clock cycles (20ms simulation time)
                $display("ERROR: 3-Stage Pipeline Simulation timed out!");
                $display("Current RAM[254]: 0x%h, Cycles: %0d", uut.mem.ram[254], cycle_count);
                $finish;
            end
        join
    end
endmodule
