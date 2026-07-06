module data_mem(

    input clk,
    input [31:0] addr,
    input write_en,
    input [3:0] byte_en,
    input [31:0] write_data,

    output [31:0] data_out
);

    reg [31:0] ram[255:0]; //  256 location in ram, each of size 32 bit 


// reading is again asynchronous 
assign data_out  = ram[addr];

// wrtingin is synchornous 

always @(posedge clk) begin 
    if(write_en) begin
       if (byte_en[0]) ram[addr][7:0]   <= write_data[7:0];
       if (byte_en[1]) ram[addr][15:8]  <= write_data[15:8];
       if (byte_en[2]) ram[addr][23:16] <= write_data[23:16];
       if (byte_en[3]) ram[addr][31:24] <= write_data[31:24];
    end

end 



endmodule 