// program counter max address 8 bits (256) only 

module program_counter(
    input clk,
    input rst, // reset
    input en, // enable the pc
    input load, // jump enable 
    input [31:0]d_in, // address to jump at
    
    output reg [31:0] pc // output address to reach at 
);


    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            pc <= 32'h00000000;
        end    
    
        else if (load) begin
            pc <= d_in; // jump
        end
    
        else if (en) begin
            
            // if(pc == 255) begin  // limiting pc till 255
            //     pc <=0; 
            // end
            pc <= pc+4; // next address
        end 
    end 
endmodule 