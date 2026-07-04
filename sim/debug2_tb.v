`timescale 1ns/1ps
module debug2_tb();
    reg clk, rst;
    top_piplined uut (.clk(clk), .rst(rst));
    always #5 clk = ~clk;

    initial begin
        clk = 0; rst = 0;
        repeat(1) @(posedge clk);
        rst = 1;

        uut.reg_file.registers[1] = 32'h00000005;
        uut.reg_file.registers[2] = 32'h00000003;
        uut.ROM.rom[0] = 32'h00208333; // add x6, x1, x2

        #1;
        $display("T=%0t x1=%h x2=%h rom0=%h PC=%h", $time, uut.reg_file.registers[1], uut.reg_file.registers[2], uut.ROM.rom[0], uut.pc);

        @(posedge clk); #1;
        $display("T=%0t x1=%h x2=%h PC=%h if_id=%h", $time, uut.reg_file.registers[1], uut.reg_file.registers[2], uut.pc, uut.if_id_instr);

        @(posedge clk); #1;
        $display("T=%0t x1=%h x2=%h PC=%h if_id=%h id_ex_alu_en=%b id_ex_sel_a=x%0d id_ex_sel_b=x%0d rd1=%h rd2=%h", $time, uut.reg_file.registers[1], uut.reg_file.registers[2], uut.pc, uut.if_id_instr, uut.id_ex_alu_en, uut.id_ex_reg_sel_a, uut.id_ex_reg_sel_b, uut.read_data1, uut.read_data2);

        @(posedge clk); #1;
        $display("T=%0t x6=%h alu_result=%h wb=%h", $time, uut.reg_file.registers[6], uut.alu_result, uut.write_back_data);

        $finish;
    end
endmodule
