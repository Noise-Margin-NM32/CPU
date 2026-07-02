module data_mem(

    input clk,
    input [31:0] addr,
    input write_en,
    input [31:0] write_data,

    output [31:0] data_out
);

    reg [31:0] ram[255:0]; //  256 location in ram, each of size 32 bit 


// reading is again asynchronous 
assign data_out  = ram[addr];

// wrtingin is synchornous 

always @(posedge clk) begin 
    if(write_en) begin
       ram[addr] <= write_data; 
    end

end 



endmodule 