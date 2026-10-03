`timescale 1ns/1ps
module tb_pipelined_fft();
    reg clk, rstn;
    top_piplined uut (.clk(clk), .rstn(rstn));

    always #5 clk = ~clk;

    integer cycle_count;
    integer instr_count;
    reg sim_done;

    // Track retired valid instructions
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            cycle_count <= 0;
            instr_count <= 0;
            sim_done    <= 0;
        end else if (!sim_done) begin
            cycle_count <= cycle_count + 1;
            if (uut.ex_mem_enable && !uut.insert_bubble && (uut.if_id_instr != 32'h00000013 || uut.ex_mem_instr_type != 0)) begin
                instr_count <= instr_count + 1;
            end
        end
    end

    initial begin
        clk = 0; rstn = 0;
        $readmemh("../firmware/fft.hex", uut.ROM.rom);
        #20;
        rstn = 1; // Release reset

        fork
            begin
                wait(uut.mem.ram[64] == 32'hABCD1234);
                sim_done = 1;
                #20;
                $display("================================================================================");
                $display("   [3-STAGE PIPELINED RV32IM CPU] — 4-POINT FFT & IFFT RESULTS");
                $display("================================================================================");
                $display(">>> INPUT SEQUENCE: x = [1, 2, 3, 4] <<<");
                $display("--------------------------------------------------------------------------------");
                $display(">>> FOURIER DOMAIN OUTPUT (FORWARD FFT): <<<");
                $display("  X[0] = %0d + (%0d)j  (Expected: 10 + 0j)", $signed(uut.mem.ram[0]), $signed(uut.mem.ram[1]));
                $display("  X[1] = %0d + (%0d)j  (Expected: -2 + 2j)", $signed(uut.mem.ram[2]), $signed(uut.mem.ram[3]));
                $display("  X[2] = %0d + (%0d)j  (Expected: -2 + 0j)", $signed(uut.mem.ram[4]), $signed(uut.mem.ram[5]));
                $display("  X[3] = %0d + (%0d)j  (Expected: -2 + -2j)", $signed(uut.mem.ram[6]), $signed(uut.mem.ram[7]));
                $display("--------------------------------------------------------------------------------");
                $display(">>> RECONSTRUCTED TIME DOMAIN OUTPUT (INVERSE IFFT): <<<");
                $display("  x'[0] = %0d + (%0d)j (Expected: 1 + 0j)", $signed(uut.mem.ram[8]), $signed(uut.mem.ram[9]));
                $display("  x'[1] = %0d + (%0d)j (Expected: 2 + 0j)", $signed(uut.mem.ram[10]), $signed(uut.mem.ram[11]));
                $display("  x'[2] = %0d + (%0d)j (Expected: 3 + 0j)", $signed(uut.mem.ram[12]), $signed(uut.mem.ram[13]));
                $display("  x'[3] = %0d + (%0d)j (Expected: 4 + 0j)", $signed(uut.mem.ram[14]), $signed(uut.mem.ram[15]));
                $display("--------------------------------------------------------------------------------");
                $display("  Mathematical Accuracy Check : %s", (uut.mem.ram[16] == 1) ? "PASSED (100% Exact Match)" : "FAILED");
                $display("--------------------------------------------------------------------------------");
                $display(">>> PERFORMANCE METRICS: 3-STAGE PIPELINED CORE <<<");
                $display("  Total Clock Cycles           : %0d cycles", cycle_count);
                $display("  Total Retired Instructions   : %0d instrs", instr_count);
                if (instr_count > 0) begin
                    $display("  Cycles Per Instruction (CPI) : %0.3f", (1.0 * cycle_count) / instr_count);
                    $display("  Instructions Per Cycle (IPC) : %0.3f", (1.0 * instr_count) / cycle_count);
                end
                $display("  Execution Time @ 300MHz      : %0.2f ns (%0.3f us)", (cycle_count * 1000.0 / 300.0), (cycle_count / 300.0));
                $display("================================================================================");
                $finish;
            end
            begin
                #500000; // Timeout after 50,000 clock cycles (0.5ms)
                $display("ERROR: 3-Stage Pipeline Simulation timed out! Cycles: %0d", cycle_count);
                $finish;
            end
        join
    end
endmodule
