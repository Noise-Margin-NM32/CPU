`default_nettype wire

module instruction_mem(
    input clk,
    input [31:0] addr,
    input rstn,
    // input halt,
    input ready,
    output reg valid,
    output reg [31:0] ins_out
); 

//Adding a Valid Ready Handshake to test out the working, will replace with full blown AHB later on

reg halt;

assign halt = ~ (valid & ready);


reg [31:0] rom [255:0];

assign valid = 1'b1; // valid signal is always high, indicating that the instruction memory is always ready to provide the next instruction
// initial begin
//     $readmemh("/home/omkar/8bit_CPU_pipline/firmware/program.hex",rom);// loads the hex code
// end

// assign ins_out = rom[addr[9:2]]; // use the lower bit of pc

always @(posedge clk or negedge rstn) begin
    if(!rstn) begin
        ins_out <= 32'h00000013;
        // valid <= 1'b0;
    end
    else begin
        ins_out <= (addr[9:2] < 256) ? (halt) ? ins_out : rom[addr[9:2]] :32'h00000013; // reading the data from the memory
        // valid <= 1'b1;
    end
end
endmodule