`timescale 1ns/1ps
module top_tb();
    reg clk, rst;
            reg test_status [1:45];
    string test_names [1:45];
    
    integer idx;
    initial begin
        test_names[1]  = "ADD";
        test_names[2]  = "SUB";
        test_names[3]  = "SLL";
        test_names[4]  = "SLT";
        test_names[5]  = "SLTU";
        test_names[6]  = "XOR";
        test_names[7]  = "SRL";
        test_names[8]  = "SRA";
        test_names[9]  = "OR";
        test_names[10] = "AND";
        test_names[11] = "ADDI";
        test_names[12] = "SLLI";
        test_names[13] = "SLTI";
        test_names[14] = "XORI";
        test_names[15] = "SRLI";
        test_names[16] = "SRAI";
        test_names[17] = "ORI";
        test_names[18] = "ANDI";
        test_names[19] = "LB";
        test_names[20] = "LH";
        test_names[21] = "LW";
        test_names[22] = "LBU";
        test_names[23] = "LHU";
        test_names[24] = "SW";
        test_names[25] = "SH";
        test_names[26] = "SB";
        test_names[27] = "BEQ Not Taken";
        test_names[28] = "BEQ Taken";
        test_names[29] = "BNE Taken";
        test_names[30] = "BLT Taken";
        test_names[31] = "BGE Taken";
        test_names[32] = "BLTU Not Taken";
        test_names[33] = "BGEU Taken";
        test_names[34] = "LUI";
        test_names[35] = "AUIPC";
        test_names[36] = "JAL";
        test_names[37] = "JALR";
        test_names[38] = "MUL";
        test_names[39] = "MULH";
        test_names[40] = "MULHSU";
        test_names[41] = "MULHU";
        test_names[42] = "DIV";
        test_names[43] = "DIVU";
        test_names[44] = "REM";
        test_names[45] = "REMU";
        
        for (idx = 1; idx <= 45; idx = idx + 1) begin
            test_status[idx] = 1'b0;
        end
    end

    integer passed_tests = 0;
    integer failed_tests = 0;

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

        // S-Type (Store) Instructions (Base x1=5)
    uut.mem.ram[17] = 32'hA5A5A5A5; // Initial value at addr 17
    uut.mem.ram[18] = 32'h5A5A5A5A; // Initial value at addr 18
    uut.mem.ram[19] = 32'h12345678; // Initial value at addr 19


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

    // IL-Type (Load) Instructions (Base x1=5, Offset=35, Addr=40, reads mem[10]=0x89ABCDEF)
    uut.ROM.rom[18] = 32'h02308C03; // lb x24, 35(x1)
    uut.ROM.rom[19] = 32'h02309C83; // lh x25, 35(x1)
    uut.ROM.rom[20] = 32'h0230AD03; // lw x26, 35(x1)
    uut.ROM.rom[21] = 32'h0230CD83; // lbu x27, 35(x1)
    uut.ROM.rom[22] = 32'h0230DE03; // lhu x28, 35(x1)


    // sw x3, 63(x1) -> RAM[17] = x3 (7)
    uut.ROM.rom[23] = 32'h0230AFA3;
    // sh x3, 67(x1) -> RAM[18][15:0] = x3[15:0] (7)
    uut.ROM.rom[24] = 32'h043091A3;
    // sb x3, 71(x1) -> RAM[19][7:0] = x3[7:0] (7)
    uut.ROM.rom[25] = 32'h043083A3;

    // Test 27: BEQ Not Taken (x1=5, x2=3 are not equal)
    uut.ROM.rom[26] = 32'h00208663; // beq x1, x2, 12 (Not Taken, PC goes to 27)
    uut.ROM.rom[27] = 32'h00A00F13; // addi x30, x0, 10 (executed, x30 = 10)
    uut.ROM.rom[28] = 32'h00000013; // nop
    uut.ROM.rom[29] = 32'h00000013; // nop

    // Setup x29 = 5 for Test 28
    uut.reg_file.registers[29] = 32'h00000005;

    // Test 28: BEQ Taken (x1=5, x29=5 are equal)
    uut.ROM.rom[30] = 32'h01D08863; // beq x1, x29, 16 (Taken, PC goes to index 34)
    uut.ROM.rom[31] = 32'h01400F93; // addi x31, x0, 20 (should be skipped, so x31 remains 0 or doesn't get 20)
    uut.ROM.rom[32] = 32'h00000013; // nop
    uut.ROM.rom[33] = 32'h00000013; // nop
    uut.ROM.rom[34] = 32'h01E00F93; // addi x31, x0, 30 (executed, x31 = 30)

    // Test 29: BNE Taken (x1=5, x2=3 are not equal)
    uut.ROM.rom[35] = 32'h00209863; // bne x1, x2, 16 (Taken, PC goes to index 39)
    uut.ROM.rom[36] = 32'h02800093; // addi x1, x0, 40 (should be skipped)
    uut.ROM.rom[37] = 32'h00000013; // nop
    uut.ROM.rom[38] = 32'h00000013; // nop
    uut.ROM.rom[39] = 32'h03200093; // addi x1, x0, 50 (executed, x1 = 50)


    // Test 30: BLT Taken (x5=-5, x4=-2 are signed, -5 < -2 is true)
    uut.ROM.rom[40] = 32'h0042C863; // blt x5, x4, 16 (Taken, PC goes to index 44)
    uut.ROM.rom[41] = 32'h04600113; // addi x2, x0, 70 (should be skipped)
    uut.ROM.rom[42] = 32'h00000013; // nop
    uut.ROM.rom[43] = 32'h00000013; // nop
    uut.ROM.rom[44] = 32'h03C00113; // addi x2, x0, 60 (executed, x2 = 60)

    // Test 31: BGE Taken (x4=-2, x5=-5 are signed, -2 >= -5 is true)
    uut.ROM.rom[45] = 32'h0052D863; // bge x4, x5, 16 (Taken, PC goes to index 49)
    uut.ROM.rom[46] = 32'h05A00193; // addi x3, x0, 90 (should be skipped)
    uut.ROM.rom[47] = 32'h00000013; // nop
    uut.ROM.rom[48] = 32'h00000013; // nop
    uut.ROM.rom[49] = 32'h05000193; // addi x3, x0, 80 (executed, x3 = 80)

    // Test 32: BLTU Not Taken (x4=100, x1=50 are unsigned, 100 < 50 is false)
    uut.ROM.rom[50] = 32'h00126863; // bltu x4, x1, 16 (Not Taken, PC goes to 51)
    uut.ROM.rom[51] = 32'h06400213; // addi x4, x0, 100 (executed, x4 = 100)
    uut.ROM.rom[52] = 32'h00000013; // nop
    uut.ROM.rom[53] = 32'h00000013; // nop
    uut.ROM.rom[54] = 32'h06E00E93; // addi x29, x0, 110 (should be skipped)

    // Test 33: BGEU Taken (x4=100, x1=50 are unsigned, 100 >= 50 is true)
    uut.ROM.rom[55] = 32'h00127863; // bgeu x4, x1, 16 (Taken, PC goes to index 59)
    uut.ROM.rom[56] = 32'h08200293; // addi x5, x0, 130 (should be skipped)
    uut.ROM.rom[57] = 32'h00000013; // nop
    uut.ROM.rom[58] = 32'h00000013; // nop
    uut.ROM.rom[59] = 32'h07800293; // addi x5, x0, 120 (executed, x5 = 120)

    // Test 34: LUI (Load Upper Immediate)
    uut.ROM.rom[60] = 32'h12345EB7; // lui x29, 32'h12345
    uut.ROM.rom[61] = 32'h05D02823; // sw x29, 80(x0) (stores LUI result at RAM[20])

    // Test 35: AUIPC (Add Upper Immediate to PC)
    // At ROM index 62 (PC = 248), auipc x29, 32'h22222 -> x29 = 32'h22222000 + 248 = 32'h222220F8
    uut.ROM.rom[62] = 32'h22222E97; 
    uut.ROM.rom[63] = 32'h07D02023; // sw x29, 96(x0) (stores AUIPC result at RAM[24])

    // Test 36: JAL (Jump and Link)
    // At ROM index 64 (PC = 256 = 0x100), jal x29, 120 -> jumps to index 100+120 = 220 (PC = 272) and sets x29 = 260
    uut.ROM.rom[64] = 32'h12000EEF; 
    uut.ROM.rom[65] = 32'h09D02823; // sw x29, 144(x0) (stores to RAM[36] - should be skipped!)
    // uut.ROM.rom[66] = 32'h00000013; // nop
    // uut.ROM.rom[67] = 32'h00000013; // nop
    uut.ROM.rom[136] = 32'h07D02823; // sw x29, 112(x0) (stores JAL return address 104 at RAM[28])

    // Test 37: JALR (Jump and Link Register)
    // Setup x29 = 284 (32'h0000011C)
    uut.ROM.rom[137] = 32'h11c00E93; // addi x29, x0, 284
    // At ROM index 70 (PC = 280), jalr x29, x29, 4 -> jumps to target 284 + 4 = 288 (index 72) and sets x29 = 284
    uut.ROM.rom[138] = 32'h004E8EE7; 
    uut.ROM.rom[139] = 32'h0BD02023; // sw x29, 160(x0) (stores to RAM[40] - should be skipped!)
    uut.ROM.rom[140] = 32'h09D02023; // sw x29, 128(x0) (stores JALR return address 284 at RAM[32])

    // // ===== M-Extension Tests =====
    // // Re-setup registers for M-extension tests
    // // After all branches/jumps, x1-x5 have been modified. We load fresh values via ADDI instructions.
    // // ROM[141] onwards: setup registers, then run M instructions

    // // Setup: x1 = 7, x2 = 3, x3 = -5 (0xFFFFFFFB), x4 = -3 (0xFFFFFFFD)
    // uut.ROM.rom[141] = 32'h00700093; // addi x1, x0, 7
    // uut.ROM.rom[142] = 32'h00300113; // addi x2, x0, 3
    // uut.ROM.rom[143] = 32'hFFB00193; // addi x3, x0, -5
    // uut.ROM.rom[144] = 32'hFFD00213; // addi x4, x0, -3

    // // Test 38: MUL x5, x1, x2  -> 7 * 3 = 21 (0x15)
    // // opcode=0110011, funct3=000, funct7=0000001, rd=5, rs1=1, rs2=2
    // uut.ROM.rom[145] = 32'h022082B3; // mul x5, x1, x2

    // // Test 39: MULH x6, x3, x4 -> (-5) * (-3) = 15, upper 32 bits = 0x00000000
    // // opcode=0110011, funct3=001, funct7=0000001, rd=6, rs1=3, rs2=4
    // uut.ROM.rom[146] = 32'h02419333; // mulh x6, x3, x4

    // // Test 40: MULHSU x7, x3, x2 -> (-5) signed * 3 unsigned = -15, upper 32 = 0xFFFFFFFF
    // // opcode=0110011, funct3=010, funct7=0000001, rd=7, rs1=3, rs2=2
    // uut.ROM.rom[147] = 32'h0221A3B3; // mulhsu x7, x3, x2

    // // Test 41: MULHU x8, x1, x2 -> 7 unsigned * 3 unsigned = 21, upper 32 = 0x00000000
    // // opcode=0110011, funct3=011, funct7=0000001, rd=8, rs1=1, rs2=2
    // uut.ROM.rom[148] = 32'h0220B433; // mulhu x8, x1, x2

    // // Test 42: DIV x9, x3, x2 -> (-5) / 3 = -1 (truncated toward zero: -5/3 = -1)
    // // opcode=0110011, funct3=100, funct7=0000001, rd=9, rs1=3, rs2=2
    // uut.ROM.rom[149] = 32'h0221C4B3; // div x9, x3, x2

    // // Test 43: DIVU x10, x1, x2 -> 7 / 3 = 2
    // // opcode=0110011, funct3=101, funct7=0000001, rd=10, rs1=1, rs2=2
    // uut.ROM.rom[150] = 32'h0220D533; // divu x10, x1, x2

    // // Test 44: REM x11, x3, x2 -> (-5) % 3 = -2 (0xFFFFFFFE)
    // // opcode=0110011, funct3=110, funct7=0000001, rd=11, rs1=3, rs2=2
    // uut.ROM.rom[151] = 32'h0221E5B3; // rem x11, x3, x2

    // // Test 45: REMU x12, x1, x2 -> 7 % 3 = 1
    // // opcode=0110011, funct3=111, funct7=0000001, rd=12, rs1=1, rs2=2
    // uut.ROM.rom[152] = 32'h0220F633; // remu x12, x1, x2

    #1500;



    $display("====================");
    $display("Begin Verification");
    $display("====================");

    if (uut.reg_file.registers[6] == 32'h00000008) begin
        $display("Test 1 Passed: ADD");
        passed_tests = passed_tests + 1;
        test_status[1] = 1'b1;
    end else begin
        $display("Test 1 Failed: ADD");
        failed_tests = failed_tests + 1;
        test_status[1] = 1'b0;
    end
    $display("Expected: 0x00000008, Got: 0x%h", uut.reg_file.registers[6]);
    $display("--------------------");

    if (uut.reg_file.registers[7] == 32'h00000002) begin
        $display("Test 2 Passed: SUB");
        passed_tests = passed_tests + 1;
        test_status[2] = 1'b1;
    end else begin
        $display("Test 2 Failed: SUB");
        failed_tests = failed_tests + 1;
        test_status[2] = 1'b0;
    end
    $display("Expected: 0x00000002, Got: 0x%h", uut.reg_file.registers[7]);
    $display("--------------------");

    if (uut.reg_file.registers[8] == 32'h00000028) begin
        $display("Test 3 Passed: SLL");
        passed_tests = passed_tests + 1;
        test_status[3] = 1'b1;
    end else begin
        $display("Test 3 Failed: SLL");
        failed_tests = failed_tests + 1;
        test_status[3] = 1'b0;
    end
    $display("Expected: 0x00000028, Got: 0x%h", uut.reg_file.registers[8]);
    $display("--------------------");

    if (uut.reg_file.registers[9] == 32'h00000001) begin
        $display("Test 4 Passed: SLT");
        passed_tests = passed_tests + 1;
        test_status[4] = 1'b1;
    end else begin
        $display("Test 4 Failed: SLT");
        failed_tests = failed_tests + 1;
        test_status[4] = 1'b0;
    end
    $display("Expected: 0x00000001, Got: 0x%h", uut.reg_file.registers[9]);
    $display("--------------------");

    if (uut.reg_file.registers[10] == 32'h00000000) begin
        $display("Test 5 Passed: SLTU");
        passed_tests = passed_tests + 1;
        test_status[5] = 1'b1;
    end else begin
        $display("Test 5 Failed: SLTU");
        failed_tests = failed_tests + 1;
        test_status[5] = 1'b0;
    end
    $display("Expected: 0x00000000, Got: 0x%h", uut.reg_file.registers[10]);
    $display("--------------------");

    if (uut.reg_file.registers[11] == 32'h00000006) begin
        $display("Test 6 Passed: XOR");
        passed_tests = passed_tests + 1;
        test_status[6] = 1'b1;
    end else begin
        $display("Test 6 Failed: XOR");
        failed_tests = failed_tests + 1;
        test_status[6] = 1'b0;
    end
    $display("Expected: 0x00000006, Got: 0x%h", uut.reg_file.registers[11]);
    $display("--------------------");

    if (uut.reg_file.registers[12] == 32'h00000000) begin
        $display("Test 7 Passed: SRL");
        passed_tests = passed_tests + 1;
        test_status[7] = 1'b1;
    end else begin
        $display("Test 7 Failed: SRL");
        failed_tests = failed_tests + 1;
        test_status[7] = 1'b0;
    end
    $display("Expected: 0x00000000, Got: 0x%h", uut.reg_file.registers[12]);
    $display("--------------------");

    if (uut.reg_file.registers[13] == 32'hFFFFFFFF) begin
        $display("Test 8 Passed: SRA");
        passed_tests = passed_tests + 1;
        test_status[8] = 1'b1;
    end else begin
        $display("Test 8 Failed: SRA");
        failed_tests = failed_tests + 1;
        test_status[8] = 1'b0;
    end
    $display("Expected: 0xFFFFFFFF, Got: 0x%h", uut.reg_file.registers[13]);
    $display("--------------------");

    if (uut.reg_file.registers[14] == 32'h00000007) begin
        $display("Test 9 Passed: OR");
        passed_tests = passed_tests + 1;
        test_status[9] = 1'b1;
    end else begin
        $display("Test 9 Failed: OR");
        failed_tests = failed_tests + 1;
        test_status[9] = 1'b0;
    end
    $display("Expected: 0x00000007, Got: 0x%h", uut.reg_file.registers[14]);
    $display("--------------------");

    if (uut.reg_file.registers[15] == 32'h00000001) begin
        $display("Test 10 Passed: AND");
        passed_tests = passed_tests + 1;
        test_status[10] = 1'b1;
    end else begin
        $display("Test 10 Failed: AND");
        failed_tests = failed_tests + 1;
        test_status[10] = 1'b0;
    end
    $display("Expected: 0x00000001, Got: 0x%h", uut.reg_file.registers[15]);
    $display("--------------------");

    if (uut.reg_file.registers[16] == 32'h0000000F) begin
        $display("Test 11 Passed: ADDI");
        passed_tests = passed_tests + 1;
        test_status[11] = 1'b1;
    end else begin
        $display("Test 11 Failed: ADDI");
        failed_tests = failed_tests + 1;
        test_status[11] = 1'b0;
    end
    $display("Expected: 0x0000000F, Got: 0x%h", uut.reg_file.registers[16]);
    $display("--------------------");

    if (uut.reg_file.registers[17] == 32'h00000014) begin
        $display("Test 12 Passed: SLLI");
        passed_tests = passed_tests + 1;
        test_status[12] = 1'b1;
    end else begin
        $display("Test 12 Failed: SLLI");
        failed_tests = failed_tests + 1;
        test_status[12] = 1'b0;
    end
    $display("Expected: 0x00000014, Got: 0x%h", uut.reg_file.registers[17]);
    $display("--------------------");

    if (uut.reg_file.registers[18] == 32'h00000001) begin
        $display("Test 13 Passed: SLTI");
        passed_tests = passed_tests + 1;
        test_status[13] = 1'b1;
    end else begin
        $display("Test 13 Failed: SLTI");
        failed_tests = failed_tests + 1;
        test_status[13] = 1'b0;
    end
    $display("Expected: 0x00000001, Got: 0x%h", uut.reg_file.registers[18]);
    $display("--------------------");

    if (uut.reg_file.registers[19] == 32'h0000000A) begin
        $display("Test 14 Passed: XORI");
        passed_tests = passed_tests + 1;
        test_status[14] = 1'b1;
    end else begin
        $display("Test 14 Failed: XORI");
        failed_tests = failed_tests + 1;
        test_status[14] = 1'b0;
    end
    $display("Expected: 0x0000000A, Got: 0x%h", uut.reg_file.registers[19]);
    $display("--------------------");

    if (uut.reg_file.registers[20] == 32'h00000002) begin
        $display("Test 15 Passed: SRLI");
        passed_tests = passed_tests + 1;
        test_status[15] = 1'b1;
    end else begin
        $display("Test 15 Failed: SRLI");
        failed_tests = failed_tests + 1;
        test_status[15] = 1'b0;
    end
    $display("Expected: 0x00000002, Got: 0x%h", uut.reg_file.registers[20]);
    $display("--------------------");

    if (uut.reg_file.registers[21] == 32'hFFFFFFFF) begin
        $display("Test 16 Passed: SRAI");
        passed_tests = passed_tests + 1;
        test_status[16] = 1'b1;
    end else begin
        $display("Test 16 Failed: SRAI");
        failed_tests = failed_tests + 1;
        test_status[16] = 1'b0;
    end
    $display("Expected: 0xFFFFFFFF, Got: 0x%h", uut.reg_file.registers[21]);
    $display("--------------------");

    if (uut.reg_file.registers[22] == 32'h0000000D) begin
        $display("Test 17 Passed: ORI");
        passed_tests = passed_tests + 1;
        test_status[17] = 1'b1;
    end else begin
        $display("Test 17 Failed: ORI");
        failed_tests = failed_tests + 1;
        test_status[17] = 1'b0;
    end
    $display("Expected: 0x0000000D, Got: 0x%h", uut.reg_file.registers[22]);
    $display("--------------------");

    if (uut.reg_file.registers[23] == 32'h00000004) begin
        $display("Test 18 Passed: ANDI");
        passed_tests = passed_tests + 1;
        test_status[18] = 1'b1;
    end else begin
        $display("Test 18 Failed: ANDI");
        failed_tests = failed_tests + 1;
        test_status[18] = 1'b0;
    end
    $display("Expected: 0x00000004, Got: 0x%h", uut.reg_file.registers[23]);
    $display("--------------------");

    if (uut.reg_file.registers[24] == 32'hFFFFFFEF) begin
        $display("Test 19 Passed: LB");
        passed_tests = passed_tests + 1;
        test_status[19] = 1'b1;
    end else begin
        $display("Test 19 Failed: LB");
        failed_tests = failed_tests + 1;
        test_status[19] = 1'b0;
    end
    $display("Expected: 0xFFFFFFEF, Got: 0x%h", uut.reg_file.registers[24]);
    $display("--------------------");

    if (uut.reg_file.registers[25] == 32'hFFFFCDEF) begin
        $display("Test 20 Passed: LH");
        passed_tests = passed_tests + 1;
        test_status[20] = 1'b1;
    end else begin
        $display("Test 20 Failed: LH");
        failed_tests = failed_tests + 1;
        test_status[20] = 1'b0;
    end
    $display("Expected: 0xFFFFCDEF, Got: 0x%h", uut.reg_file.registers[25]);
    $display("--------------------");

    if (uut.reg_file.registers[26] == 32'h89ABCDEF) begin
        $display("Test 21 Passed: LW");
        passed_tests = passed_tests + 1;
        test_status[21] = 1'b1;
    end else begin
        $display("Test 21 Failed: LW");
        failed_tests = failed_tests + 1;
        test_status[21] = 1'b0;
    end
    $display("Expected: 0x89ABCDEF, Got: 0x%h", uut.reg_file.registers[26]);
    $display("--------------------");

    if (uut.reg_file.registers[27] == 32'h000000EF) begin
        $display("Test 22 Passed: LBU");
        passed_tests = passed_tests + 1;
        test_status[22] = 1'b1;
    end else begin
        $display("Test 22 Failed: LBU");
        failed_tests = failed_tests + 1;
        test_status[22] = 1'b0;
    end
    $display("Expected: 0x000000EF, Got: 0x%h", uut.reg_file.registers[27]);
    $display("--------------------");

    if (uut.reg_file.registers[28] == 32'h0000CDEF) begin
        $display("Test 23 Passed: LHU");
        passed_tests = passed_tests + 1;
        test_status[23] = 1'b1;
    end else begin
        $display("Test 23 Failed: LHU");
        failed_tests = failed_tests + 1;
        test_status[23] = 1'b0;
    end
    $display("Expected: 0x0000CDEF, Got: 0x%h", uut.reg_file.registers[28]);
    $display("--------------------");
    
    // Test 24: SW
    if (uut.mem.ram[17] == 32'h00000007) begin
        $display("Test 24 Passed: SW");
        passed_tests = passed_tests + 1;
        test_status[24] = 1'b1;
    end else begin
        $display("Test 24 Failed: SW");
        failed_tests = failed_tests + 1;
        test_status[24] = 1'b0;
    end
    $display("Expected: 0x00000007, Got: 0x%h", uut.mem.ram[17]);
    $display("--------------------");

    // Test 25: SH
    if (uut.mem.ram[18] == 32'h5a5a0007) begin
        $display("Test 25 Passed: SH");
        passed_tests = passed_tests + 1;
        test_status[25] = 1'b1;
    end else begin
        $display("Test 25 Failed: SH");
        failed_tests = failed_tests + 1;
        test_status[25] = 1'b0;
    end
    $display("Expected: 0x5a5a0007, Got: 0x%h", uut.mem.ram[18]);
    $display("--------------------");

    // Test 26: SB
    if (uut.mem.ram[19] == 32'h12345607) begin
        $display("Test 26 Passed: SB");
        passed_tests = passed_tests + 1;
        test_status[26] = 1'b1;
    end else begin
        $display("Test 26 Failed: SB");
        failed_tests = failed_tests + 1;
        test_status[26] = 1'b0;
    end
    $display("Expected: 0x12345607, Got: 0x%h", uut.mem.ram[19]);
    $display("--------------------");

    // Test 27: BEQ Not Taken
    if (uut.reg_file.registers[30] == 32'h0000000A) begin
        $display("Test 27 Passed: BEQ Not Taken");
        passed_tests = passed_tests + 1;
        test_status[27] = 1'b1;
    end else begin
        $display("Test 27 Failed: BEQ Not Taken");
        failed_tests = failed_tests + 1;
        test_status[27] = 1'b0;
    end
    $display("Expected: 0x0000000A, Got: 0x%h", uut.reg_file.registers[30]);
    $display("--------------------");

    // Test 28: BEQ Taken
    if (uut.reg_file.registers[31] == 32'h0000001E) begin
        $display("Test 28 Passed: BEQ Taken");
        passed_tests = passed_tests + 1;
        test_status[28] = 1'b1;
    end else begin
        $display("Test 28 Failed: BEQ Taken");
        failed_tests = failed_tests + 1;
        test_status[28] = 1'b0;
    end
    $display("Expected: 0x0000001E, Got: 0x%h", uut.reg_file.registers[31]);
    $display("--------------------");

    // Test 29: BNE Taken
    if (uut.reg_file.registers[1] == 32'h00000032) begin
        $display("Test 29 Passed: BNE Taken");
        passed_tests = passed_tests + 1;
        test_status[29] = 1'b1;
    end else begin
        $display("Test 29 Failed: BNE Taken");
        failed_tests = failed_tests + 1;
        test_status[29] = 1'b0;
    end
    $display("Expected: 0x00000032, Got: 0x%h", uut.reg_file.registers[1]);
    $display("--------------------");

    // Test 30: BLT Taken
    if (uut.reg_file.registers[2] == 32'h0000003C) begin
        $display("Test 30 Passed: BLT Taken");
        passed_tests = passed_tests + 1;
        test_status[30] = 1'b1;
    end else begin
        $display("Test 30 Failed: BLT Taken");
        failed_tests = failed_tests + 1;
        test_status[30] = 1'b0;
    end
    $display("Expected: 0x0000003C, Got: 0x%h", uut.reg_file.registers[2]);
    $display("--------------------");

    // Test 31: BGE Taken
    if (uut.reg_file.registers[3] == 32'h00000050) begin
        $display("Test 31 Passed: BGE Taken");
        passed_tests = passed_tests + 1;
        test_status[31] = 1'b1;
    end else begin
        $display("Test 31 Failed: BGE Taken");
        failed_tests = failed_tests + 1;
        test_status[31] = 1'b0;
    end
    $display("Expected: 0x00000050, Got: 0x%h", uut.reg_file.registers[3]);
    $display("--------------------");

    // Test 32: BLTU Not Taken
    if (uut.reg_file.registers[4] == 32'h00000064) begin
        $display("Test 32 Passed: BLTU Not Taken");
        passed_tests = passed_tests + 1;
        test_status[32] = 1'b1;
    end else begin
        $display("Test 32 Failed: BLTU Not Taken");
        failed_tests = failed_tests + 1;
        test_status[32] = 1'b0;
    end
    $display("Expected: 0x00000064, Got: 0x%h", uut.reg_file.registers[4]);
    $display("--------------------");

    // Test 33: BGEU Taken
    if (uut.reg_file.registers[5] == 32'h00000078) begin
        $display("Test 33 Passed: BGEU Taken");
        passed_tests = passed_tests + 1;
        test_status[33] = 1'b1;
    end else begin
        $display("Test 33 Failed: BGEU Taken");
        failed_tests = failed_tests + 1;
        test_status[33] = 1'b0;
    end
    $display("Expected: 0x00000078, Got: 0x%h", uut.reg_file.registers[5]);
    $display("--------------------");

    // Test 34: LUI
    if (uut.mem.ram[20] == 32'h12345000) begin
        $display("Test 34 Passed: LUI");
        passed_tests = passed_tests + 1;
        test_status[34] = 1'b1;
    end else begin
        $display("Test 34 Failed: LUI");
        failed_tests = failed_tests + 1;
        test_status[34] = 1'b0;
    end
    $display("Expected: 0x12345000, Got: 0x%h", uut.mem.ram[20]);
    $display("--------------------");

    // Test 35: AUIPC
    if (uut.mem.ram[24] == 32'h222220F8) begin
        $display("Test 35 Passed: AUIPC");
        passed_tests = passed_tests + 1;
        test_status[35] = 1'b1;
    end else begin
        $display("Test 35 Failed: AUIPC");
        failed_tests = failed_tests + 1;
        test_status[35] = 1'b0;
    end
    $display("Expected: 0x222220F8, Got: 0x%h", uut.mem.ram[24]);
    $display("--------------------");

    // Test 36: JAL
    if (uut.mem.ram[28] == 32'h00000104 && $isunknown(uut.mem.ram[36])) begin
        $display("Test 36 Passed: JAL");
        passed_tests = passed_tests + 1;
        test_status[36] = 1'b1;
    end else begin
        $display("Test 36 Failed: JAL");
        failed_tests = failed_tests + 1;
        test_status[36] = 1'b0;
    end
    $display("Expected Return: 0x00000104, Got: 0x%h", uut.mem.ram[28]);
    $display("Expected Skip Success (RAM[36]!=0X00000104): Got: 0x%h", uut.mem.ram[36]);
    $display("--------------------");

    // Test 37: JALR
    if (uut.mem.ram[32] == 32'h0000022c && $isunknown(uut.mem.ram[40])) begin
        $display("Test 37 Passed: JALR");
        passed_tests = passed_tests + 1;
        test_status[37] = 1'b1;
    end else begin
        $display("Test 37 Failed: JALR");
        failed_tests = failed_tests + 1;
        test_status[37] = 1'b0;
    end
    // $display(uut.mem.ram[32] == 32'h0000022c);
    // $display($isunknown(uut.mem.ram[40]));
    $display("Expected Return: 0x0000022C, Got: 0x%h", uut.mem.ram[32]);
    $display("Expected Skip Success (RAM[40]=0xXXXXXXXX): Got: 0x%h", uut.mem.ram[40]);
    $display("--------------------");




    // ===== M-Extension Verification =====

    // Test 38: MUL  7 * 3 = 21 = 0x00000015
    if (uut.reg_file.registers[5] == 32'h00000015) begin
        $display("Test 38 Passed: MUL");
        passed_tests = passed_tests + 1;
        test_status[38] = 1'b1;
    end else begin
        $display("Test 38 Failed: MUL");
        failed_tests = failed_tests + 1;
        test_status[38] = 1'b0;
    end
    $display("Expected: 0x00000015, Got: 0x%h", uut.reg_file.registers[5]);
    $display("--------------------");

    // Test 39: MULH  (-5)*(-3)=15, upper 32 = 0x00000000
    if (uut.reg_file.registers[6] == 32'h00000000) begin
        $display("Test 39 Passed: MULH");
        passed_tests = passed_tests + 1;
        test_status[39] = 1'b1;
    end else begin
        $display("Test 39 Failed: MULH");
        failed_tests = failed_tests + 1;
        test_status[39] = 1'b0;
    end
    $display("Expected: 0x00000000, Got: 0x%h", uut.reg_file.registers[6]);
    $display("--------------------");

    // Test 40: MULHSU  (-5 signed) * (3 unsigned) = -15, upper 32 = 0xFFFFFFFF
    if (uut.reg_file.registers[7] == 32'hFFFFFFFF) begin
        $display("Test 40 Passed: MULHSU");
        passed_tests = passed_tests + 1;
        test_status[40] = 1'b1;
    end else begin
        $display("Test 40 Failed: MULHSU");
        failed_tests = failed_tests + 1;
        test_status[40] = 1'b0;
    end
    $display("Expected: 0xFFFFFFFF, Got: 0x%h", uut.reg_file.registers[7]);
    $display("--------------------");

    // Test 41: MULHU  7 * 3 = 21, upper 32 = 0x00000000
    if (uut.reg_file.registers[8] == 32'h00000000) begin
        $display("Test 41 Passed: MULHU");
        passed_tests = passed_tests + 1;
        test_status[41] = 1'b1;
    end else begin
        $display("Test 41 Failed: MULHU");
        failed_tests = failed_tests + 1;
        test_status[41] = 1'b0;
    end
    $display("Expected: 0x00000000, Got: 0x%h", uut.reg_file.registers[8]);
    $display("--------------------");

    // Test 42: DIV  (-5) / 3 = -1 (truncated toward zero) = 0xFFFFFFFF
    if (uut.reg_file.registers[9] == 32'hFFFFFFFF) begin
        $display("Test 42 Passed: DIV");
        passed_tests = passed_tests + 1;
        test_status[42] = 1'b1;
    end else begin
        $display("Test 42 Failed: DIV");
        failed_tests = failed_tests + 1;
        test_status[42] = 1'b0;
    end
    $display("Expected: 0xFFFFFFFF, Got: 0x%h", uut.reg_file.registers[9]);
    $display("--------------------");

    // Test 43: DIVU  7 / 3 = 2 = 0x00000002
    if (uut.reg_file.registers[10] == 32'h00000002) begin
        $display("Test 43 Passed: DIVU");
        passed_tests = passed_tests + 1;
        test_status[43] = 1'b1;
    end else begin
        $display("Test 43 Failed: DIVU");
        failed_tests = failed_tests + 1;
        test_status[43] = 1'b0;
    end
    $display("Expected: 0x00000002, Got: 0x%h", uut.reg_file.registers[10]);
    $display("--------------------");

    // Test 44: REM  (-5) % 3 = -2 = 0xFFFFFFFE
    if (uut.reg_file.registers[11] == 32'hFFFFFFFE) begin
        $display("Test 44 Passed: REM");
        passed_tests = passed_tests + 1;
        test_status[44] = 1'b1;
    end else begin
        $display("Test 44 Failed: REM");
        failed_tests = failed_tests + 1;
        test_status[44] = 1'b0;
    end
    $display("Expected: 0xFFFFFFFE, Got: 0x%h", uut.reg_file.registers[11]);
    $display("--------------------");

    // Test 45: REMU  7 % 3 = 1 = 0x00000001
    if (uut.reg_file.registers[12] == 32'h00000001) begin
        $display("Test 45 Passed: REMU");
        passed_tests = passed_tests + 1;
        test_status[45] = 1'b1;
    end else begin
        $display("Test 45 Failed: REMU");
        failed_tests = failed_tests + 1;
        test_status[45] = 1'b0;
    end
    $display("Expected: 0x00000001, Got: 0x%h", uut.reg_file.registers[12]);
    $display("--------------------");

    $display("====================");
    $display("Final Results");
    $display("====================");
    $display("Passed: %0d / 45", passed_tests);
    $display("Failed: %0d / 45", failed_tests);
    $display("");
    $display("--- Passed Tests ---");
    for (idx = 1; idx <= 45; idx = idx + 1) begin
        if (test_status[idx] == 1'b1) begin
            $display("  - Test %0d: %s", idx, test_names[idx]);
        end
    end
    $display("");
    $display("--- Failed Tests ---");
    for (idx = 1; idx <= 45; idx = idx + 1) begin
        if (test_status[idx] == 1'b0) begin
            $display("  - Test %0d: %s", idx, test_names[idx]);
        end
    end
    $display("====================");
    $finish;
    end

    initial begin
        $dumpfile("cpu_sim.vcd");
        $dumpvars(0, top_tb);
        $monitor("Time=%0t PC=%h if_id_instr=%h if_id_pc=%h id_ex_instr_type=%h id_ex_pc=%h alu_A=%h alu_B=%h alu_res=%h jump=%b branch_taken=%b x17=%h x18=%h x20=%h x21=%h", $time, uut.pc, uut.if_id_instr, uut.if_id_pc, uut.id_ex_instr_type, uut.id_ex_pc, uut.alu_unit.A, uut.alu_unit.B, uut.alu_unit.result, uut.jump, uut.branch_taken, uut.reg_file.registers[17], uut.reg_file.registers[18], uut.reg_file.registers[20], uut.reg_file.registers[21]);
    end
endmodule