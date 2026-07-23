module alu(
    input alu_en,
    input [31:0] A,
    input [31:0] B,

    input [4:0] alu_op, // operation alu perfroms

    output reg [31:0] result,
    output reg carry,
    output reg zero_flag
);



reg [63:0] mul_out;

always_comb begin
    if (alu_en) begin
        case(alu_op)
        5'b00000: {carry,result} = A+B;
        5'b00001: {carry,result} = A-B;
        5'b00010:  result = A << B[4:0]; // SLL
        5'b00011: begin
            if (A[31] == B[31]) begin
                result = A<B ? 32'h00000001 : 32'h00000000;
            end
            else begin
                result = A[31] ? 32'h00000001 : 32'h00000000;
            end
        end
        5'b00100: result = A < B ? 32'h00000001 : 32'h00000000; // SLTU
        5'b00101: result = A ^ B; //XOR
        5'b00110: result = A >> B[4:0];// SRL
        5'b00111: result = $signed(A) >>> B[4:0]; // SRA
        5'b01000: result = A|B; //OR
        5'b01001: result = A&B; //AND
        5'b01010:begin
            mul_out = A*B;
            result = mul_out[31:0]; // MUL (lower 32 bits)
        end
        5'b01011:begin
            mul_out = $signed(A) * $signed(B);
            result = mul_out[63:32]; // MULH (upper 32 bits, signed×signed)
        end
        5'b01100:begin
            mul_out = $signed({{32{A[31]}}, A}) * $signed({1'b0, B});
            result = mul_out[63:32]; // MULHSU (upper 32, signed×unsigned)
        end
        5'b01101:begin
            mul_out = A * B;
            result = mul_out[63:32]; // MULHU (upper 32, unsigned×unsigned)
        end
        5'b01110: begin // DIV (signed)
            if (B == 32'h0)
                result = 32'hFFFFFFFF; // div-by-zero → -1
            else if (A == 32'h80000000 && B == 32'hFFFFFFFF)
                result = 32'h80000000; // overflow: INT_MIN / -1 → INT_MIN
            else
                result = $signed(A) / $signed(B);
        end
        5'b01111: begin // DIVU (unsigned)
            if (B == 32'h0)
                result = 32'hFFFFFFFF; // div-by-zero → 2^32-1
            else
                result = A / B;
        end
        5'b10000: begin // REM (signed)
            if (B == 32'h0)
                result = A; // rem-by-zero → dividend
            else if (A == 32'h80000000 && B == 32'hFFFFFFFF)
                result = 32'h0; // overflow: INT_MIN % -1 → 0
            else
                result = $signed(A) % $signed(B);
        end
        5'b10001: begin // REMU (unsigned)
            if (B == 32'h0)
                result = A; // rem-by-zero → dividend
            else
                result = A % B;
        end
        default: result = 32'h00;

        endcase

        zero_flag = (result == 32'h00000000); // zero flag if result is 00
    end else begin
        result = 32'h00000000;
        carry = 1'b0;
        zero_flag = 1'b0;
    end
end





endmodule 