module register_file( // planned to have 8 register in one register file
    input clk,
    input rst,
    input en_write, // enable to right to register ( 3 bit value to code for a reg)
    input [4:0] write_reg, // which address to be written to
    input [31:0] write_data, 
    
    // which reg to read data from 
    input [4:0] read_reg1, // read port1
    input [4:0] read_reg2, // read port2

    output [31:0] read_data1,
    output [31:0] read_data2
);


// create 32 register  32 bit
reg [31:0] registers [31:0]; //x0 - x31 internal riscv registers

// assign registers[0] = 32'h00000000; // hardwired to 0 x0


// asynchronous read  why ?
assign read_data1 = (read_reg1 == 5'b00000) ? 32'h00000000 : registers[read_reg1];            
assign read_data2 = (read_reg2 == 5'b00000) ? 32'h00000000 : registers[read_reg2];   

// now take care of rst and read 

integer i;
always @(posedge clk or negedge rst) begin

    if(!rst) begin
        for(i =1; i<32; i = i+1)begin
            registers[i] <= 32'h00000000; // clearing all the registers
        end 
    end 

    else if(en_write) begin
        registers[write_reg] <= (write_reg != 5'b0) ? write_data : 32'h00000000; // write to the register file if not x0

    end

end 






endmodule