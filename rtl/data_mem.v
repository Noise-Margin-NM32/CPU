`timescale 1ns/1ps
`default_nettype wire

module data_mem #(
    parameter WORDS = 4096
)(
    input  wire        HCLK,
    input  wire        HRESETn,
    input  wire [31:0] HADDR,
    input  wire [1:0]  HTRANS,
    input  wire        HWRITE,
    input  wire [2:0]  HSIZE,
    input  wire [31:0] HWDATA,
    input  wire        HREADY,
    output wire        HREADYOUT,
    output wire [31:0] HRDATA,
    output wire        HRESP
);

    reg [31:0] ram [WORDS-1:0];

    // Initialize RAM to 0
    integer i;
    initial begin
        for (i = 0; i < WORDS; i = i + 1) begin
            ram[i] = 32'h00000000;
        end
    end

    // AHB-Lite Pipelined Address Phase
    reg [11:0] addr_reg;
    reg [1:0]  byte_off_reg;
    reg        write_reg;
    reg [2:0]  size_reg;
    reg        trans_active;

    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            addr_reg     <= 12'd0;
            byte_off_reg <= 2'd0;
            write_reg    <= 1'b0;
            size_reg     <= 3'b010;
            trans_active <= 1'b0;
        end else if (HREADY) begin
            addr_reg     <= HADDR[13:2];
            byte_off_reg <= HADDR[1:0];
            write_reg    <= HWRITE;
            size_reg     <= HSIZE;
            trans_active <= HTRANS[1]; // Active for NONSEQ (2'b10) or SEQ (2'b11)
        end
    end

    // Data Phase Write Execution (Synchronous to HCLK)
    always @(posedge HCLK) begin
        if (HREADY && trans_active && write_reg && (addr_reg < WORDS)) begin
            case (size_reg)
                3'b000: begin // Byte write
                    case (byte_off_reg)
                        2'b00: ram[addr_reg][7:0]   <= HWDATA[7:0];
                        2'b01: ram[addr_reg][15:8]  <= HWDATA[15:8];
                        2'b10: ram[addr_reg][23:16] <= HWDATA[23:16];
                        2'b11: ram[addr_reg][31:24] <= HWDATA[31:24];
                    endcase
                end
                3'b001: begin // Halfword write
                    if (!byte_off_reg[1])
                        ram[addr_reg][15:0]  <= HWDATA[15:0];
                    else
                        ram[addr_reg][31:16] <= HWDATA[31:16];
                end
                default: begin // Word write (3'b010)
                    ram[addr_reg] <= HWDATA;
                end
            endcase
        end
    end

    // Data Phase Outputs
    assign HREADYOUT = 1'b1;
    assign HRESP     = 1'b0; // OKAY
    assign HRDATA    = (trans_active && !write_reg && (addr_reg < WORDS)) ? ram[addr_reg] : 32'h00000000;

endmodule