module instruction_mem(
    input [31:0] addr,
    output [31:0] ins_out
); 


reg [31:0] rom [255:0];

initial begin
    $readmemh("/home/omkar/8bit_CPU_pipline/firmware/program.hex",rom);// loads the hex code
end

assign ins_out = rom[addr[9:2]]; // use the lower bit of pc




endmodule