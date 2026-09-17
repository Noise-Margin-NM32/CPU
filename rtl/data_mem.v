`timescale 1ns/1ps
`default_nettype wire

module data_mem (
    input  wire        clk,
    input  wire        rstn,
    input  wire [31:0] addr,        // Address from Stage 3 (ALU result)
    input  wire        valid,       // Driven by CPU: 1 when Load or Store is active
    input  wire        write_en,    // 1 for Store, 0 for Load
    input  wire [3:0]  byte_en,     // Byte-enable strobe (SB=4'b0001, SH=4'b0011, SW=4'b1111 shifted)
    input  wire [31:0] write_data,  // Data to write (shifted into proper byte position)
    output wire        ready,       // Driven by RAM: 1 when transaction completes
    output wire [31:0] data_out     // Read data word
);

    reg [31:0] ram [255:0];

    // Initialize RAM to 0
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            ram[i] = 32'h00000000;
        end
    end

    // RAM responds when valid is asserted
    assign ready = valid;

    // Synchronous write on rising clock edge with byte enables
    always @(posedge clk) begin
        if (valid && write_en) begin
            if (byte_en[0]) ram[addr[9:2]][7:0]   <= write_data[7:0];
            if (byte_en[1]) ram[addr[9:2]][15:8]  <= write_data[15:8];
            if (byte_en[2]) ram[addr[9:2]][23:16] <= write_data[23:16];
            if (byte_en[3]) ram[addr[9:2]][31:24] <= write_data[31:24];
        end
    end

    // Asynchronous read (available during Stage 3 for sub-word alignment and writeback)
    assign data_out = (valid && !write_en && (addr[9:2] < 256)) ? ram[addr[9:2]] : 32'h00000000;

endmodule