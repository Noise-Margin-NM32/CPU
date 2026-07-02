module alu(
    input alu_en,
    input [31:0] A,
    input [31:0] B,

    input [3:0] alu_op, // operation alu perfroms

    output reg [31:0] result,
    output reg carry,
    output reg zero_flag
);



always_comb begin
    if (alu_en) begin
        case(alu_op)
        4'b0000: {carry,result} = A+B;
        4'b0001: {carry,result} = A-B;
        4'b0010:  result = A << B[4:0]; // SLL
        4'b0011: begin
            if (A[31] == B[31]) begin
                result = A<B ? 32'h00000001 : 32'h00000000;
            end
            else begin
                result = A[31] ? 32'h00000001 : 32'h00000000;
            end
        end
        4'b0100: result = A < B ? 32'h00000001 : 32'h00000000; // SLTU
        4'b0101: result = A ^ B; //XOR
        4'b0110: result = A >> B[4:0];// SRL
        4'b0111: result = $signed(A) >>> B[4:0]; // SRA
        4'b1000: result = A|B; //OR
        4'b1001: result = A&B; //AND
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