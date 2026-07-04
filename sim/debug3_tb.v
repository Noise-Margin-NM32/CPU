`timescale 1ns/1ps
module debug3_tb();
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
        uut.ROM.rom[0] = 32'h00208333; // add x6, x1, x2
        uut.ROM.rom[1] = 32'h402083B3; // sub x7, x1, x2

        $display("--- After init (t=%0t) ---", $time);
        $display("  x1=%h x2=%h", uut.reg_file.registers[1], uut.reg_file.registers[2]);
        $display("  PC=%h rom[0]=%h rom[1]=%h", uut.pc, uut.ROM.rom[0], uut.ROM.rom[1]);

        repeat(8) begin
            @(posedge clk); #1;
            $display("T=%0t PC=%h | IF_ID=%h | id_ex: en=%b op=%b wreg=x%0d enwr=%b type=%b sela=x%0d selb=x%0d | rd1=%h rd2=%h | ALU_res=%h | WB=%h | x1=%h x2=%h x6=%h x7=%h",
                $time, uut.pc, uut.if_id_instr,
                uut.id_ex_alu_en, uut.id_ex_alu_op, uut.id_ex_write_reg, uut.id_ex_en_write, uut.id_ex_instr_type, uut.id_ex_reg_sel_a, uut.id_ex_reg_sel_b,
                uut.read_data1, uut.read_data2,
                uut.alu_result, uut.write_back_data,
                uut.reg_file.registers[1], uut.reg_file.registers[2], uut.reg_file.registers[6], uut.reg_file.registers[7]);
        end
        $finish;
    end
endmodule
