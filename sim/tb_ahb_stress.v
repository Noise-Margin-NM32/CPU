`timescale 1ns/1ps
`default_nettype wire

module tb_ahb_stress();

    reg clk;
    reg rstn;

    // AHB Instruction Master Wires
    wire [1:0]  instr_htrans;
    wire [31:0] instr_haddr;
    wire        instr_hwrite;
    wire [2:0]  instr_hsize;
    wire [31:0] instr_hwdata;
    wire        rom_hready;
    wire [31:0] instr_hrdata;
    wire        instr_hresp;

    // AHB Data Master Wires
    wire        data_hbusreq;
    wire [1:0]  data_htrans;
    wire [31:0] data_haddr;
    wire        data_hwrite;
    wire [2:0]  data_hsize;
    wire [31:0] data_hwdata;
    wire        ram_hready;
    wire [31:0] data_hrdata;
    wire        data_hresp;

    // Testbench wait-state & arbitration control registers
    reg tb_instr_hready;
    reg tb_data_hready;
    reg tb_data_hgrant;

    wire cpu_instr_hready = rom_hready && tb_instr_hready;
    wire cpu_data_hready  = ram_hready && tb_data_hready;

    // Instantiate DUT (CPU Core)
    top_piplined uut (
        .clk(clk),
        .rstn(rstn),
        .instr_htrans(instr_htrans),
        .instr_haddr(instr_haddr),
        .instr_hwrite(instr_hwrite),
        .instr_hsize(instr_hsize),
        .instr_hwdata(instr_hwdata),
        .instr_hready(cpu_instr_hready),
        .instr_hrdata(instr_hrdata),
        .instr_hresp(instr_hresp),
        .data_hbusreq(data_hbusreq),
        .data_htrans(data_htrans),
        .data_haddr(data_haddr),
        .data_hwrite(data_hwrite),
        .data_hsize(data_hsize),
        .data_hwdata(data_hwdata),
        .data_hgrant(tb_data_hgrant),
        .data_hready(cpu_data_hready),
        .data_hrdata(data_hrdata),
        .data_hresp(data_hresp)
    );

    // Instantiate Instruction ROM Slave
    instruction_mem ROM (
        .HCLK(clk),
        .HRESETn(rstn),
        .HADDR(instr_haddr),
        .HTRANS(instr_htrans),
        .HWRITE(instr_hwrite),
        .HSIZE(instr_hsize),
        .HWDATA(instr_hwdata),
        .HREADY(cpu_instr_hready),
        .HREADYOUT(rom_hready),
        .HRDATA(instr_hrdata),
        .HRESP(instr_hresp)
    );

    // Instantiate Data RAM Slave
    data_mem mem (
        .HCLK(clk),
        .HRESETn(rstn),
        .HADDR(data_haddr),
        .HTRANS(data_htrans),
        .HWRITE(data_hwrite),
        .HSIZE(data_hsize),
        .HWDATA(data_hwdata),
        .HREADY(cpu_data_hready),
        .HREADYOUT(ram_hready),
        .HRDATA(data_hrdata),
        .HRESP(data_hresp)
    );

    always #5 clk = ~clk;

    integer test_errors = 0;

    initial begin
        clk = 0;
        rstn = 0;
        tb_instr_hready = 1'b1;
        tb_data_hready  = 1'b1;
        tb_data_hgrant  = 1'b1;

        // Load test instructions into ROM:
        // PC=0:  addi x1, x0, 15    (0x00F00093)
        // PC=4:  addi x2, x0, 25    (0x01900113)
        // PC=8:  add  x3, x1, x2    (0x002081B3) -> x3 = 40
        // PC=12: sw   x3, 0(x0)     (0x00302023) -> RAM[0] = 40
        // PC=16: lw   x4, 0(x0)     (0x00002203) -> x4 = 40
        // PC=20: addi x5, x4, 10    (0x00A20293) -> x5 = 50
        // PC=24: sw   x5, 4(x0)     (0x00502223) -> RAM[1] = 50
        // PC=28: jal  x0, 0         (0x0000006F) -> halt
        ROM.rom[0] = 32'h00F00093;
        ROM.rom[1] = 32'h01900113;
        ROM.rom[2] = 32'h002081B3;
        ROM.rom[3] = 32'h00302023;
        ROM.rom[4] = 32'h00002203;
        ROM.rom[5] = 32'h00A20293;
        ROM.rom[6] = 32'h00502223;
        ROM.rom[7] = 32'h0000006F;

        #20;
        rstn = 1;

        $display("==================================================");
        $display("   AHB-Lite Protocol Stress & Verification Test   ");
        $display("==================================================");

        // ---------------------------------------------------------------------
        // Test 1: Inject Instruction Bus Wait States (HREADY = 0)
        // ---------------------------------------------------------------------
        $display("[1/3] Testing Instruction Fetch Wait States...");
        @(posedge clk);
        @(posedge clk);
        // Inject 2-cycle wait state on instruction bus
        tb_instr_hready = 1'b0;
        @(posedge clk);
        @(posedge clk);
        tb_instr_hready = 1'b1;

        // ---------------------------------------------------------------------
        // Test 2: Inject Data Bus Arbitration Delay (HGRANT = 0)
        // ---------------------------------------------------------------------
        $display("[2/3] Testing Data Bus Arbitration Delay (HGRANT deassertion)...");
        // Wait until CPU asserts HBUSREQ for the first store (PC=12)
        wait(data_hbusreq == 1'b1);
        @(negedge clk);
        // Deassert HGRANT for 2 cycles to simulate bus contention
        tb_data_hgrant = 1'b0;
        $display("      HBUSREQ detected, forcing HGRANT=0 for 2 cycles...");
        @(posedge clk);
        @(posedge clk);
        @(negedge clk);
        tb_data_hgrant = 1'b1;
        $display("      HGRANT restored to 1");

        // ---------------------------------------------------------------------
        // Test 3: Inject Data Bus Wait States (HREADY = 0)
        // ---------------------------------------------------------------------
        $display("[3/3] Testing Data Bus Wait States (HREADY=0 during transfer)...");
        // Wait until next bus request (Load at PC=16)
        wait(data_hbusreq == 1'b1);
        @(posedge clk);
        // Inject 3 wait states on data memory
        tb_data_hready = 1'b0;
        $display("      Injecting 3 wait states on data bus...");
        repeat(3) @(posedge clk);
        tb_data_hready = 1'b1;
        $display("      Data bus HREADY restored to 1");

        // Wait for program to reach halt
        #500;

        // Verify Memory Results
        $display("--------------------------------------------------");
        $display("Verification Results:");
        $display("RAM[0] = %0d (Expected: 40)", mem.ram[0]);
        $display("RAM[1] = %0d (Expected: 50)", mem.ram[1]);
        $display("x1     = %0d (Expected: 15)", uut.reg_file.registers[1]);
        $display("x2     = %0d (Expected: 25)", uut.reg_file.registers[2]);
        $display("x3     = %0d (Expected: 40)", uut.reg_file.registers[3]);
        $display("x4     = %0d (Expected: 40)", uut.reg_file.registers[4]);
        $display("x5     = %0d (Expected: 50)", uut.reg_file.registers[5]);

        if (mem.ram[0] == 40 && mem.ram[1] == 50 &&
            uut.reg_file.registers[1] == 15 && uut.reg_file.registers[2] == 25 &&
            uut.reg_file.registers[3] == 40 && uut.reg_file.registers[4] == 40 &&
            uut.reg_file.registers[5] == 50) begin
            $display("==================================================");
            $display(">>> ALL AHB PROTOCOL STRESS TESTS PASSED! <<<");
            $display("==================================================");
        end else begin
            $display("==================================================");
            $display(">>> ERROR: ONE OR MORE AHB STRESS CHECKS FAILED! <<<");
            $display("==================================================");
            test_errors = test_errors + 1;
        end

        if (test_errors == 0)
            $finish;
        else
            $fatal(1);
    end

endmodule
