`timescale 1ns/1ps
`default_nettype wire

module top_piplined #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input  wire                   clk,
    input  wire                   rstn,

    // =========================================================================
    // Instruction Port (AHB-Lite Master - Read Only)
    // =========================================================================
    output wire [1:0]             instr_htrans,
    output wire [ADDR_WIDTH-1:0]  instr_haddr,
    output wire                   instr_hwrite,  // Tied to 1'b0
    output wire [2:0]             instr_hsize,   // Tied to 3'b010
    output wire [DATA_WIDTH-1:0]  instr_hwdata,  // Tied to 32'h0
    input  wire                   instr_hready,
    input  wire [DATA_WIDTH-1:0]  instr_hrdata,
    input  wire                   instr_hresp,

    // =========================================================================
    // Data Port (AHB Master)
    // =========================================================================
    output reg                    data_hbusreq,
    output reg  [1:0]             data_htrans,
    output reg  [ADDR_WIDTH-1:0]  data_haddr,
    output reg                    data_hwrite,
    output reg  [2:0]             data_hsize,
    output reg  [DATA_WIDTH-1:0]  data_hwdata,
    input  wire                   data_hgrant,
    input  wire                   data_hready,
    input  wire [DATA_WIDTH-1:0]  data_hrdata,
    input  wire                   data_hresp
);

    // Static AHB-Lite Instruction Port Tie-offs
    assign instr_hwrite = 1'b0;
    assign instr_hsize  = 3'b010; // 32-bit instruction word
    assign instr_hwdata = 32'h00000000;

    // =========================================================================
    // Stage 1: IF (Instruction Fetch)
    // =========================================================================
    wire [31:0] pc;
    wire [31:0] branch_target;
    wire        branch_taken;
    wire        jump;

    wire        pc_enable;
    wire        if_id_enable;
    wire        ex_mem_enable;
    wire        insert_bubble;
    wire        freeze_all;
    wire        stall_stage1_2;

    program_counter pc_inst (
        .clk(clk),
        .rstn(rstn),
        .en(pc_enable),
        .jump(branch_taken || jump),
        .d_in(branch_target),
        .halt(!pc_enable),
        .pc(pc)
    );

    assign instr_haddr = pc;

    // Instruction Fetch Tracking & Skid Buffer
    reg [31:0] fetch_pc;
    reg        fetch_valid;
    reg [31:0] skid_instr;
    reg [31:0] skid_pc;
    reg        skid_valid;

    assign instr_htrans = (!rstn) ? 2'b00 :
                          (stall_stage1_2 && skid_valid) ? 2'b00 : 2'b10;

    // IF/ID Pipeline Register
    reg [31:0] if_id_pc;
    reg [31:0] if_id_instr;

    wire stall_imem = fetch_valid && !instr_hready;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            fetch_pc     <= 32'h00000000;
            fetch_valid  <= 1'b0;
            skid_instr   <= 32'h00000013;
            skid_pc      <= 32'h00000000;
            skid_valid   <= 1'b0;
            if_id_pc     <= 32'h00000000;
            if_id_instr  <= 32'h00000013; // NOP (ADDI x0, x0, 0)
        end else if (instr_hready) begin
            if (!stall_stage1_2) begin
                if (branch_taken || jump) begin
                    if_id_instr <= 32'h00000013; // Flush wrong-path instruction to NOP
                    if_id_pc    <= branch_target;
                    fetch_pc    <= branch_target;
                    fetch_valid <= 1'b0;
                    skid_valid  <= 1'b0;
                end else if (skid_valid) begin
                    // Consume skid buffer
                    if_id_instr <= skid_instr;
                    if_id_pc    <= skid_pc;
                    skid_valid  <= 1'b0;
                    fetch_pc    <= pc;
                    fetch_valid <= 1'b1;
                end else if (if_id_enable) begin
                    if (fetch_valid) begin
                        if_id_instr <= instr_hrdata;
                        if_id_pc    <= fetch_pc;
                    end else begin
                        if_id_instr <= 32'h00000013;
                        if_id_pc    <= pc;
                    end
                    fetch_pc    <= pc;
                    fetch_valid <= 1'b1;
                end
            end else begin
                // Pipeline is frozen (e.g. data bus transfer or ALU stall)
                if (fetch_valid && !skid_valid) begin
                    skid_instr  <= instr_hrdata;
                    skid_pc     <= fetch_pc;
                    skid_valid  <= 1'b1;
                    fetch_valid <= 1'b0;
                end
            end
        end
    end

    // =========================================================================
    // Stage 2: ID/EX (Decode, Register Read, Fast ALU & Multi-Unit Issue)
    // =========================================================================
    wire [4:0]  reg_sel_a;
    wire [4:0]  reg_sel_b;
    wire        en_write;
    wire [4:0]  write_reg;
    wire [4:0]  alu_op;
    wire        write_en;
    wire [19:0] imm;
    wire        alu_en;
    wire [3:0]  instr_type;
    wire [2:0]  load_size;

    control_unit cu (
        .instr(if_id_instr),
        .reg_sel_a(reg_sel_a),
        .reg_sel_b(reg_sel_b),
        .en_write(en_write),
        .write_reg(write_reg),
        .alu_op(alu_op),
        .write_en(write_en),
        .imm(imm),
        .alu_en(alu_en),
        .instr_type(instr_type),
        .load_size(load_size)
    );

    // Register File & Stage 3 Writeback Connections
    reg  [31:0] ex_mem_alu_result;
    reg  [31:0] ex_mem_write_data;
    reg  [4:0]  ex_mem_write_reg;
    reg         ex_mem_en_write;
    reg         ex_mem_write_en;
    reg  [3:0]  ex_mem_instr_type;
    reg  [2:0]  ex_mem_load_size;

    wire [31:0] write_back_data;
    wire [31:0] read_data1;
    wire [31:0] read_data2;

    register_file reg_file (
        .clk(clk),
        .rstn(rstn),
        .en_write(ex_mem_en_write && !freeze_all),
        .write_reg(ex_mem_write_reg),
        .write_data(write_back_data),
        .read_reg1(reg_sel_a),
        .read_reg2(reg_sel_b),
        .read_data1(read_data1),
        .read_data2(read_data2)
    );

    // Operand Forwarding from Stage 3 (MEM/WB) to Stage 2 (ID/EX)
    wire forward_a = ex_mem_en_write && (ex_mem_write_reg != 5'd0) && (ex_mem_write_reg == reg_sel_a);
    wire forward_b = ex_mem_en_write && (ex_mem_write_reg != 5'd0) && (ex_mem_write_reg == reg_sel_b);

    wire [31:0] fwd_data_a = forward_a ? write_back_data : read_data1;
    wire [31:0] fwd_data_b = forward_b ? write_back_data : read_data2;

    // ALU Input Operand Multiplexing
    wire [31:0] alu_A = (instr_type == 4'b0110) ? if_id_pc : // AUIPC: PC + imm
                        (instr_type == 4'b1000) ? if_id_pc : // JAL: PC + 4 (return address)
                        (instr_type == 4'b1001) ? if_id_pc : // JALR: PC + 4 (return address)
                        fwd_data_a;

    wire [31:0] alu_B = (instr_type == 4'b0000) ? fwd_data_b :                                  // R-type
                        (instr_type == 4'b0001) ? {{12{imm[19]}}, imm} :                        // IL-type
                        (instr_type == 4'b0010) ? {{12{imm[19]}}, imm} :                        // IA-type
                        (instr_type == 4'b0011) ? {{12{imm[19]}}, imm} :                        // S-type
                        (instr_type == 4'b0100) ? fwd_data_b :                                  // B-type (for comparison)
                        (instr_type == 4'b0110) ? {imm, 12'h000} :                              // AUIPC
                        (instr_type == 4'b0111) ? {imm, 12'h000} :                              // LUI
                        (instr_type == 4'b1000) ? 32'h00000004 :                                // JAL (computes PC+4)
                        (instr_type == 4'b1001) ? 32'h00000004 : 32'h00000000;                  // JALR (computes PC+4)

    // ALU Subsystem Wrapper
    wire [31:0] alu_result;
    wire        carry;
    wire        zero_flag;
    wire        slt_result;
    wire        sltu_result;
    wire        alu_busy;
    wire        alu_done;
    wire [1:0]  active_unit;

    alu alu_unit (
        .clk(clk),
        .rstn(rstn),
        .alu_en(alu_en),
        .A(alu_A),
        .B(alu_B),
        .alu_op(alu_op),
        .result(alu_result),
        .carry(carry),
        .zero_flag(zero_flag),
        .slt_result(slt_result),
        .sltu_result(sltu_result),
        .alu_busy(alu_busy),
        .alu_done(alu_done),
        .active_unit(active_unit)
    );

    // Branch & Jump Condition Evaluation (Stage 2)
    wire branch_condition_met = (load_size == 3'b000) ? zero_flag :     // BEQ
                                (load_size == 3'b001) ? !zero_flag :    // BNE
                                (load_size == 3'b010) ? slt_result :    // BLT
                                (load_size == 3'b011) ? !slt_result :   // BGE
                                (load_size == 3'b100) ? sltu_result :   // BLTU
                                (load_size == 3'b101) ? !sltu_result :  // BGEU
                                1'b0;

    assign branch_taken = (instr_type == 4'b0100) && branch_condition_met;
    assign jump         = (instr_type == 4'b1000) || (instr_type == 4'b1001); // JAL / JALR

    assign branch_target = (instr_type == 4'b1001) ? ((fwd_data_a + {{12{imm[19]}}, imm}) & ~32'd1) : // JALR: (rs1 + imm) & ~1
                           (instr_type == 4'b1000) ? (if_id_pc + {{11{imm[19]}}, imm, 1'b0}) :        // JAL: PC + imm
                           (instr_type == 4'b0100) ? (if_id_pc + {{12{imm[19]}}, imm}) :               // Branch: PC + imm
                           (pc + 4);

    // =========================================================================
    // Hazard Detection, Scoreboard & Stall Control
    // =========================================================================
    wire stall_alu_busy = alu_busy;

    // Load-Use Hazard: Instruction in Stage 2 depends on a Load currently in Stage 3
    wire stall_load_use = (ex_mem_instr_type == 4'b0001) && (ex_mem_write_reg != 5'd0) &&
                          ((ex_mem_write_reg == reg_sel_a) || (ex_mem_write_reg == reg_sel_b));

    wire stall_dmem;

    assign freeze_all     = stall_dmem;
    assign stall_stage1_2 = freeze_all || stall_alu_busy || stall_load_use || stall_imem;
    assign insert_bubble  = stall_alu_busy || stall_load_use;

    assign pc_enable      = !stall_stage1_2;
    assign if_id_enable   = !stall_stage1_2;
    assign ex_mem_enable  = !freeze_all;

    // EX/MEM Pipeline Register (Stage 2 -> Stage 3)
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            ex_mem_alu_result <= 32'h00000000;
            ex_mem_write_data <= 32'h00000000;
            ex_mem_write_reg  <= 5'd0;
            ex_mem_en_write   <= 1'b0;
            ex_mem_write_en   <= 1'b0;
            ex_mem_instr_type <= 4'd0;
            ex_mem_load_size  <= 3'd0;
        end else if (freeze_all) begin
            // Hold Stage 3 registers during memory wait-state
        end else if (insert_bubble) begin
            // Inject NOP Bubble into Stage 3 to prevent data corruption
            ex_mem_alu_result <= 32'h00000000;
            ex_mem_write_data <= 32'h00000000;
            ex_mem_write_reg  <= 5'd0;
            ex_mem_en_write   <= 1'b0;
            ex_mem_write_en   <= 1'b0;
            ex_mem_instr_type <= 4'd0;
            ex_mem_load_size  <= 3'd0;
        end else begin
            // Normal advance from Stage 2 to Stage 3
            ex_mem_alu_result <= alu_result;
            ex_mem_write_data <= fwd_data_b; // Store data (forwarded)
            ex_mem_write_reg  <= write_reg;
            ex_mem_en_write   <= en_write;
            ex_mem_write_en   <= write_en;
            ex_mem_instr_type <= instr_type;
            ex_mem_load_size  <= load_size;
        end
    end

    // =========================================================================
    // Stage 3: MEM/WB (Memory Access & Writeback) with AHB Master FSM
    // =========================================================================
    localparam D_IDLE = 1'b0;
    localparam D_DATA = 1'b1;

    reg d_state;

    wire dmem_req = (ex_mem_instr_type == 4'b0001) || ex_mem_write_en;
    wire [31:0] mem_addr = ex_mem_alu_result;

    // Sub-word formatting for HWDATA (byte/halfword replication across bus lanes)
    wire [31:0] formatted_write_data =
        (ex_mem_load_size == 3'b000) ? {4{ex_mem_write_data[7:0]}} :   // SB
        (ex_mem_load_size == 3'b001) ? {2{ex_mem_write_data[15:0]}} :  // SH
        ex_mem_write_data;                                              // SW

    // Transfer size calculation from RISC-V load/store size
    reg [2:0] calc_hsize;
    always @(*) begin
        case (ex_mem_load_size)
            3'b000:  calc_hsize = 3'b000; // Byte
            3'b001:  calc_hsize = 3'b001; // Halfword
            3'b010:  calc_hsize = 3'b010; // Word
            3'b011:  calc_hsize = 3'b000; // Byte unsigned
            3'b100:  calc_hsize = 3'b001; // Halfword unsigned
            default: calc_hsize = 3'b010;
        endcase
    end

    // Combinational AHB Master Outputs
    always @(*) begin
        if (d_state == D_IDLE) begin
            if (dmem_req) begin
                data_hbusreq = 1'b1;
                data_htrans  = 2'b10; // NONSEQ Address Phase
                data_haddr   = mem_addr;
                data_hwrite  = ex_mem_write_en;
                data_hsize   = calc_hsize;
                data_hwdata  = formatted_write_data;
            end else begin
                data_hbusreq = 1'b0;
                data_htrans  = 2'b00; // IDLE
                data_haddr   = 32'h00000000;
                data_hwrite  = 1'b0;
                data_hsize   = 3'b010;
                data_hwdata  = 32'h00000000;
            end
        end else begin // D_DATA
            data_hbusreq = 1'b0;
            data_htrans  = 2'b00; // IDLE
            data_haddr   = mem_addr;
            data_hwrite  = ex_mem_write_en;
            data_hsize   = calc_hsize;
            data_hwdata  = formatted_write_data;
        end
    end

    // Pipeline stall for Data Port:
    // When in D_IDLE, dmem_req requires freezing Stage 3 for the upcoming Data Phase.
    // When in D_DATA, wait states from slave (!data_hready) extend the freeze.
    assign stall_dmem = (d_state == D_IDLE) ? dmem_req : !data_hready;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            d_state <= D_IDLE;
        end else begin
            case (d_state)
                D_IDLE: begin
                    if (dmem_req && data_hgrant && data_hready) begin
                        // Address phase accepted this cycle -> proceed to Data Phase next cycle
                        d_state <= D_DATA;
                    end
                end
                D_DATA: begin
                    if (data_hready) begin
                        // Data phase completed
                        d_state <= D_IDLE;
                    end
                end
            endcase
        end
    end

    // Sub-word Load Alignment & Sign Extension from HRDATA
    wire [31:0] shifted_data_out = data_hrdata >> (8 * mem_addr[1:0]);

    wire [31:0] aligned_load_data =
        (ex_mem_load_size == 3'b000) ? {{24{shifted_data_out[7]}}, shifted_data_out[7:0]} :   // LB
        (ex_mem_load_size == 3'b001) ? {{16{shifted_data_out[15]}}, shifted_data_out[15:0]} : // LH
        (ex_mem_load_size == 3'b010) ? shifted_data_out :                                      // LW
        (ex_mem_load_size == 3'b011) ? {24'h000000, shifted_data_out[7:0]} :                  // LBU
        (ex_mem_load_size == 3'b100) ? {16'h0000, shifted_data_out[15:0]} :                   // LHU
        shifted_data_out;

    // Writeback Data Selection
    assign write_back_data = (ex_mem_instr_type == 4'b0001) ? aligned_load_data : ex_mem_alu_result;

endmodule