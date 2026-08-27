module top_piplined(
    input clk,
    input rstn
);


// Stage 1: Fetch(IF) signals: PC + ROM 


// Stage 2: Decode (ID) Signals: Control UNit 



// Stage 3: EXECUTE 




// ******STAGE 1

wire en, jump; // en- pc enable  
wire [31:0] d_in; // addr to jump 
wire [31:0] pc;
wire branch_taken; // branch decision wire
reg halt;
reg i_valid;
reg i_ready;


assign en = 1'b1; // always enable the pc to increment
// assign jump = 1'b0; // no jump in this design, for now
wire [31:0] instruction_r; // instruction read from ROM
// reg [31:0] instruction; //instruction retruned from ROM to cu


// Pipline Register; IF/ID Register 
// reg [31:0] if_id_instr;
reg [31:0] if_id_pc; // pc value to be passed to the next stage (ID) for branch and jump instructions

program_counter pc_inst(
    // input 
    .clk(clk), .rstn(rstn), .en(en), .jump(jump), .d_in(d_in), .halt(halt),
    // output 
    .pc(pc)
);


instruction_mem ROM(
    .clk(clk),
    .addr(pc),
    // .halt(halt),
    .rstn(rstn),
    .ready(i_ready),
    // output
    .valid(i_valid),
    .ins_out(instruction_r)
);

assign i_ready = ~halt; // ready signal is high when halt is low, indicating that the instruction memory is ready to provide the next instruction


// if_id 
always @(posedge clk or negedge rstn) begin
    if(!rstn || jump) begin
        // if_id_instr <= 32'h00000013; // NOP instruction
        // instruction <= 32'h00000013; // NOP instruction/
        if_id_pc    <= if_id_pc; // NOP instruction
    end
    else begin 
        // if_id_instr <= instruction;
        // instruction <= instruction_r;
        if_id_pc <= pc;
    end
end 


// STAGE 2: Decode + Execute

// Decode goal: figure out what to do and get the data

// assign instruction = instruction_r; // assign the instruction read from ROM to the instruction wire for decoding

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

//ALU
wire [31:0] alu_result;
wire zero_flag, carry;
wire [31:0] alu_A, alu_B;

wire [31:0] read_data1,read_data2; //coming by reading the register-- can either go back to register or alu or memory

//other wirs
wire comparison_out;
assign comparison_out = (alu_op == 5'b00001) ? zero_flag : alu_result[0];

assign branch_taken = ((x_m_instr_type == 4'b0100) && ((x_m_load_size == 3'b000) ? comparison_out : !comparison_out)) ||
                      (x_m_instr_type == 4'b1000) || (x_m_instr_type == 4'b1001); // Branch taken for B-type, JAL, and JALR instructions


// -- PIpline Register: ID/EXECUTE

reg [4:0] x_m_write_reg; // choosen write reg by cu to register file 
reg [4:0] x_m_alu_op; //alu_opcode
reg [4:0] x_m_reg_sel_a,x_m_reg_sel_b; // register selectors returned by the control unit  
reg x_m_en_write; // write enable returned by the cu to the mem module 
// reg [31:0] x_m_data_out;
reg x_m_write_en; // write enable to write in mem after decoded in cpu 

reg [19:0] x_m_imm;//???

reg [3:0] x_m_instr_type; // to identify the type of instruction (R, I, S, B, U, J) 000-R, 001-IL, 010-IA, 011-S, 100-B, 101-U, 110-J
reg [2:0] x_m_load_size; // to identify the size of the data
reg x_m_alu_en;
reg x_m_zero_flag;
reg [31:0] x_m_pc; // pc value to be passed to the next stage (ID) for branch and jump instructions

reg [31:0] x_m_alu_result; // result from the ALU to be passed to the next stage (MEM) for memory access instructions

assign alu_A = (instr_type == 4'b0000) ? read_data1 :
               (instr_type == 4'b0001) ? read_data1 :
               (instr_type == 4'b0010) ? read_data1 :
               (instr_type == 4'b0011) ? read_data1 :
               (instr_type == 4'b0100) ? read_data1 :
               (instr_type == 4'b0101) ? if_id_pc : 
               (instr_type == 4'b0110) ? if_id_pc :
               (instr_type == 4'b1000) ? if_id_pc :
               (instr_type == 4'b1001) ? if_id_pc :
               (instr_type == 4'b1010) ? if_id_pc :
               (instr_type == 4'b1011) ? read_data1 : 32'h00000000;

assign alu_B = (instr_type == 4'b0000) ? read_data2 :
               (instr_type == 4'b0001) ? {{12{imm[19]}}, imm} : // Sign-extend immediate for IL-type
               (instr_type == 4'b0010) ? {{12{imm[19]}}, imm} : // Sign-extend immediate for IA-type
               (instr_type == 4'b0011) ? {{12{imm[19]}}, imm} : // Sign-extend immediate for S-type
               (instr_type == 4'b0100) ? read_data2 : // Sign-extend immediate for B-type
               (instr_type == 4'b0101) ? {{12{imm[19]}}, imm} : 
               (instr_type == 4'b0110) ? {imm, 12'h000} :
               (instr_type == 4'b1000) ? 32'h00000004 :
               (instr_type == 4'b1001) ? 32'h00000004 :
               (instr_type == 4'b1010) ? {{11{imm[19]}}, imm, 1'b0} :
               (instr_type == 4'b1011) ? {{12{imm[19]}}, imm} : 32'h00000000; // Sign-extend immediate for J-type

assign jump = (x_m_instr_type == 4'b0101) || (x_m_instr_type == 4'b1010) || (x_m_instr_type == 4'b1011);

assign d_in = (x_m_instr_type == 4'b1011) ? {alu_result[31:1], 1'b0} : alu_result;

control_unit cu(
    // input 
    .instr(instruction_r),  
    // output 
    .instr_type(instr_type),

    //to ALU
    .alu_en(cu_alu_en),
    .alu_op(alu_op),
    .imm(imm),

    // to Register File
    .reg_sel_a(reg_sel_a),
    .reg_sel_b(reg_sel_b),
    .en_write(en_write),
    .write_reg(write_reg),

    // to Data Memory
    .write_en(write_en),
    .load_size(load_size)

    // .addr(addr),
    // .en(en),.load(load),
    // .load_instr(load_instr),
);

alu alu_unit(
    .alu_en(cu_alu_en),
    .A(alu_A),
    .B(alu_B),
    .alu_op(alu_op),
    .result(alu_result),
    .zero_flag(zero_flag),
    .carry(carry)
);

// pipline ID to Execute
always @(posedge clk or negedge rstn) begin

    if(!rstn) begin
        // x_m_alu_op <= 4'b0000;
        // x_m_reg_sel_a <=0;
        // x_m_reg_sel_b <=0;
        // x_m_imm <= 20'b00000000000000000000;
        // x_m_pc <= 32'h00000000;
        x_m_en_write <= 0;
        x_m_write_en <= 0;
        x_m_write_reg <= 5'b00000;
        x_m_instr_type <= 4'b0000;
        x_m_load_size <= 3'b000;
        // x_m_alu_en <= 1'b0;
        // x_m_zero_flag <= 1'b0;

    end 

    else begin 
        if(halt) begin
            // x_m_alu_op <= 4'b0000;
            // x_m_reg_sel_a <=x_m_reg_sel_a;
            // x_m_reg_sel_b <=x_m_reg_sel_b;
            // x_m_imm <= x_m_imm;
            // x_m_alu_en <= 1'b1;
            x_m_en_write <= x_m_en_write;
            x_m_write_en <= x_m_write_en;
            x_m_write_reg <= x_m_write_reg;
            x_m_instr_type <= (x_m_instr_type == 4'b0100) ? 4'b0101 :
                                (x_m_instr_type == 4'b1000) ? 4'b1010 :
                                (x_m_instr_type == 4'b1001) ? 4'b1011 : x_m_instr_type;
            x_m_load_size <= x_m_load_size;
            // x_m_zero_flag <= 1'b0;
            x_m_pc <= x_m_pc;
            

        end
        else begin
            // x_m_alu_op <= alu_op;
            // x_m_reg_sel_a <= reg_sel_a;
            // x_m_reg_sel_b <= reg_sel_b;
            // x_m_imm <= imm;
            // x_m_pc <= if_id_pc;
            // x_m_alu_en <= cu_alu_en;
            x_m_en_write <= en_write;
            x_m_write_en <= write_en;
            x_m_write_reg <= write_reg;
            x_m_instr_type <= instr_type;
            x_m_load_size <= load_size;
            x_m_alu_result <= alu_result;
            

            // x_m_zero_flag <= zero_flag;
        end
    end
end


// stage 3: Mem + WB

wire [31:0] write_data; // data from  from  register file to mem or data written to mem
wire [31:0] write_back_data; //  the data that actually goes to the reg values

// reading mem\
wire [31:0] addr; // address to be read from mem by the cu
wire [31:0] data_out; // data read from the mem to the ........



assign addr = (x_m_instr_type == 4'b0001) ? x_m_alu_result : 
              (x_m_instr_type == 4'b0011) ? x_m_alu_result : 32'h00000000;

wire [31:0] shifted_data_out;
assign shifted_data_out = data_out >> (8 * addr[1:0]);

assign write_back_data = (x_m_instr_type == 4'b0000) ? x_m_alu_result : 
                        (x_m_instr_type == 4'b0001) ?  (x_m_load_size == 3'b000) ? {{24{shifted_data_out[7]}}, shifted_data_out[7:0]} : 
                                                        (x_m_load_size == 3'b001) ? {{16{shifted_data_out[15]}}, shifted_data_out[15:0]} :
                                                        (x_m_load_size == 3'b010) ? shifted_data_out :
                                                        (x_m_load_size == 3'b011) ? {24'b0, shifted_data_out[7:0]} : 
                                                        (x_m_load_size == 3'b100) ? {16'b0, shifted_data_out[15:0]} : 
                                                        shifted_data_out :
                        (x_m_instr_type == 4'b0010) ? x_m_alu_result : 
                        (x_m_instr_type == 4'b0011) ? data_out : 
                        (x_m_instr_type == 4'b0100) ? 32'h00000000 : 
                        (x_m_instr_type == 4'b0101) ? 32'h00000000 : 
                        (x_m_instr_type == 4'b0110) ? x_m_alu_result :
                        (x_m_instr_type == 4'b0111) ? {x_m_imm, 12'h000} :
                        (x_m_instr_type == 4'b1000) ? x_m_alu_result :
                        (x_m_instr_type == 4'b1001) ? x_m_alu_result : 32'h00000000;

wire [3:0] byte_en;
assign byte_en = (x_m_instr_type == 4'b0011) ? (
                     (x_m_load_size == 3'b000) ? (4'b0001 << addr[1:0]) : // SB
                     (x_m_load_size == 3'b001) ? (4'b0011 << addr[1:0]) : // SH
                     (x_m_load_size == 3'b010) ? (4'b1111 << addr[1:0]) : 4'b0000 // SW
                 ) : 4'b0000;

assign write_data = (x_m_instr_type == 4'b0011) ? (
                        (x_m_load_size == 3'b000) ? {4{read_data2[7:0]}} :   // SB
                        (x_m_load_size == 3'b001) ? {2{read_data2[15:0]}} :  // SH
                        read_data2                                             // SW
                    ) : 32'h00000000; 



data_mem mem(

    // input 
    .clk(clk),
    .addr(addr), // this addr can come for stage 2( directly) or in stage 3 
    .write_en(x_m_write_en),
    .byte_en(byte_en),
    .write_data(write_data), // **** wrtie back from Execute stage
    
    // output
    .data_out(data_out) // getting data is stage 2
);


register_file reg_file(
    .clk(clk),
    .rstn(rstn),

    // input coming from execute stage
    .en_write(x_m_en_write),
    .write_reg(x_m_write_reg),
    .write_data(write_back_data), 
   
   // inputs (( reading reg in stage 2 ))
    .read_reg1(reg_sel_a),
    .read_reg2(reg_sel_b),


    // output
    .read_data1(read_data1),
    .read_data2(read_data2) 
);

always @(posedge clk or negedge rstn) begin
    if(!rstn) begin
        halt <= 1'b0;
    end
    else begin
        halt <= (instr_type == 4'b0001 && halt == 1'b0) ? 1'b1 : 1'b0; // halt the pc if load instruction is encountered
    end
end



// *********
// this write data can come from 3 place 1) Mem using READ command 2) ALU using SUB,MOV ADD commands 3) from instruction direct  by immediate value 
// If Opcode is 0 (LOADI), take immediate. If 4 (READ), take RAM. Else ALU.

//***********


endmodule