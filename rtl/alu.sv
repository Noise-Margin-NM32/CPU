`timescale 1ns/1ps
`default_nettype wire

module alu (
    input  wire        clk,
    input  wire        rstn,
    input  wire        alu_en,
    input  wire [31:0] A,
    input  wire [31:0] B,
    input  wire [4:0]  alu_op,

    output reg  [31:0] result,
    output wire        carry,
    output wire        zero_flag,
    output wire        slt_result,
    output wire        sltu_result,

    output wire        alu_busy,
    output wire        alu_done,
    output wire [1:0]  active_unit // 2'b00 = INT, 2'b01 = MUL, 2'b10 = DIV
);

    // Demux: Select target functional unit based on alu_op
    wire is_mul = alu_en && (alu_op >= 5'b01010 && alu_op <= 5'b01101);
    wire is_div = alu_en && (alu_op >= 5'b01110 && alu_op <= 5'b10001);
    wire is_int = alu_en && (!is_mul && !is_div);

    assign active_unit = is_div ? 2'b10 : (is_mul ? 2'b01 : 2'b00);

    // 1. Integer Functional Unit (1-Cycle)
    wire [31:0] int_result;
    alu_int u_alu_int (
        .alu_en(is_int),
        .A(A),
        .B(B),
        .alu_op(alu_op),
        .result(int_result),
        .carry(carry),
        .zero_flag(zero_flag),
        .slt_result(slt_result),
        .sltu_result(sltu_result)
    );

    // 2. Multiplier Functional Unit (2-Stage Pipeline)
    wire [31:0] mul_result;
    wire mul_busy, mul_done;
    multiplier u_multiplier (
        .clk(clk),
        .rstn(rstn),
        .mul_en(is_mul),
        .A(A),
        .B(B),
        .alu_op(alu_op),
        .result(mul_result),
        .busy(mul_busy),
        .done(mul_done)
    );

    // 3. Divider Functional Unit (32-Cycle Iterative)
    wire [31:0] div_result;
    wire div_busy, div_done;
    divider u_divider (
        .clk(clk),
        .rstn(rstn),
        .div_en(is_div),
        .A(A),
        .B(B),
        .alu_op(alu_op),
        .result(div_result),
        .busy(div_busy),
        .done(div_done)
    );

    // Overall feedback signals sent to top_piplined.v
    assign alu_busy = mul_busy || div_busy;
    assign alu_done = is_int ? 1'b1 : (mul_done || div_done);

    // Output Multiplexer
    always @(*) begin
        case (active_unit)
            2'b00:   result = int_result;
            2'b01:   result = mul_result;
            2'b10:   result = div_result;
            default: result = int_result;
        endcase
    end

endmodule