`timescale 1ns/1ps
`default_nettype wire

module instruction_mem #(
    parameter HEX_FILE = ""
)(
    input  wire        clk,
    input  wire        rstn,
    input  wire [31:0] addr,       // Address from PC (byte address)
    input  wire        valid,      // Driven by CPU: 1 when requesting instruction
    output wire        ready,      // Driven by ROM: 1 when instruction is available
    output wire [31:0] ins_out     // 32-bit instruction word
);

    reg [31:0] rom [255:0];

    // Initialize ROM to NOPs
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            rom[i] = 32'h00000013; // NOP (ADDI x0, x0, 0)
        end
        if (HEX_FILE != "") begin
            $readmemh(HEX_FILE, rom);
        end
    end

    // Ready responds directly to valid in 1-cycle zero-wait-state mode
    assign ready = valid;

    // Word indexing with boundary check: returns NOP if out of bounds or invalid
    assign ins_out = (valid && (addr[9:2] < 256)) ? rom[addr[9:2]] : 32'h00000013;

endmodule