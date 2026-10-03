`timescale 1ns/1ps
`default_nettype wire

module divider (
    input  wire        clk,
    input  wire        rstn,
    input  wire        div_en,       // Trigger strobe
    input  wire [31:0] A,            // Dividend
    input  wire [31:0] B,            // Divisor
    input  wire [4:0]  alu_op,       // 5'b01110=DIV, 5'b01111=DIVU, 5'b10000=REM, 5'b10001=REMU
    output reg  [31:0] result,
    output wire        busy,
    output wire        done
);

    wire is_div_op = div_en && (alu_op >= 5'b01110 && alu_op <= 5'b10001);
    wire is_signed = (alu_op == 5'b01110 || alu_op == 5'b10000);

    localparam D_IDLE = 2'b00;
    localparam D_CALC = 2'b01;
    localparam D_DONE = 2'b10;

    reg [1:0]  state;
    reg [5:0]  count;
    reg [4:0]  saved_op;
    reg        neg_quot;
    reg        neg_rem;

    reg [31:0] reg_b;      // Divisor magnitude
    reg [63:0] reg_r_q;    // [63:32] Remainder, [31:0] Quotient

    // Absolute values
    wire [31:0] abs_a = (is_signed && A[31]) ? (-A) : A;
    wire [31:0] abs_b = (is_signed && B[31]) ? (-B) : B;

    // Corner cases
    wire div_by_zero = (B == 32'd0);
    wire overflow    = (is_signed && (A == 32'h80000000) && (B == 32'hFFFFFFFF));

    assign busy = (state == D_CALC) || (state == D_IDLE && is_div_op && !div_by_zero && !overflow);
    assign done = (state == D_DONE) || (state == D_IDLE && is_div_op && (div_by_zero || overflow));

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            state     <= D_IDLE;
            count     <= 6'd0;
            saved_op  <= 5'd0;
            neg_quot  <= 1'b0;
            neg_rem   <= 1'b0;
            reg_b     <= 32'd0;
            reg_r_q   <= 64'd0;
            result    <= 32'd0;
        end else begin
            case (state)
                D_IDLE: begin
                    if (is_div_op) begin
                        saved_op <= alu_op;
                        if (div_by_zero) begin
                            // Fast 1-cycle resolution for Division by Zero
                            if (alu_op == 5'b01110 || alu_op == 5'b01111)
                                result <= 32'hFFFFFFFF; // DIV / DIVU -> 2^32-1
                            else
                                result <= A;            // REM / REMU -> Dividend
                        end else if (overflow) begin
                            // Fast 1-cycle resolution for Signed Overflow (INT_MIN / -1)
                            if (alu_op == 5'b01110)
                                result <= 32'h80000000; // DIV -> INT_MIN
                            else
                                result <= 32'h00000000; // REM -> 0
                        end else begin
                            // Normal 32-cycle division
                            neg_quot <= is_signed && (A[31] ^ B[31]);
                            neg_rem  <= is_signed && A[31];
                            reg_b    <= abs_b;
                            reg_r_q  <= {32'd0, abs_a};
                            count    <= 6'd32;
                            state    <= D_CALC;
                        end
                    end
                end

                D_CALC: begin
                    if (count > 0) begin
                        reg [63:0] shifted_rq;
                        reg [32:0] sub_res;
                        shifted_rq = {reg_r_q[62:0], 1'b0};
                        sub_res = {1'b0, shifted_rq[63:32]} - {1'b0, reg_b};

                        if (!sub_res[32]) begin // Remainder >= Divisor
                            reg_r_q <= {sub_res[31:0], shifted_rq[31:1], 1'b1};
                        end else begin
                            reg_r_q <= shifted_rq;
                        end
                        count <= count - 1'b1;
                    end else begin
                        // Calculation complete
                        if (saved_op == 5'b10000) // REM
                            result <= neg_rem ? (-reg_r_q[63:32]) : reg_r_q[63:32];
                        else if (saved_op == 5'b10001) // REMU
                            result <= reg_r_q[63:32];
                        else if (saved_op == 5'b01110) // DIV
                            result <= neg_quot ? (-reg_r_q[31:0]) : reg_r_q[31:0];
                        else // DIVU
                            result <= reg_r_q[31:0];

                        state <= D_DONE;
                    end
                end

                D_DONE: begin
                    state <= D_IDLE;
                end
            endcase
        end
    end

endmodule
