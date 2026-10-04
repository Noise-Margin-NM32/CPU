`timescale 1ns/1ps
module tb_c();
    reg clk, rstn;
    // AHB-Lite Instruction Master Wires
    wire [1:0]  instr_htrans;
    wire [31:0] instr_haddr;
    wire        instr_hwrite;
    wire [2:0]  instr_hsize;
    wire [31:0] instr_hwdata;
    wire        instr_hready;
    wire [31:0] instr_hrdata;
    wire        instr_hresp;

    // AHB Data Master Wires
    wire        data_hbusreq;
    wire [1:0]  data_htrans;
    wire [31:0] data_haddr;
    wire        data_hwrite;
    wire [2:0]  data_hsize;
    wire [31:0] data_hwdata;
    wire        data_hgrant = 1'b1; // Default granted
    wire        data_hready;
    wire [31:0] data_hrdata;
    wire        data_hresp;

    top_piplined uut (
        .clk(clk),
        .rstn(rstn),
        .instr_htrans(instr_htrans),
        .instr_haddr(instr_haddr),
        .instr_hwrite(instr_hwrite),
        .instr_hsize(instr_hsize),
        .instr_hwdata(instr_hwdata),
        .instr_hready(instr_hready),
        .instr_hrdata(instr_hrdata),
        .instr_hresp(instr_hresp),
        .data_hbusreq(data_hbusreq),
        .data_htrans(data_htrans),
        .data_haddr(data_haddr),
        .data_hwrite(data_hwrite),
        .data_hsize(data_hsize),
        .data_hwdata(data_hwdata),
        .data_hgrant(data_hgrant),
        .data_hready(data_hready),
        .data_hrdata(data_hrdata),
        .data_hresp(data_hresp)
    );

    instruction_mem #(
        .HEX_FILE("../firmware/program.hex")
    ) ROM (
        .HCLK(clk),
        .HRESETn(rstn),
        .HADDR(instr_haddr),
        .HTRANS(instr_htrans),
        .HWRITE(instr_hwrite),
        .HSIZE(instr_hsize),
        .HWDATA(instr_hwdata),
        .HREADY(instr_hready),
        .HREADYOUT(instr_hready),
        .HRDATA(instr_hrdata),
        .HRESP(instr_hresp)
    );

    data_mem mem (
        .HCLK(clk),
        .HRESETn(rstn),
        .HADDR(data_haddr),
        .HTRANS(data_htrans),
        .HWRITE(data_hwrite),
        .HSIZE(data_hsize),
        .HWDATA(data_hwdata),
        .HREADY(data_hready),
        .HREADYOUT(data_hready),
        .HRDATA(data_hrdata),
        .HRESP(data_hresp)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0; rstn = 0;
        #20;
        rstn = 1; // Release reset

        // Wait until completion marker is written to RAM[254]
        // or a timeout occurs
        fork
            begin
                wait(mem.ram[254] == 32'hABCD1234);
                #100;
                $display("==================================================");
                $display("   RISC-V C Program executed successfully!");
                $display("==================================================");
                $display("--- Base RV32IM C Functionality ---");
                $display("mem[0]  (add: 15 + 7)         = %d (Expected: 22)", mem.ram[0]);
                $display("mem[1]  (sub: 15 - 7)         = %d (Expected: 8)", mem.ram[1]);
                $display("mem[2]  (mul: 15 * 7)         = %d (Expected: 105)", mem.ram[2]);
                $display("mem[3]  (div: 15 / 7)         = %d (Expected: 2)", mem.ram[3]);
                $display("mem[4]  (rem: 15 %% 7)         = %d (Expected: 1)", mem.ram[4]);
                $display("mem[5]  (addi: 15 + 100)      = %d (Expected: 115)", mem.ram[5]);
                $display("mem[6]  (and: 15 & 7)         = %d (Expected: 7)", mem.ram[6]);
                $display("mem[7]  (or: 15 | 7)          = %d (Expected: 15)", mem.ram[7]);
                $display("mem[8]  (xor: 15 ^ 7)         = %d (Expected: 8)", mem.ram[8]);
                $display("mem[9]  (andi: 15 & 15)       = %d (Expected: 15)", mem.ram[9]);
                $display("mem[18] (loop sum 0..9)       = %d (Expected: 45)", mem.ram[18]);
                $display("mem[23] (function call)       = %d (Expected: 22)", mem.ram[23]);
                $display("mem[25] (sb -> lb: 0x7f)      = 0x%h (Expected: 0x7f)", mem.ram[25]);
                $display("mem[27] (sh -> lh: 0x1234)    = 0x%h (Expected: 0x1234)", mem.ram[27]);
                $display("mem[31] (lw: DEADBEEF)        = 0x%h (Expected: 0xdeadbeef)", mem.ram[31]);
                $display("--------------------------------------------------");
                $display("--- Hardware Hazard & Pipeline Stalling Tests ---");
                $display("mem[50] (RAW: Chained ALU Fwd)  = %d (Expected: 120)", mem.ram[50]);
                $display("mem[51] (RAW: Load-Use Stall)   = %d (Expected: 84)", mem.ram[51]);
                $display("mem[52] (RAW: Multiplier Stall) = %d (Expected: 115)", mem.ram[52]);
                $display("mem[53] (RAW: Divider Stall)    = %d (Expected: 109)", mem.ram[53]);
                $display("mem[54] (RAW: MUL -> Store SW)  = %d (Expected: 75)", mem.ram[54]);
                $display("mem[55] (RAW: DIV -> Branch)    = %d (Expected: 1)", mem.ram[55]);
                $display("mem[56] (WAR: Write-After-Read) = %d (Expected: 1)", mem.ram[56]);
                $display("mem[57] (WAW: MUL -> ADDI)      = %d (Expected: 777)", mem.ram[57]);
                $display("mem[58] (WAW: ALU Back-to-Back) = %d (Expected: 333)", mem.ram[58]);
                $display("mem[59] (Mixed Multi-Unit Stress)= %d (Expected: 203)", mem.ram[59]);
                $display("==================================================");

                // Verification check
                if (mem.ram[50] == 120 && mem.ram[51] == 84 && mem.ram[52] == 115 &&
                    mem.ram[53] == 109 && mem.ram[54] == 75 && mem.ram[55] == 1 &&
                    mem.ram[56] == 1 && mem.ram[57] == 777 && mem.ram[58] == 333 &&
                    mem.ram[59] == 203) begin
                    $display(">>> ALL HARDWARE HAZARD & STALLING TESTS PASSED! <<<");
                end else begin
                    $display(">>> ERROR: ONE OR MORE HAZARD TESTS FAILED! <<<");
                end
                $display("==================================================");
                $finish;
            end
            begin
                #200000; // Timeout after 20,000 clock cycles
                $display("--------------------------------------------------");
                $display("ERROR: Simulation timed out (completion marker not found).");
                $display("Current RAM[254] value: 0x%h", mem.ram[254]);
                $display("--------------------------------------------------");
                $display("mem[50] (RAW: Chained ALU Fwd)  = %d (Expected: 120)", mem.ram[50]);
                $display("mem[51] (RAW: Load-Use Stall)   = %d (Expected: 84)", mem.ram[51]);
                $display("mem[52] (RAW: Multiplier Stall) = %d (Expected: 115)", mem.ram[52]);
                $display("mem[53] (RAW: Divider Stall)    = %d (Expected: 109)", mem.ram[53]);
                $display("mem[54] (RAW: MUL -> Store SW)  = %d (Expected: 75)", mem.ram[54]);
                $display("mem[55] (RAW: DIV -> Branch)    = %d (Expected: 1)", mem.ram[55]);
                $display("mem[56] (WAR: Write-After-Read) = %d (Expected: 1)", mem.ram[56]);
                $display("mem[57] (WAW: MUL -> ADDI)      = %d (Expected: 777)", mem.ram[57]);
                $display("mem[58] (WAW: ALU Back-to-Back) = %d (Expected: 333)", mem.ram[58]);
                $display("mem[59] (Mixed Multi-Unit Stress)= %d (Expected: 203)", mem.ram[59]);
                $finish;
            end
        join
    end

    initial begin
        $dumpfile("c_sim.vcd");
        $dumpvars(0, tb_c);
        // $monitor("Time=%0t PC=%h if_id_instr=%h if_id_pc=%h x_m_instr_type=%h alu_A=%h alu_B=%h alu_res=%h write_data=%h write_back_data=%h sp=%h x10=%h x11=%h",
        //          $time, uut.pc, uut.if_id_instr, uut.if_id_pc, uut.x_m_instr_type, uut.alu_unit.A, uut.alu_unit.B, uut.alu_unit.result, uut.write_data, uut.write_back_data, uut.reg_file.registers[2], uut.reg_file.registers[10], uut.reg_file.registers[11]);
    end
endmodule
