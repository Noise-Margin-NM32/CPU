`timescale 1ns/1ps
module debug_tb();
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

        // Monitor key signals every cycle
        repeat(10) begin
            @(posedge clk);
            #1;
            $display("T=%0t PC=%h IF_ID=%h | id_ex: alu_en=%b alu_op=%b sel_a=x%0d sel_b=x%0d wr_reg=x%0d en_wr=%b type=%b | ALU: A=%h B=%h res=%h | RD1=%h RD2=%h | WB=%h",
                $time, uut.pc, uut.if_id_instr,
                uut.id_ex_alu_en, uut.id_ex_alu_op, uut.id_ex_reg_sel_a, uut.id_ex_reg_sel_b, uut.id_ex_write_reg, uut.id_ex_en_write, uut.id_ex_instr_type,
                uut.alu_A, uut.alu_B, uut.alu_result,
                uut.read_data1, uut.read_data2,
                uut.write_back_data);
        end

        $display("x1=%h x2=%h x6=%h", uut.reg_file.registers[1], uut.reg_file.registers[2], uut.reg_file.registers[6]);
        $finish;
    end
endmodule
