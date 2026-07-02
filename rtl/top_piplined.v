module top_piplined(
    input clk,
    input rst
);


// Stage 1: Fetch(IF) signals: PC + ROM 
wire en, load; // en- pc enable    load- jump enable 
wire [31:0] d_in; // addr to jump 
wire [31:0] pc;

wire [31:0] instruction; // ROM: instruction retruned from ROM


// Pipline Register; IF/ID Register 
reg [31:0] if_id_instr;


// Stage 2: Decode (ID) Signals: Control UNit 
// Decode goal: figure out what to do and get the data

// CU
wire [4:0] reg_sel_a, reg_sel_b; // register numebr retutned from the control unit after decoding the instruction 
wire en_write;// coming from cu to register file 
wire [4:0] write_reg; // choosen write reg by cu to register file 
wire [3:0] alu_op; //
wire [31:0] addr; // address to be read from mem by the cu 
wire write_en; // write enable returned by the cu to the mem module 
wire cu_alu_en; // alu enable returned by cu

// register file 
wire [31:0] read_data1,read_data2; //coming by reading the register-- can either go back to register or alu or memory

// reading mem
wire [31:0] data_out; // data read from the mem to the ........


// -- PIpline Register: ID/EXECUTE

reg [4:0] id_ex_write_reg; // choosen write reg by cu to register file 
reg [3:0] id_ex_alu_op; //
reg [31:0] id_ex_addr; // address to be read from mem by the cu 
reg id_ex_en_write; // write enable returned by the cu to the mem module 
reg [31:0] id_ex_data_out;
reg [31:0] id_ex_read_data1,id_ex_read_data2;
reg id_ex_write_en; // write enable to write in mem after decoded in cpu 

reg [19:0] id_ex_imm;//???

reg [6:0] id_ex_opcode;
reg id_ex_alu_en;


// Stage 3: EXECUTE 
wire [31:0] alu_result;
wire [31:0] write_data; // data from  from  register file to mem or data written to mem
wire [31:0] write_back_data; //  the data that actually goes to the reg values
wire zero_flag, carry;

wire [19:0]if_id_imm;



// ******STAGE 1
program_counter pc_inst(
    // input 
    .clk(clk), .rst(rst), .en(en), .load(load), .d_in(d_in), 
    // output 
    .pc(pc)
);

instruction_mem ROM(
    .addr(pc),
    // output
    .ins_out(instruction)
);



// if_id 
always @(posedge clk) begin
    if(!rst || load ) if_id_instr <= 32'h00000000;
    else if_id_instr <= instruction;

end 


// STAGE 2: cu decodeing and data reading from ram or reg files
control_unit cu(
    // input 
    .instr(if_id_instr),
    .status_z(zero_flag),    
    // output 
    .reg_sel_a(reg_sel_a),
    .reg_sel_b(reg_sel_b),

    .imm(if_id_imm),
    .en_write(en_write),
    .write_reg(write_reg),
    .alu_op(alu_op),
    .data_in(d_in),
    .addr(addr),
    .en(en),.load(load),
    .write_en(write_en),
    .alu_en(cu_alu_en)
);





// pipline ID to Execute
always @(posedge clk) begin

    if(!rst) begin
        id_ex_en_write <=0; 
        id_ex_write_en <=0;
        id_ex_alu_op <= 4'b0000;
        id_ex_write_reg <= 5'b00000;
        id_ex_data_out <= 32'h00000000;
        id_ex_read_data1 <= 32'h00000000;
        id_ex_read_data2 <= 32'h00000000;
        id_ex_alu_en <= 1'b0;

    end 

    else begin 
        id_ex_read_data1 <= read_data1;
        id_ex_read_data2 <= read_data2;
        id_ex_en_write <= en_write;
        id_ex_write_en <= write_en;
        id_ex_write_reg <= write_reg;
        id_ex_alu_op <= alu_op;
        id_ex_data_out <= data_out;
        id_ex_opcode <= if_id_instr[6:0];
        id_ex_imm <= if_id_imm;
        id_ex_addr <=  addr;
        id_ex_alu_en <= cu_alu_en;

    end

end


// stage 3 exeucte 


data_mem mem(

    // input 
    .clk(clk),
    .addr(id_ex_addr), // this addr can come for stage 2( directly) or in stage 3 
    .write_en(id_ex_write_en),
    .write_data(id_ex_read_data1), // **** wrtie back from Execute stage
    
    // output
    .data_out(data_out) // getting data is stage 2
);


register_file reg_file(
    .clk(clk),
    .rst(rst),

    // input coming from execute stage
    .en_write(id_ex_en_write),
    .write_reg(id_ex_write_reg),
    .write_data(write_back_data), // this write data can come from 3 place 1) Mem using READ command 2) ALU using SUB,MOV ADD commands 3) from instruction direct  by immediate value 
   
   // inputs (( reading reg in stage 2 ))
    .read_reg1(reg_sel_a),
    .read_reg2(reg_sel_b),


    // output
    .read_data1(read_data1),
    .read_data2(read_data2) 
);



alu alu_unit(
    .alu_en(id_ex_alu_en),
    .A(id_ex_read_data1),
    .B(id_ex_read_data2),
    .alu_op(id_ex_alu_op),
    .result(alu_result),
    .zero_flag(zero_flag),
    .carry(carry)
);

// *********
// this write data can come from 3 place 1) Mem using READ command 2) ALU using SUB,MOV ADD commands 3) from instruction direct  by immediate value 
// If Opcode is 0 (LOADI), take immediate. If 4 (READ), take RAM. Else ALU.

//verify this pls

  assign write_back_data = (id_ex_opcode == 7'b0000011) ? data_out : // Load from RAM           
                             (id_ex_opcode == 7'b0110111) ? id_ex_imm : // LUI (Immediate)        
                             alu_result; // Default for R-Type and I-Type ALU


//***********


endmodule