`timescale 1ns/1ps
`default_nettype wire

module register_file (
    input  wire        clk,
    input  wire        rstn,
    input  wire        en_write,
    input  wire [4:0]  write_reg,
    input  wire [31:0] write_data,
    
    input  wire [4:0]  read_reg1,
    input  wire [4:0]  read_reg2,

    output wire [31:0] read_data1,
    output wire [31:0] read_data2
);

    reg [31:0] registers [31:0];

    // Asynchronous read with internal write-through bypass:
    // If writing to rd in the same cycle as reading rs, forward write_data immediately
    assign read_data1 = (read_reg1 == 5'b00000) ? 32'h00000000 :
                        (en_write && (write_reg != 5'b00000) && (write_reg == read_reg1)) ? write_data :
                        registers[read_reg1];

    assign read_data2 = (read_reg2 == 5'b00000) ? 32'h00000000 :
                        (en_write && (write_reg != 5'b00000) && (write_reg == read_reg2)) ? write_data :
                        registers[read_reg2];

    integer i;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 32'h00000000;
            end
        end else if (en_write && (write_reg != 5'b00000)) begin
            registers[write_reg] <= write_data;
        end
    end

endmodule