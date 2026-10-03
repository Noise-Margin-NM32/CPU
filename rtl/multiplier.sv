`timescale 1ns/1ps
`default_nettype wire

module multiplier (
    input  wire        clk,
    input  wire        rstn,
    input  wire        mul_en,       // Trigger strobe
    input  wire [31:0] A,
    input  wire [31:0] B,
    input  wire [4:0]  alu_op,       // 5'b01010=MUL, 5'b01011=MULH, 5'b01100=MULHSU, 5'b01101=MULHU
    output wire [31:0] result,
    output wire        busy,
    output wire        done
);

    wire is_mul_op = mul_en && (alu_op >= 5'b01010 && alu_op <= 5'b01101);

    localparam M_IDLE = 2'b00;
    localparam M_PIPE = 2'b01;
    localparam M_DONE = 2'b10;

    reg [1:0] state;
    reg [4:0] saved_op;
    reg signed [32:0] op_a;
    reg signed [32:0] op_b;
    reg signed [65:0] product;

    assign busy = (state == M_PIPE) || (state == M_IDLE && is_mul_op);
    assign done = (state == M_DONE);

    // Output is driven continuously from product based on saved_op
    assign result = (saved_op == 5'b01010) ? product[31:0] : product[63:32];

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            state    <= M_IDLE;
            saved_op <= 5'd0;
            op_a     <= 33'd0;
            op_b     <= 33'd0;
            product  <= 66'd0;
        end else begin
            case (state)
                M_IDLE: begin
                    if (is_mul_op) begin
                        saved_op <= alu_op;
                        // Sign-extend A
                        if (alu_op == 5'b01101) // MULHU
                            op_a <= {1'b0, A};
                        else
                            op_a <= {A[31], A};

                        // Sign-extend B
                        if (alu_op == 5'b01100 || alu_op == 5'b01101) // MULHSU, MULHU
                            op_b <= {1'b0, B};
                        else
                            op_b <= {B[31], B};

                        state <= M_PIPE;
                    end
                end

                M_PIPE: begin
                    // Compute 64-bit product in Stage 2
                    product <= op_a * op_b;
                    state   <= M_DONE;
                end

                M_DONE: begin
                    state <= M_IDLE;
                end
            endcase
        end
    end

endmodule
