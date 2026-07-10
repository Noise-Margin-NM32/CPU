module top_piplined(
    input clk,
    input rst
);


// Stage 1: Fetch(IF) signals: PC + ROM 


// Stage 2: Decode (ID) Signals: Control UNit 



// Stage 3: EXECUTE 




// ******STAGE 1

wire en, jump; // en- pc enable  
wire [31:0] d_in; // addr to jump 
wire [31:0] pc;
wire branch_taken; // branch decision wire


assign en = 1'b1; // always enable the pc to increment
// assign jump = 1'b0; // no jump in this design, for now

wire [31:0] instruction; // ROM: instruction retruned from ROM


// Pipline Register; IF/ID Register 
reg [31:0] if_id_instr;
reg [31:0] if_id_pc; // pc value to be passed to the next stage (ID) for branch and jump instructions

program_counter pc_inst(
    // input 
    .clk(clk), .rst(rst), .en(en), .jump(jump), .d_in(d_in), 
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
    if(!rst || jump || branch_taken) begin
        if_id_instr <= 32'h00000000;
        if_id_pc    <= 32'h00000000;
    end
    else begin 
        if_id_instr <= instruction;
        if_id_pc <= pc;
    end
end 


// STAGE 2: cu decodeing and data reading from ram or reg files

// Decode goal: figure out what to do and get the data

// CU
wire [4:0] reg_sel_a, reg_sel_b; // register numebr retutned from the control unit after decoding the instruction 
wire en_write;// coming from cu to register file 
wire [4:0] write_reg; // choosen write reg by cu to register file 
wire [4:0] alu_op; //
wire [19:0] imm; // immediate value
wire cu_alu_en; // alu enable returned by cu
// wire [31:0] addr; // address to be read from mem by the cu 
// wire write_en; // write enable returned by the cu to the mem module 
// wire load_instr;
wire [3:0] instr_type; // to identify the type of instruction (R, I, S, B, U, J) 000-R, 001-IL, 010-IA, 011-S, 100-B, 101-U, 110-J
wire [2:0] load_size; // to identify the size of the data to be loaded (byte, half-word, word) 00-byte, 01-half-word, 10


// -- PIpline Register: ID/EXECUTE

reg [4:0] id_ex_write_reg; // choosen write reg by cu to register file 
reg [4:0] id_ex_alu_op; //alu_opcode
reg [4:0] id_ex_reg_sel_a,id_ex_reg_sel_b; // register selectors returned by the control unit  
reg id_ex_en_write; // write enable returned by the cu to the mem module 
// reg [31:0] id_ex_data_out;
reg id_ex_write_en; // write enable to write in mem after decoded in cpu 

reg [19:0] id_ex_imm;//???

reg [3:0] id_ex_instr_type; // to identify the type of instruction (R, I, S, B, U, J) 000-R, 001-IL, 010-IA, 011-S, 100-B, 101-U, 110-J
reg [2:0] id_ex_load_size; // to identify the size of the data
reg id_ex_alu_en;
reg id_ex_zero_flag;
reg [31:0] id_ex_pc; // pc value to be passed to the next stage (ID) for branch and jump instructions


control_unit cu(
    // input 
    .instr(if_id_instr),
    // .status_z(zero_flag),    
    // output 
    .reg_sel_a(reg_sel_a),
    .reg_sel_b(reg_sel_b),
    .en_write(en_write),
    .write_en(write_en),

    .write_reg(write_reg),
    .alu_op(alu_op),
    .imm(imm),

    .alu_en(cu_alu_en),
    // .addr(addr),
    // .load_instr(load_instr),
    // .en(en),.load(load),
    .instr_type(instr_type),
    .load_size(load_size)
);

// pipline ID to Execute
always @(posedge clk) begin

    if(!rst) begin
        // id_ex_en_write_reg <=0; 
        id_ex_alu_op <= 4'b0000;
        id_ex_reg_sel_a <=0;
        id_ex_reg_sel_b <=0;
        id_ex_en_write <= 0;
        id_ex_write_en <= 0;
        id_ex_imm <= 20'b00000000000000000000;
        id_ex_write_reg <= 5'b00000;
        id_ex_instr_type <= 4'b0000;
        id_ex_load_size <= 3'b000;
        id_ex_alu_en <= 1'b0;
        // id_ex_zero_flag <= 1'b0;
        id_ex_pc <= 32'h00000000;

    end 

    else begin 
        // id_ex_alu <= read_data1;
        // id_ex_read_data2 <= read_data2;
        // id_ex_en_write <= en_write;
        // id_ex_write_en <= write_en;
        // id_ex_write_reg <= write_reg;
        // id_ex_alu_op <= alu_op;
        // id_ex_data_out <= data_out;
        // id_ex_opcode <= if_id_instr[6:0];
        // id_ex_imm <= if_id_imm;
        // id_ex_addr <=  addr;
        // id_ex_alu_en <= cu_alu_en;
        if( branch_taken ) begin
            id_ex_alu_op <= 4'b0000;
            id_ex_reg_sel_a <=id_ex_reg_sel_a;
            id_ex_reg_sel_b <=id_ex_reg_sel_b;
            id_ex_en_write <= 0;
            id_ex_write_en <= 0;
            id_ex_imm <= id_ex_imm;
            id_ex_write_reg <= id_ex_write_reg;
            id_ex_instr_type <= (id_ex_instr_type == 4'b0100) ? 4'b0101 :
                                (id_ex_instr_type == 4'b1000) ? 4'b1010 :
                                (id_ex_instr_type == 4'b1001) ? 4'b1011 : id_ex_instr_type;
            id_ex_load_size <= id_ex_load_size;
            id_ex_alu_en <= 1'b1;
            // id_ex_zero_flag <= 1'b0;
            id_ex_pc <= id_ex_pc;

        end
        else begin
            id_ex_alu_op <= alu_op;
            id_ex_reg_sel_a <= reg_sel_a;
            id_ex_reg_sel_b <= reg_sel_b;
            id_ex_en_write <= en_write;
            id_ex_write_en <= write_en;
            id_ex_imm <= imm;
            id_ex_write_reg <= write_reg;
            id_ex_instr_type <= instr_type;
            id_ex_load_size <= load_size;
            id_ex_alu_en <= cu_alu_en;
            // id_ex_zero_flag <= zero_flag;
            id_ex_pc <= if_id_pc;
        end
    end
end


// stage 3 exeucte 
wire [31:0] alu_result;
wire zero_flag, carry;
wire [31:0] alu_A, alu_B;

wire [31:0] write_data; // data from  from  register file to mem or data written to mem
wire [31:0] write_back_data; //  the data that actually goes to the reg values

wire [19:0]if_id_imm;

// register file 
wire [31:0] read_data1,read_data2; //coming by reading the register-- can either go back to register or alu or memory

// reading mem\
wire [31:0] addr; // address to be read from mem by the cu
wire [31:0] data_out; // data read from the mem to the ........

assign alu_A = (id_ex_instr_type == 4'b0000) ? read_data1 :
               (id_ex_instr_type == 4'b0001) ? read_data1 :
               (id_ex_instr_type == 4'b0010) ? read_data1 :
               (id_ex_instr_type == 4'b0011) ? read_data1 :
               (id_ex_instr_type == 4'b0100) ? read_data1 :
               (id_ex_instr_type == 4'b0101) ? id_ex_pc : 
               (id_ex_instr_type == 4'b0110) ? id_ex_pc :
               (id_ex_instr_type == 4'b1000) ? id_ex_pc :
               (id_ex_instr_type == 4'b1001) ? id_ex_pc :
               (id_ex_instr_type == 4'b1010) ? id_ex_pc :
               (id_ex_instr_type == 4'b1011) ? read_data1 : 32'h00000000;

assign alu_B = (id_ex_instr_type == 4'b0000) ? read_data2 :
               (id_ex_instr_type == 4'b0001) ? {{12{id_ex_imm[19]}}, id_ex_imm} : // Sign-extend immediate for IL-type
               (id_ex_instr_type == 4'b0010) ? {{12{id_ex_imm[19]}}, id_ex_imm} : // Sign-extend immediate for IA-type
               (id_ex_instr_type == 4'b0011) ? {{12{id_ex_imm[19]}}, id_ex_imm} : // Sign-extend immediate for S-type
               (id_ex_instr_type == 4'b0100) ? read_data2 : // Sign-extend immediate for B-type
               (id_ex_instr_type == 4'b0101) ? {{12{id_ex_imm[19]}}, id_ex_imm} : 
               (id_ex_instr_type == 4'b0110) ? {id_ex_imm, 12'h000} :
               (id_ex_instr_type == 4'b1000) ? 32'h00000004 :
               (id_ex_instr_type == 4'b1001) ? 32'h00000004 :
               (id_ex_instr_type == 4'b1010) ? {{11{id_ex_imm[19]}}, id_ex_imm, 1'b0} :
               (id_ex_instr_type == 4'b1011) ? {{12{id_ex_imm[19]}}, id_ex_imm} : 32'h00000000; // Sign-extend immediate for J-type


assign write_back_data = (id_ex_instr_type == 4'b0000) ? alu_result : 
                        (id_ex_instr_type == 4'b0001) ?  (id_ex_load_size == 3'b000) ? {{24{data_out[7]}}, data_out[7:0]} : 
                                                        (id_ex_load_size == 3'b001) ? {{16{data_out[15]}}, data_out[15:0]} :
                                                        (id_ex_load_size == 3'b010) ? data_out :
                                                        (id_ex_load_size == 3'b011) ? {24'b0, data_out[7:0]} : 
                                                        (id_ex_load_size == 3'b100) ? {16'b0, data_out[15:0]} : 
                                                        data_out :
                        (id_ex_instr_type == 4'b0010) ? alu_result : 
                        (id_ex_instr_type == 4'b0011) ? data_out : 
                        (id_ex_instr_type == 4'b0100) ? 32'h00000000 : 
                        (id_ex_instr_type == 4'b0101) ? 32'h00000000 : 
                        (id_ex_instr_type == 4'b0110) ? alu_result :
                        (id_ex_instr_type == 4'b0111) ? {id_ex_imm, 12'h000} :
                        (id_ex_instr_type == 4'b1000) ? alu_result :
                        (id_ex_instr_type == 4'b1001) ? alu_result : 32'h00000000;

assign addr = (id_ex_instr_type == 4'b0001) ? alu_result : 
              (id_ex_instr_type == 4'b0011) ? alu_result : 32'h00000000;

wire [3:0] byte_en;
assign byte_en = (id_ex_instr_type == 4'b0011) ? (
                     (id_ex_load_size == 3'b000) ? 4'b0001 : // SB
                     (id_ex_load_size == 3'b001) ? 4'b0011 : // SH
                     (id_ex_load_size == 3'b010) ? 4'b1111 : 4'b0000 // SW
                 ) : 4'b0000;

assign write_data = read_data2; 

wire comparison_out;
assign comparison_out = (id_ex_alu_op == 4'b0001) ? zero_flag : alu_result[0];

assign branch_taken = ((id_ex_instr_type == 4'b0100) && 
                      ((id_ex_load_size == 3'b000) ? comparison_out : !comparison_out)) ||
                      (id_ex_instr_type == 4'b1000) || (id_ex_instr_type == 4'b1001); // Branch taken for B-type, JAL, and JALR instructions

assign jump = (id_ex_instr_type == 4'b0101) || (id_ex_instr_type == 4'b1010) || (id_ex_instr_type == 4'b1011);

assign d_in = (id_ex_instr_type == 4'b1011) ? {alu_result[31:1], 1'b0} : alu_result;

data_mem mem(

    // input 
    .clk(clk),
    .addr(addr), // this addr can come for stage 2( directly) or in stage 3 
    .write_en(id_ex_write_en),
    .byte_en(byte_en),
    .write_data(write_data), // **** wrtie back from Execute stage
    
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
    .read_reg1(id_ex_reg_sel_a),
    .read_reg2(id_ex_reg_sel_b),


    // output
    .read_data1(read_data1),
    .read_data2(read_data2) 
);



alu alu_unit(
    .alu_en(id_ex_alu_en),
    .A(alu_A),
    .B(alu_B),
    .alu_op(id_ex_alu_op),
    .result(alu_result),
    .zero_flag(zero_flag),
    .carry(carry)
);

// *********
// this write data can come from 3 place 1) Mem using READ command 2) ALU using SUB,MOV ADD commands 3) from instruction direct  by immediate value 
// If Opcode is 0 (LOADI), take immediate. If 4 (READ), take RAM. Else ALU.

//***********


endmodule