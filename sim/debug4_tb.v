`timescale 1ns/1ps
module debug4_tb();
    reg clk, rst;
    top_piplined uut (.clk(clk), .rst(rst));
    always #5 clk = ~clk;

    initial begin
        clk = 0; rst = 0;
        repeat(1) @(posedge clk);
        rst = 1;
        #1;

        uut.reg_file.registers[1] = 32'h00000005;
        uut.reg_file.registers[2] = 32'h00000003;
        uut.reg_file.registers[4] = 32'hFFFFFFFE;
        uut.ROM.rom[0] = 32'h00208333; // add x6, x1, x2
        uut.ROM.rom[1] = 32'h402083B3; // sub x7, x1, x2
        uut.ROM.rom[2] = 32'h00209433; // sll x8, x1, x2

        repeat(8) begin
            @(posedge clk); #1;
            $display("T=%0t | PC=%h | instruction(ROM out)=%h | if_id_instr(CU in)=%h | id_ex: alu_en=%b op=%b wreg=x%0d | x6=%h x7=%h x8=%h",
                $time, uut.pc, uut.instruction, uut.if_id_instr,
                uut.id_ex_alu_en, uut.id_ex_alu_op, uut.id_ex_write_reg,
                uut.reg_file.registers[6], uut.reg_file.registers[7], uut.reg_file.registers[8]);
        end
        $finish;
    end
endmodule
