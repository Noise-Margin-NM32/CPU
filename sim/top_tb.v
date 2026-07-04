`timescale 1ns/1ps
module top_tb();
    reg clk, rst;

    top_piplined uut (.clk(clk), .rst(rst));

    always #5 clk = ~clk;
	
    initial begin
        clk = 0; rst = 0;
        repeat(1) @(negedge clk);
         rst = 1; // Release reset
         #1;
         
//    uut.pc_inst.pc_en = 1'b0;

    uut.reg_file.registers[1] = 32'h00000005; // x1 = 5
    uut.reg_file.registers[2] = 32'h00000003; // x2 = 3
    uut.reg_file.registers[3] = 32'h00000007; // x3 = 7
    uut.reg_file.registers[4] = 32'hFFFFFFFE; // x4 = -2
    uut.reg_file.registers[5] = 32'hFFFFFFFB; // x5 = -5

    uut.mem.ram[10] = 32'h89ABCDEF; // Initialize data memory at addr 10 for Load tests

    uut.ROM.rom[0] = 32'h00208333; // add x6, x1, x2
//    uut.ROM.rom[0] = 32'h402083B3; // sub x7, x1, x2
    uut.ROM.rom[1] = 32'h402083B3; // sub x7, x1, x2
    uut.ROM.rom[2] = 32'h00209433; // sll x8, x1, x2
    uut.ROM.rom[3] = 32'h002224B3; // slt x9, x4, x2
    uut.ROM.rom[4] = 32'h0020B533; // sltu x10, x1, x2
    uut.ROM.rom[5] = 32'h0020c5b3; // xor x11, x1, x2
    uut.ROM.rom[6] = 32'h0020d633; // srl x12, x1, x2
    uut.ROM.rom[7] = 32'h402256B3; // sra x13, x4, x2
    uut.ROM.rom[8] = 32'h0020E733; // or x14, x1, x2
    uut.ROM.rom[9] = 32'h0020F7B3; // and x15, x1, x2

    // IA-Type (Immediate Arithmetic) Instructions
    uut.ROM.rom[10] = 32'h00A08813; // addi x16, x1, 10    (5 + 10 = 15)
    uut.ROM.rom[11] = 32'h00209893; // slli x17, x1, 2     (5 << 2 = 20)
    uut.ROM.rom[12] = 32'h00A0A913; // slti x18, x1, 10    (5 < 10 = 1)
    uut.ROM.rom[13] = 32'h00F0C993; // xori x19, x1, 15    (5 ^ 15 = 10)
    uut.ROM.rom[14] = 32'h0010DA13; // srli x20, x1, 1     (5 >> 1 = 2)
    uut.ROM.rom[15] = 32'h40125A93; // srai x21, x4, 1     (-2 >> 1 = -1)
    uut.ROM.rom[16] = 32'h0080EB13; // ori x22, x1, 8      (5 | 8 = 13)
    uut.ROM.rom[17] = 32'h0040FB93; // andi x23, x1, 4     (5 & 4 = 4)

    // IL-Type (Load) Instructions (Base x1=5, Offset=5, Addr=10, mem[10]=0x89ABCDEF)
    uut.ROM.rom[18] = 32'h00508C03; // lb x24, 5(x1)
    uut.ROM.rom[19] = 32'h00509C83; // lh x25, 5(x1)
    uut.ROM.rom[20] = 32'h0050AD03; // lw x26, 5(x1)
    uut.ROM.rom[21] = 32'h0050CD83; // lbu x27, 5(x1)
    uut.ROM.rom[22] = 32'h0050DE03; // lhu x28, 5(x1)
    
//    uut.pc_inst.pc_en = 1'b1;


    #1000

    $display("====================");
    $display("Begin Verification");
    $display("====================");

    if (uut.reg_file.registers[6] == 32'h00000008) begin
        $display("Test 1 Passed: ADD");
    end else begin
        $display("Test 1 Failed: ADD");
    end
    $display("Expected: 0x00000008, Got: 0x%h", uut.reg_file.registers[6]);
    $display("--------------------");

    if (uut.reg_file.registers[7] == 32'h00000002) begin
        $display("Test 2 Passed: SUB");
    end else begin
        $display("Test 2 Failed: SUB");
    end
    $display("Expected: 0x00000002, Got: 0x%h", uut.reg_file.registers[7]);
    $display("--------------------");

    if (uut.reg_file.registers[8] == 32'h00000028) begin
        $display("Test 3 Passed: SLL");
    end else begin
        $display("Test 3 Failed: SLL");
    end
    $display("Expected: 0x00000028, Got: 0x%h", uut.reg_file.registers[8]);
    $display("--------------------");

    if (uut.reg_file.registers[9] == 32'h00000001) begin
        $display("Test 4 Passed: SLT");
    end else begin
        $display("Test 4 Failed: SLT");
    end
    $display("Expected: 0x00000001, Got: 0x%h", uut.reg_file.registers[9]);
    $display("--------------------");

    if (uut.reg_file.registers[10] == 32'h00000000) begin
        $display("Test 5 Passed: SLTU");
    end else begin
        $display("Test 5 Failed: SLTU");
    end
    $display("Expected: 0x00000000, Got: 0x%h", uut.reg_file.registers[10]);
    $display("--------------------");

    if (uut.reg_file.registers[11] == 32'h00000006) begin
        $display("Test 6 Passed: XOR");
    end else begin
        $display("Test 6 Failed: XOR");
    end
    $display("Expected: 0x00000006, Got: 0x%h", uut.reg_file.registers[11]);
    $display("--------------------");

    if (uut.reg_file.registers[12] == 32'h00000000) begin
        $display("Test 7 Passed: SRL");
    end else begin
        $display("Test 7 Failed: SRL");
    end
    $display("Expected: 0x00000000, Got: 0x%h", uut.reg_file.registers[12]);
    $display("--------------------");

    if (uut.reg_file.registers[13] == 32'hFFFFFFFF) begin
        $display("Test 8 Passed: SRA");
    end else begin
        $display("Test 8 Failed: SRA");
    end
    $display("Expected: 0xFFFFFFFF, Got: 0x%h", uut.reg_file.registers[13]);
    $display("--------------------");

    if (uut.reg_file.registers[14] == 32'h00000007) begin
        $display("Test 9 Passed: OR");
    end else begin
        $display("Test 9 Failed: OR");
    end
    $display("Expected: 0x00000007, Got: 0x%h", uut.reg_file.registers[14]);
    $display("--------------------");

    if (uut.reg_file.registers[15] == 32'h00000001) begin
        $display("Test 10 Passed: AND");
    end else begin
        $display("Test 10 Failed: AND");
    end
    $display("Expected: 0x00000001, Got: 0x%h", uut.reg_file.registers[15]);
    $display("--------------------");

    if (uut.reg_file.registers[16] == 32'h0000000F) begin
        $display("Test 11 Passed: ADDI");
    end else begin
        $display("Test 11 Failed: ADDI");
    end
    $display("Expected: 0x0000000F, Got: 0x%h", uut.reg_file.registers[16]);
    $display("--------------------");

    if (uut.reg_file.registers[17] == 32'h00000014) begin
        $display("Test 12 Passed: SLLI");
    end else begin
        $display("Test 12 Failed: SLLI");
    end
    $display("Expected: 0x00000014, Got: 0x%h", uut.reg_file.registers[17]);
    $display("--------------------");

    if (uut.reg_file.registers[18] == 32'h00000001) begin
        $display("Test 13 Passed: SLTI");
    end else begin
        $display("Test 13 Failed: SLTI");
    end
    $display("Expected: 0x00000001, Got: 0x%h", uut.reg_file.registers[18]);
    $display("--------------------");

    if (uut.reg_file.registers[19] == 32'h0000000A) begin
        $display("Test 14 Passed: XORI");
    end else begin
        $display("Test 14 Failed: XORI");
    end
    $display("Expected: 0x0000000A, Got: 0x%h", uut.reg_file.registers[19]);
    $display("--------------------");

    if (uut.reg_file.registers[20] == 32'h00000002) begin
        $display("Test 15 Passed: SRLI");
    end else begin
        $display("Test 15 Failed: SRLI");
    end
    $display("Expected: 0x00000002, Got: 0x%h", uut.reg_file.registers[20]);
    $display("--------------------");

    if (uut.reg_file.registers[21] == 32'hFFFFFFFF) begin
        $display("Test 16 Passed: SRAI");
    end else begin
        $display("Test 16 Failed: SRAI");
    end
    $display("Expected: 0xFFFFFFFF, Got: 0x%h", uut.reg_file.registers[21]);
    $display("--------------------");

    if (uut.reg_file.registers[22] == 32'h0000000D) begin
        $display("Test 17 Passed: ORI");
    end else begin
        $display("Test 17 Failed: ORI");
    end
    $display("Expected: 0x0000000D, Got: 0x%h", uut.reg_file.registers[22]);
    $display("--------------------");

    if (uut.reg_file.registers[23] == 32'h00000004) begin
        $display("Test 18 Passed: ANDI");
    end else begin
        $display("Test 18 Failed: ANDI");
    end
    $display("Expected: 0x00000004, Got: 0x%h", uut.reg_file.registers[23]);
    $display("--------------------");

    if (uut.reg_file.registers[24] == 32'hFFFFFFEF) begin
        $display("Test 19 Passed: LB");
    end else begin
        $display("Test 19 Failed: LB");
    end
    $display("Expected: 0xFFFFFFEF, Got: 0x%h", uut.reg_file.registers[24]);
    $display("--------------------");

    if (uut.reg_file.registers[25] == 32'hFFFFCDEF) begin
        $display("Test 20 Passed: LH");
    end else begin
        $display("Test 20 Failed: LH");
    end
    $display("Expected: 0xFFFFCDEF, Got: 0x%h", uut.reg_file.registers[25]);
    $display("--------------------");

    if (uut.reg_file.registers[26] == 32'h89ABCDEF) begin
        $display("Test 21 Passed: LW");
    end else begin
        $display("Test 21 Failed: LW");
    end
    $display("Expected: 0x89ABCDEF, Got: 0x%h", uut.reg_file.registers[26]);
    $display("--------------------");

    if (uut.reg_file.registers[27] == 32'h000000EF) begin
        $display("Test 22 Passed: LBU");
    end else begin
        $display("Test 22 Failed: LBU");
    end
    $display("Expected: 0x000000EF, Got: 0x%h", uut.reg_file.registers[27]);
    $display("--------------------");

    if (uut.reg_file.registers[28] == 32'h0000CDEF) begin
        $display("Test 23 Passed: LHU");
    end else begin
        $display("Test 23 Failed: LHU");
    end
    $display("Expected: 0x0000CDEF, Got: 0x%h", uut.reg_file.registers[28]);
    $display("--------------------");

        $finish;
    end

    initial begin
        $dumpfile("cpu_sim.vcd");
        $dumpvars(0, top_tb);
        // $monitor("Time: %0t | PC: %h | Instr: %h | Reg0: %h", $time, uut.pc, uut.instruction, uut.reg_file.registers[0]);
    end
endmodule
