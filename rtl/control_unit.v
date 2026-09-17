`timescale 1ns/1ps
`default_nettype wire

module control_unit (
    input  wire [31:0] instr,

    output reg  [4:0]  reg_sel_a,
    output reg  [4:0]  reg_sel_b,
    output reg         en_write,
    output reg  [4:0]  write_reg,
    output reg  [4:0]  alu_op,
    output reg         write_en,
    output reg  [19:0] imm,
    output reg         alu_en,
    output reg  [3:0]  instr_type,
    output reg  [2:0]  load_size
);

    always @(*) begin
        // Defaults
        reg_sel_a  = 5'd0;
        reg_sel_b  = 5'd0;
        write_reg  = 5'd0;
        en_write   = 1'b0;
        write_en   = 1'b0;
        alu_op     = 5'b00000;
        imm        = 20'h00000;
        alu_en     = 1'b0;
        instr_type = 4'b0000;
        load_size  = 3'b000;

        case (instr[6:0])
            7'b0110011: begin // R-type + M-extension
                reg_sel_a  = instr[19:15];
                reg_sel_b  = instr[24:20];
                write_reg  = instr[11:7];
                en_write   = 1'b1;
                write_en   = 1'b0;
                alu_en     = 1'b1;
                instr_type = 4'b0000;

                case (instr[14:12])
                    3'b000: begin
                        case (instr[31:25])
                            7'b0000000: alu_op = 5'b00000; // ADD
                            7'b0100000: alu_op = 5'b00001; // SUB
                            7'b0000001: alu_op = 5'b01010; // MUL
                            default:    alu_op = 5'b00000;
                        endcase
                    end
                    3'b001: begin
                        if (instr[31:25] == 7'b0000001)
                            alu_op = 5'b01011; // MULH
                        else
                            alu_op = 5'b00010; // SLL
                    end
                    3'b010: begin
                        if (instr[31:25] == 7'b0000001)
                            alu_op = 5'b01100; // MULHSU
                        else
                            alu_op = 5'b00011; // SLT
                    end
                    3'b011: begin
                        if (instr[31:25] == 7'b0000001)
                            alu_op = 5'b01101; // MULHU
                        else
                            alu_op = 5'b00100; // SLTU
                    end
                    3'b100: begin
                        if (instr[31:25] == 7'b0000001)
                            alu_op = 5'b01110; // DIV
                        else
                            alu_op = 5'b00101; // XOR
                    end
                    3'b101: begin
                        case (instr[31:25])
                            7'b0000000: alu_op = 5'b00110; // SRL
                            7'b0100000: alu_op = 5'b00111; // SRA
                            7'b0000001: alu_op = 5'b01111; // DIVU
                            default:    alu_op = 5'b00110;
                        endcase
                    end
                    3'b110: begin
                        if (instr[31:25] == 7'b0000001)
                            alu_op = 5'b10000; // REM
                        else
                            alu_op = 5'b01000; // OR
                    end
                    3'b111: begin
                        if (instr[31:25] == 7'b0000001)
                            alu_op = 5'b10001; // REMU
                        else
                            alu_op = 5'b01001; // AND
                    end
                endcase
            end

            7'b0000011: begin // IL-type (Load)
                write_reg  = instr[11:7];
                reg_sel_a  = instr[19:15];
                reg_sel_b  = 5'd0;
                write_en   = 1'b0;
                en_write   = 1'b1;
                alu_en     = 1'b1;
                alu_op     = 5'b00000; // ADD base + offset
                instr_type = 4'b0001;
                imm        = {{8{instr[31]}}, instr[31:20]};

                case (instr[14:12])
                    3'b000:  load_size = 3'b000; // LB
                    3'b001:  load_size = 3'b001; // LH
                    3'b010:  load_size = 3'b010; // LW
                    3'b100:  load_size = 3'b011; // LBU
                    3'b101:  load_size = 3'b100; // LHU
                    default: load_size = 3'b010;
                endcase
            end

            7'b0010011: begin // IA-type (Immediate Arithmetic)
                write_reg  = instr[11:7];
                reg_sel_a  = instr[19:15];
                reg_sel_b  = 5'd0;
                write_en   = 1'b0;
                en_write   = 1'b1;
                alu_en     = 1'b1;
                instr_type = 4'b0010;
                imm        = {{8{instr[31]}}, instr[31:20]};

                case (instr[14:12])
                    3'b000:  alu_op = 5'b00000; // ADDI
                    3'b001:  alu_op = 5'b00010; // SLLI
                    3'b010:  alu_op = 5'b00011; // SLTI
                    3'b011:  alu_op = 5'b00100; // SLTIU
                    3'b100:  alu_op = 5'b00101; // XORI
                    3'b101: begin
                        if (instr[31:25] == 7'b0100000)
                            alu_op = 5'b00111; // SRAI
                        else
                            alu_op = 5'b00110; // SRLI
                    end
                    3'b110:  alu_op = 5'b01000; // ORI
                    3'b111:  alu_op = 5'b01001; // ANDI
                    default: alu_op = 5'b00000;
                endcase
            end

            7'b0100011: begin // S-type (Store)
                write_reg  = 5'd0;
                reg_sel_a  = instr[19:15];
                reg_sel_b  = instr[24:20];
                write_en   = 1'b1;
                en_write   = 1'b0;
                alu_en     = 1'b1;
                alu_op     = 5'b00000; // ADD base + offset
                instr_type = 4'b0011;
                imm        = {{8{instr[31]}}, instr[31:25], instr[11:7]};

                case (instr[14:12])
                    3'b000:  load_size = 3'b000; // SB
                    3'b001:  load_size = 3'b001; // SH
                    3'b010:  load_size = 3'b010; // SW
                    default: load_size = 3'b010;
                endcase
            end

            7'b1100011: begin // B-type (Branch)
                write_reg  = 5'd0;
                reg_sel_a  = instr[19:15];
                reg_sel_b  = instr[24:20];
                write_en   = 1'b0;
                en_write   = 1'b0;
                alu_en     = 1'b1;
                instr_type = 4'b0100;
                imm        = {{8{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};

                case (instr[14:12])
                    3'b000: begin alu_op = 5'b00001; load_size = 3'b000; end // BEQ
                    3'b001: begin alu_op = 5'b00001; load_size = 3'b001; end // BNE
                    3'b100: begin alu_op = 5'b00011; load_size = 3'b010; end // BLT
                    3'b101: begin alu_op = 5'b00011; load_size = 3'b011; end // BGE
                    3'b110: begin alu_op = 5'b00100; load_size = 3'b100; end // BLTU
                    3'b111: begin alu_op = 5'b00100; load_size = 3'b101; end // BGEU
                    default: begin alu_op = 5'b00001; load_size = 3'b000; end
                endcase
            end

            7'b0110111: begin // U-type (LUI)
                write_reg  = instr[11:7];
                reg_sel_a  = 5'd0;
                reg_sel_b  = 5'd0;
                write_en   = 1'b0;
                en_write   = 1'b1;
                alu_en     = 1'b1;
                alu_op     = 5'b10010; // Pass Immediate
                instr_type = 4'b0111;
                imm        = instr[31:12];
            end

            7'b0010111: begin // U-type (AUIPC)
                write_reg  = instr[11:7];
                reg_sel_a  = 5'd0;
                reg_sel_b  = 5'd0;
                write_en   = 1'b0;
                en_write   = 1'b1;
                alu_en     = 1'b1;
                alu_op     = 5'b00000; // ADD PC + imm
                instr_type = 4'b0110;
                imm        = instr[31:12];
            end

            7'b1101111: begin // J-type (JAL)
                write_reg  = instr[11:7];
                reg_sel_a  = 5'd0;
                reg_sel_b  = 5'd0;
                write_en   = 1'b0;
                en_write   = 1'b1;
                alu_en     = 1'b1;
                alu_op     = 5'b00000;
                instr_type = 4'b1000;
                imm        = {instr[31], instr[19:12], instr[20], instr[30:21]};
            end

            7'b1100111: begin // I-type (JALR)
                write_reg  = instr[11:7];
                reg_sel_a  = instr[19:15];
                reg_sel_b  = 5'd0;
                write_en   = 1'b0;
                en_write   = 1'b1;
                alu_en     = 1'b1;
                alu_op     = 5'b00000;
                instr_type = 4'b1001;
                imm        = {{8{instr[31]}}, instr[31:20]};
            end

            default: begin
                // Defaults for NOP or unhandled opcode
                reg_sel_a  = 5'd0;
                reg_sel_b  = 5'd0;
                write_reg  = 5'd0;
                en_write   = 1'b0;
                write_en   = 1'b0;
                alu_op     = 5'b00000;
                imm        = 20'h00000;
                alu_en     = 1'b0;
                instr_type = 4'b0000;
                load_size  = 3'b000;
            end
        endcase
    end

endmodule