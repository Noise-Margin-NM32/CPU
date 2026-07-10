module control_unit(

    input [31:0] instr,
    // input status_z,

    // now this control unit, based on input generates 
    // all the values of the signals to all the other modules 

    output reg [4:0] reg_sel_a,
    output reg [4:0] reg_sel_b, // to register file reading register number
    output reg en_write, // to register file write enable
    // output reg load_instr,

    output reg [4:0] write_reg, // register choosen to be written in the register file
    output reg [4:0] alu_op,

    // output reg [31:0] data_in, // jump address to program counter
    // output reg [31:0] addr, // address to be read from memeory 

    // output reg en, // enable to pc
    // output reg load, // pc for jump commnad 
    output reg write_en, // enable to write in the memory 

    output reg [19:0] imm, // immediate value 
    
    output reg alu_en, // enable alu computation

    output reg [3:0] instr_type, // to identify the type of instruction (R, I, S, B, U, J) 0000-R, 0001-IL, 0010-IA, 0011-S, 0100-B_1st, 0101-B-2nd, 0110-AUIPC, 0111-LUI, 1000-JAL, 1001-JALR      
    output reg [2:0] load_size // to identify the size of the data to be loaded (byte, half-word, word) 00-byte, 01-half-word, 10-word

);

////////////////////////////////////// The RISC V Base ISA ///////////////////////////////////////////////////////////////////////

//For R -type instructions, the instruction format is as follows:
// 31-25 funct7 | 24-20 rs2 | 19-15 rs1 | 14-12 funct3 | 11-7 rd | 6-0 opcode

//For I -type instructions, the instruction format is as follows:
// 31-20 imm[11:0] | 19-15 rs1 |14-12 funct3 | 11-7 rd | 6-0 opcode

//For S -type instructions, the instruction format is as follows:
// 31-25 imm[11:5] | 24-20 rs2 | 19-15 rs1 | 14-12 funct3 | 11-7 imm[4:0] | 6-0 opcode

//For B -type instructions, the instruction format is as follows:
// 31-25 imm[12|10:5] | 24-20 rs2 | 19-15 rs1 | 14-12 funct3 | 11-7 imm[4:1|11] | 6-0 opcode

//For U -type instructions, the instruction format is as follows:
// 31-12 imm[31:12] | 11-7 rd | 6-0 opcode

//For J -type instructions, the instruction format is as follows:
// 31-12 imm[20|10:1|11|19:12] | 11-7 rd | 6-0 opcode




always @(*) begin
    en_write =0;
    // en =1;
    // load =0;
    // load_instr =0;

    alu_op = 5'b00000;
    write_en =0;
    en_write =0;

    imm = 20'h00000;
    alu_en = 0;



    case(instr[6:0]) // OpCode
        7'b0110011: begin // R type instructions + M type

            reg_sel_a = instr[19:15];
            reg_sel_b = instr[24:20];
            write_reg = instr[11:7];
            imm = 20'h00000; // no immediate value for R type instructions
            alu_en = 1'b1;
            instr_type = 4'b0000; // R type instruction
            write_en = 1'b0; // no write to memory for R type instructions

            case (instr[14:12])
                3'b000: begin
                    case(instr[31:25])
                        7'b0000000: begin // ADD
                            alu_op = 5'b00000;
                        end
                        7'b0100000: begin // SUB
                            alu_op = 5'b00001;
                        end
                        7'b0000001: alu_op = 5'b01010; // MUL
                    endcase
                end

                3'b001: begin
                    if(instr[31:25] == 7'b00000001) alu_op = 5'b01011; // MULH rd = (rs1 * rs2) >> 32
                    else
                        alu_op = 5'b00010; // SLL rd = rs1 << rs2               
                end

                3'b010: begin 
                if(instr[31:25] == 7'b00000001) alu_op = 5'b01100; // MULSU rd = (rs1 * rs2) >> 32
                    else
                        alu_op = 5'b00011;// SLT rd = rs1 < rs2
                end

                3'b011: begin
                    if(instr[31:25] == 7'b00000001) alu_op = 5'b01101; // MULU rd = (rs1 * rs2) >> 32
                    else 
                        alu_op = 5'b00100;// SLTU rd = rs1 < rs2 (unsigned)
                end

                3'b100: begin 
                    if(instr[31:25] == 7'b00000001) alu_op = 5'b01110; // DIV rd = (rs1 / rs2)
                    else 
                        alu_op = 5'b00101;// XOR rd = rs1 ^ rs2
                end

                3'b101: begin 
                    case(instr[31:25])
                        7'b0000000: begin // SRL rd = rs1 >> rs2
                            alu_op = 5'b00110;
                        end
                        7'b0100000: begin // SRA rd = rs1 >> rs2 (arithmetic)
                            alu_op = 5'b00111;
                        end
                        7'b0000001: alu_op = 5'b01111; // DIVU rd = rs1 / rs2
                    endcase
                end

                3'b110: begin 
                    if(instr[31:25] == 7'b00000001) alu_op = 5'b10000; // REM rd = rs1 % rs2
                    else 
                    alu_op = 5'b01000; // OR rd = rs1 | rs2
                end

                3'b111: begin 
                    if(instr[31:25] == 7'b00000001) alu_op = 5'b10001; // REMU rd = rs1 % rs2
                    else
                    alu_op = 5'b01001;// AND rd = rs1 & rs2
                end
            endcase

            en_write=1;
        end 

        7'b0000011: begin   // IL- Type instructions (Load)
            write_reg = instr[11:7];
            reg_sel_a = instr[19:15];
            reg_sel_b = 5'b00000; 
            write_en = 1'b0; // no write to memory for load instructions

            imm = {{8{instr[31]}}, instr[31:20]}; // immediate value for I type instructions: SignExt{imm[11:0]}

            // load_instr = 1;
            instr_type = 4'b0001; // IL type instruction
            alu_op = 5'b00000; // ADD / SUB operation to calculate address
            en_write = 1;
            alu_en = 1;
            case(instr[14:12])
                3'b000: load_size = 3'b000; //LB: rd = Mem[rs1 + imm]
                3'b001: load_size = 3'b001; //LH: rd = Mem[rs1 + imm]
                3'b010: load_size = 3'b010; //LW: rd = Mem[rs1 + imm]
                3'b100: load_size = 3'b011; //LBU: rd = Mem[rs1 + imm]
                3'b101: load_size = 3'b100; //LHU: rd = Mem[rs1 + imm]
            endcase
        end

        7'b0010011: begin   // IA- Type instructions (Immediate Arithmetic) 
            write_reg = instr[11:7];
            reg_sel_a = instr[19:15];
            reg_sel_b = 5'b00000; 
            write_en = 1'b0; // no write to memory for load instructions

            imm = {{8{instr[31]}}, instr[31:20]}; // immediate value for I type instructions: SignExt{imm[11:0]}

            // load_instr = 1;
            instr_type = 4'b0010; // IA type instruction
            en_write = 1;
            alu_en = 1;

            case(instr[14:12])
                3'b000: alu_op = 5'b00000; // ADDI: rd = rs1 + signExt(imm)
                3'b001: alu_op = 5'b00010; // SLLI: rd = (rs1 << uimm)
                3'b010: alu_op = 5'b00011; // SLTI: rd = (rs1 < signExt(imm))
                3'b011: alu_op = 5'b00100; // SLTIU: rd = (rs1 < signExt(imm)) unsigned
                3'b100: alu_op = 5'b00101; // XORI: rd = rs1 ^ signExt(imm)
                3'b101: begin
                    case(instr[31:25])
                        7'b0000000: alu_op = 5'b00110; // SRLI: rd = (rs1 >> uimm)
                        7'b0100000: alu_op = 5'b00111; // SRAI: rd = (rs1 >> uimm) arithmetic
                    endcase
                end
                3'b110: alu_op = 5'b01000; // ORI: rd = rs1 | signExt(imm)
                3'b111: alu_op = 5'b01001; // ANDI: rd = rs1 & signExt(imm)
            endcase
        end

        7'b0100011: begin   //S type instructions (Store)
            write_reg = 5'b00000; // no write to register file for store instructions
            write_en = 1'b1;
            reg_sel_a = instr[19:15];
            reg_sel_b = instr[24:20];
            imm = {{8{instr[31]}}, instr[31:25], instr[11:7]};
            instr_type = 4'b0011;
            alu_en = 1'b1;
            alu_op = 5'b00000;

            case(instr[14:12])
                3'b000: load_size = 3'b000;//SB
                3'b001: load_size = 3'b001;//SH
                3'b010: load_size = 3'b010;//SW
            endcase

            
        end

        7'b1100011: begin  // B type instructions (Branch)/
            write_reg = 5'b00000; // no write to register file for branch instructions
            write_en = 1'b0; // no write to memory for branch instructions
            reg_sel_a = instr[19:15];
            reg_sel_b = instr[24:20];
            imm = {{7{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0}; // SignExt{imm[12|10:5|4:1|11|0]}
            alu_en = 1'b1;
            // alu_op = 4'b0001; // SUB operation to compare rs1 and rs2
            // write_en = 1'b0; // no write to memory for branch instructions
            // instr_type = 4'b0100; // B type instruction
            if (instr_type == 4'b0100) begin
                instr_type = 4'b0101; // B type instruction (2nd part)
                alu_op = 5'b00000; // ADD operation to calculate branch target address 
            end
            else begin
                instr_type = 4'b0100;
                case(instr[14:12])
                    3'b000: begin 
                        alu_op = 5'b00001; // BEQ: if (rs1 == rs2) pc = pc + imm
                        load_size = 3'b000; // using the same lines to see if need to check zero flag or negate zero flag
                    end
                    3'b001: begin 
                        alu_op = 5'b00001;
                        load_size = 3'b001; // BNE: if (rs1 != rs2) pc = pc + imm
                    end
                    3'b100: begin   //BLT: if (rs1 < rs2) pc = pc + imm
                        alu_op = 5'b00011;
                        load_size = 3'b000;
                    end
                    3'b101: begin   //BGE: if (rs1 >= rs2) pc = pc + imm
                        alu_op = 5'b00011;
                        load_size = 3'b001;
                    end
                    3'b110: begin   //BLTU: if (rs1 < rs2) pc = pc + imm (unsigned)
                        alu_op = 5'b00100;
                        load_size = 3'b000;
                    end
                    3'b111: begin   //BGEU: if (rs1 >= rs2) pc = pc + imm (unsigned)
                        alu_op = 5'b00100;
                        load_size = 3'b001;
                    end
                endcase
            end
        end

        7'b0010111: begin // U type instructions (AUIPC)
            write_reg = instr[11:7];
            reg_sel_a = 5'b00000; // no register needed for AUIPC
            reg_sel_b = 5'b00000; // no register needed for AUIPC
            imm = instr[31:12]; // imm[31:12]
            alu_en = 1'b1;
            alu_op = 5'b00000; // ADD operation to calculate AUIPC value
            instr_type = 4'b0110; // U type instruction
            en_write = 1;

        end

        7'b0110111: begin // U type instructions (LUI)
            write_reg = instr[11:7];
            reg_sel_a = 5'b00000; // no register needed for LUI
            reg_sel_b = 5'b00000; // no register needed for LUI
            imm = instr[31:12]; // imm[31:12]
            alu_en = 1'b0; // no ALU operation needed for LUI
            instr_type = 4'b0111; // U type instruction
            en_write = 1;
        end

        7'b1101111: begin // J type instructions (JAL)
            write_reg = instr[11:7];
            reg_sel_a = 5'b00000; // no register needed for JAL
            reg_sel_b = 5'b00000; // no register needed for JAL
            imm = {instr[31], instr[19:12], instr[20], instr[30:21]}; // SignExt{imm[20|10:1|11|19:12|0]}
            alu_en = 1'b1; 
            alu_op = 5'b00000; // ADD operation to calculate JAL target address
            instr_type = 4'b1000; // J type instruction
            en_write = 1;
        end

        7'b1100111: begin // I type instructions (JALR)
            write_reg = instr[11:7];
            reg_sel_a = instr[19:15];
            reg_sel_b = 5'b00000; 
            write_en = 1'b0; // no write to memory for load instructions

            imm = {{8{instr[31]}}, instr[31:20]}; // immediate value for I type instructions: SignExt{imm[11:0]}

            alu_en = 1'b1;
            instr_type = 4'b1001; // JALR type instruction
            alu_op = 5'b00000; // ADD operation to calculate JALR target address
            en_write = 1;
        end




        // 4'h1: begin // ADD: Reg[Dest] = Reg[Dest] + Reg[Src]
        //     reg_sel_a = instr[11:9];
        //     reg_sel_b = instr[8:6];
        //     alu_op = 3'b000;
        //     write_reg = instr[11:9];
        //     en_write =1;
        // end 



        // 4'h2: begin // SUB: Reg[Dest] = Reg[Dest] - Reg[Src]
        //     reg_sel_a = instr[11:9];
        //     reg_sel_b = instr[8:6];
        //     alu_op = 3'b001;
        //     write_reg = instr[11:9];
        //     en_write =1;
        // end 

        // 4'h3: begin // MOV: Reg[Dest] = Reg[Src]
        //     reg_sel_a = instr[8:6];
        //     write_reg = instr[11:9];
        //     en_write =1;
        // end 

        //  4'h4: begin // READ: Reg[Dest] = RAM[Addr]
        //    addr = instr[7:0];
        //    write_reg = instr[11:9];
        //    en_write=1;
        // end 

        //  4'h5: begin // Write: RAM[Addr] = Reg[Dest]
            
        //    reg_sel_a = instr[11:9];
        //    write_en=1;
        //    addr = instr[7:0];
        // end


        // 4'h6: begin // JMP
        //     load =1;
        //     data_in  = {8'h00, instr[7:0]};
        
        // end 

        // 4'h7: begin // JZ: Jump if not Zero
        //     if (!status_z) begin
        //         load = 1;
        //         data_in = {8'h00, instr[7:0]};
        //     end
        // end

        // 4'h8: begin // MUL
        //     reg_sel_a = instr[11:9];
        //     reg_sel_b = instr[8:6];
        //     alu_op = 3'b100;
        //     write_reg = instr[11:9];
        //     en_write =1;
        // end

        // 4'hE: begin // HALT
        //     en =0;        
        // end 




    endcase

end 


endmodule