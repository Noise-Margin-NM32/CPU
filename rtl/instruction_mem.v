`timescale 1ns/1ps
`default_nettype wire

module instruction_mem #(
    parameter HEX_FILE = "",
    parameter WORDS    = 4096
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

    reg [31:0] rom [WORDS-1:0];

    // Initialize ROM to NOPs
    integer i;
    initial begin
        for (i = 0; i < WORDS; i = i + 1) begin
            rom[i] = 32'h00000013; // NOP (ADDI x0, x0, 0)
        end
        if (HEX_FILE != "") begin
            $readmemh(HEX_FILE, rom);
        end
    end

    // AHB-Lite Pipelined Read Engine
    reg [11:0] addr_reg;
    reg        trans_active;

    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            addr_reg     <= 12'd0;
            trans_active <= 1'b0;
        end else if (HREADY) begin
            addr_reg     <= HADDR[13:2];
            trans_active <= HTRANS[1]; // Active for NONSEQ (2'b10) or SEQ (2'b11)
        end
    end

    // Data Phase outputs
    assign HREADYOUT = 1'b1;
    assign HRESP     = 1'b0; // OKAY
    assign HRDATA    = (trans_active && (addr_reg < WORDS)) ? rom[addr_reg] : 32'h00000013;

endmodule