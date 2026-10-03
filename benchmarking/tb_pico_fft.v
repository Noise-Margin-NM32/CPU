`timescale 1ns/1ps
module tb_pico_fft();
    reg clk = 1;
    reg resetn = 0;
    wire trap;

    always #5 clk = ~clk;

    integer cycle_count;
    integer instr_count;
    reg sim_done;

    wire        mem_valid;
    wire        mem_instr;
    wire        mem_ready;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [3:0]  mem_wstrb;
    reg  [31:0] mem_rdata;

    wire        mem_la_read;
    wire        mem_la_write;
    wire [31:0] mem_la_addr;
    wire [31:0] mem_la_wdata;
    wire [3:0]  mem_la_wstrb;

    // PicoRV32 Core (identical configuration to Dhrystone testbench)
    picorv32 #(
        .BARREL_SHIFTER     (1),
        .ENABLE_FAST_MUL    (1),
        .ENABLE_DIV         (1),
        .PROGADDR_RESET     (32'h0000_0000),
        .STACKADDR          (32'h0000_4000)
    ) uut_pico (
        .clk         (clk        ),
        .resetn      (resetn     ),
        .trap        (trap       ),
        .mem_valid   (mem_valid  ),
        .mem_instr   (mem_instr  ),
        .mem_ready   (mem_ready  ),
        .mem_addr    (mem_addr   ),
        .mem_wdata   (mem_wdata  ),
        .mem_wstrb   (mem_wstrb  ),
        .mem_rdata   (mem_rdata  ),
        .mem_la_read (mem_la_read ),
        .mem_la_write(mem_la_write),
        .mem_la_addr (mem_la_addr ),
        .mem_la_wdata(mem_la_wdata),
        .mem_la_wstrb(mem_la_wstrb)
    );

    // 16KB Byte-addressed memory array (matching picorv32/dhrystone/testbench.v)
    reg [7:0] memory [0:16*1024-1];
    integer i;

    // Load hex file (word format -> byte array)
    reg [31:0] temp_hex [0:4095];
    initial begin
        for (i = 0; i < 16*1024; i = i + 1) begin
            memory[i] = 8'h00;
        end
        $readmemh("../firmware/fft.hex", temp_hex);
        for (i = 0; i < 4096; i = i + 1) begin
            memory[4*i + 0] = temp_hex[i][ 7: 0];
            memory[4*i + 1] = temp_hex[i][15: 8];
            memory[4*i + 2] = temp_hex[i][23:16];
            memory[4*i + 3] = temp_hex[i][31:24];
        end
    end

    assign mem_ready = 1;

    // Look-ahead synchronous memory read/write (0-wait state SRAM model from Dhrystone)
    always @(posedge clk) begin
        mem_rdata[ 7: 0] <= mem_la_read ? memory[mem_la_addr + 0] : 8'hxx;
        mem_rdata[15: 8] <= mem_la_read ? memory[mem_la_addr + 1] : 8'hxx;
        mem_rdata[23:16] <= mem_la_read ? memory[mem_la_addr + 2] : 8'hxx;
        mem_rdata[31:24] <= mem_la_read ? memory[mem_la_addr + 3] : 8'hxx;

        if (mem_la_write) begin
            if (mem_la_wstrb[0]) memory[mem_la_addr + 0] <= mem_la_wdata[ 7: 0];
            if (mem_la_wstrb[1]) memory[mem_la_addr + 1] <= mem_la_wdata[15: 8];
            if (mem_la_wstrb[2]) memory[mem_la_addr + 2] <= mem_la_wdata[23:16];
            if (mem_la_wstrb[3]) memory[mem_la_addr + 3] <= mem_la_wdata[31:24];
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

    // Helper functions to read 32-bit signed words from byte memory
    function signed [31:0] read_word(input integer word_idx);
        read_word = {memory[4*word_idx + 3], memory[4*word_idx + 2], memory[4*word_idx + 1], memory[4*word_idx + 0]};
    endfunction

    initial begin
        #20;
        resetn <= 1; // Release reset

        fork
            begin
                // Wait for completion marker written to mem[64] (byte address 256 = 0x100)
                wait({memory[4*64 + 3], memory[4*64 + 2], memory[4*64 + 1], memory[4*64 + 0]} == 32'hABCD1234);
                sim_done = 1;
                #20;
                $display("================================================================================");
                $display("   [PICORV32 CPU] — 4-POINT FFT & IFFT RESULTS (DHRYSTONE HARNESS)");
                $display("================================================================================");
                $display(">>> INPUT SEQUENCE: x = [1, 2, 3, 4] <<<");
                $display("--------------------------------------------------------------------------------");
                $display(">>> FOURIER DOMAIN OUTPUT (FORWARD FFT): <<<");
                $display("  X[0] = %0d + (%0d)j  (Expected: 10 + 0j)", read_word(0), read_word(1));
                $display("  X[1] = %0d + (%0d)j  (Expected: -2 + 2j)", read_word(2), read_word(3));
                $display("  X[2] = %0d + (%0d)j  (Expected: -2 + 0j)", read_word(4), read_word(5));
                $display("  X[3] = %0d + (%0d)j  (Expected: -2 + -2j)", read_word(6), read_word(7));
                $display("--------------------------------------------------------------------------------");
                $display(">>> RECONSTRUCTED TIME DOMAIN OUTPUT (INVERSE IFFT): <<<");
                $display("  x'[0] = %0d + (%0d)j (Expected: 1 + 0j)", read_word(8), read_word(9));
                $display("  x'[1] = %0d + (%0d)j (Expected: 2 + 0j)", read_word(10), read_word(11));
                $display("  x'[2] = %0d + (%0d)j (Expected: 3 + 0j)", read_word(12), read_word(13));
                $display("  x'[3] = %0d + (%0d)j (Expected: 4 + 0j)", read_word(14), read_word(15));
                $display("--------------------------------------------------------------------------------");
                $display("  Mathematical Accuracy Check : %s", (read_word(16) == 1) ? "PASSED (100% Exact Match)" : "FAILED");
                $display("--------------------------------------------------------------------------------");
                $display(">>> PERFORMANCE METRICS: PICORV32 CORE <<<");
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
                #2000000; // Timeout after 200,000 clock cycles (2ms)
                $display("ERROR: PicoRV32 Simulation timed out! Cycles: %0d", cycle_count);
                $finish;
            end
        join
    end
endmodule
