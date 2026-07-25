`timescale 1ns/1ps
module tb_c();
    reg clk, rstn;
    top_piplined uut (.clk(clk), .rstn(rstn));

    always #5 clk = ~clk;

    initial begin
        clk = 0; rstn = 0;
        #20;
        rstn = 1; // Release reset

        // Wait until completion marker is written to RAM[254]
        // or a timeout occurs
        fork
            begin
                wait(uut.mem.ram[254] == 32'hABCD1234);
                #100;
                $display("==================================================");
                $display("   RISC-V C Program executed successfully!");
                $display("==================================================");
                $display("mem[0]  (add: 15 + 7)         = %d (Expected: 22)", uut.mem.ram[0]);
                $display("mem[1]  (sub: 15 - 7)         = %d (Expected: 8)", uut.mem.ram[1]);
                $display("mem[2]  (mul: 15 * 7)         = %d (Expected: 105)", uut.mem.ram[2]);
                $display("mem[3]  (div: 15 / 7)         = %d (Expected: 2)", uut.mem.ram[3]);
                $display("mem[4]  (rem: 15 %% 7)         = %d (Expected: 1)", uut.mem.ram[4]);
                $display("mem[5]  (addi: 15 + 100)      = %d (Expected: 115)", uut.mem.ram[5]);
                $display("mem[6]  (and: 15 & 7)         = %d (Expected: 7)", uut.mem.ram[6]);
                $display("mem[7]  (or: 15 | 7)          = %d (Expected: 15)", uut.mem.ram[7]);
                $display("mem[8]  (xor: 15 ^ 7)         = %d (Expected: 8)", uut.mem.ram[8]);
                $display("mem[9]  (andi: 15 & 15)       = %d (Expected: 15)", uut.mem.ram[9]);
                $display("mem[18] (loop sum 0..9)       = %d (Expected: 45)", uut.mem.ram[18]);
                $display("mem[23] (function call)       = %d (Expected: 22)", uut.mem.ram[23]);
                $display("mem[25] (sb -> lb: 0x7f)      = 0x%h (Expected: 0x7f)", uut.mem.ram[25]);
                $display("mem[27] (sh -> lh: 0x1234)    = 0x%h (Expected: 0x1234)", uut.mem.ram[27]);
                $display("mem[31] (lw: DEADBEEF)        = 0x%h (Expected: 0xdeadbeef)", uut.mem.ram[31]);
                $display("==================================================");
                $finish;
            end
            begin
                #100000; // Timeout after 10,000 clock cycles
                $display("--------------------------------------------------");
                $display("ERROR: Simulation timed out (completion marker not found).");
                $display("Current RAM[254] value: 0x%h", uut.mem.ram[254]);
                $display("--------------------------------------------------");
                $finish;
            end
        join
    end

    initial begin
        $dumpfile("c_sim.vcd");
        $dumpvars(0, tb_c);
        $monitor("Time=%0t PC=%h if_id_instr=%h if_id_pc=%h id_ex_instr_type=%h alu_A=%h alu_B=%h alu_res=%h write_data=%h write_back_data=%h sp=%h x10=%h x11=%h",
                 $time, uut.pc, uut.if_id_instr, uut.if_id_pc, uut.id_ex_instr_type, uut.alu_unit.A, uut.alu_unit.B, uut.alu_unit.result, uut.write_data, uut.write_back_data, uut.reg_file.registers[2], uut.reg_file.registers[10], uut.reg_file.registers[11]);
    end
endmodule
