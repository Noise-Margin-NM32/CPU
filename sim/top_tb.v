`timescale 1ns/1ps
module top_tb();
    reg clk, rst;

    top_piplined uut (.clk(clk), .rst(rst));

    always #5 clk = ~clk;
	
    initial begin
        clk = 0; rst = 0;
        repeat(1) @(posedge clk);
         rst = 1; // Release reset

    uut.reg_file.registers[1] = 32'h00000005; // x1 = 5
    uut.reg_file.registers[2] = 32'h00000003; // x2 = 3
    uut.reg_file.registers[3] = 32'h00000007; // x3 = 7
    uut.reg_file.registers[4] = 32'hFFFFFFFE; // x4 = -2
    uut.reg_file.registers[5] = 32'hFFFFFFFB; // x5 = -5

    uut.ROM.rom[0] = 32'h00208333; // add x6, x1, x2
    uut.ROM.rom[1] = 32'h402083B3; // sub x7, x1, x2
    uut.ROM.rom[2] = 32'h00209433; // sll x8, x1, x2
    uut.ROM.rom[3] = 32'h002224B3; // slt x9, x4, x2
    uut.ROM.rom[4] = 32'h0020B533; // sltu x10, x1, x2
    uut.ROM.rom[5] = 32'h0020c5b3; // xor x11, x1, x2
    uut.ROM.rom[6] = 32'h0020d633; // srl x12, x1, x2
    uut.ROM.rom[7] = 32'h402256B3; // sra x13, x4, x2
    uut.ROM.rom[8] = 32'h0020E733; // or x14, x1, x2
    uut.ROM.rom[9] = 32'h0020F7B3; // and x15, x1, x2


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

        $finish;
    end

    initial begin
        $dumpfile("cpu_sim.vcd");
        $dumpvars(0, top_tb);
        // $monitor("Time: %0t | PC: %h | Instr: %h | Reg0: %h", $time, uut.pc, uut.instruction, uut.reg_file.registers[0]);
    end
endmodule
