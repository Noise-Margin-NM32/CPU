`timescale 1ns/1ps
`default_nettype wire

module alu_int (
    input  wire        alu_en,
    input  wire [31:0] A,
    input  wire [31:0] B,
    input  wire [4:0]  alu_op,
    output reg  [31:0] result,
    output wire        carry,
    output wire        zero_flag,
    output wire        slt_result,
    output wire        sltu_result
);

    wire signed [31:0] signed_A = A;
    wire signed [31:0] signed_B = B;

    // Fast Condition Flags for Stage 2 Branch Decisions
    assign zero_flag   = (A == B);
    assign slt_result  = (signed_A < signed_B) ? 1'b1 : 1'b0;
    assign sltu_result = (A < B) ? 1'b1 : 1'b0;

    // Fast Adder / Subtractor (Critical path < 1.2ns)
    wire [32:0] add_sub_res = (alu_op == 5'b00001) ? ({1'b0, A} - {1'b0, B}) : ({1'b0, A} + {1'b0, B});
    assign carry = add_sub_res[32];

    always @(*) begin
        if (alu_en) begin
            case (alu_op)
                5'b00000: result = add_sub_res[31:0];                        // ADD / ADDI / AUIPC / JAL / JALR / Addr
                5'b00001: result = add_sub_res[31:0];                        // SUB
                5'b00010: result = A << B[4:0];                              // SLL / SLLI
                5'b00011: result = {31'b0, slt_result};                      // SLT / SLTI
                5'b00100: result = {31'b0, sltu_result};                     // SLTU / SLTIU
                5'b00101: result = A ^ B;                                    // XOR / XORI
                5'b00110: result = A >> B[4:0];                              // SRL / SRLI
                5'b00111: result = signed_A >>> B[4:0];                      // SRA / SRAI
                5'b01000: result = A | B;                                    // OR / ORI
                5'b01001: result = A & B;                                    // AND / ANDI
                5'b10010: result = B;                                        // LUI (Passes Immediate)
                default:  result = 32'h00000000;
            endcase
        end else begin
            result = 32'h00000000;
        end
    end

endmodule
