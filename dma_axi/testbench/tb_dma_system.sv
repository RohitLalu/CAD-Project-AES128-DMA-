`timescale 1ns / 1ps
//============================================================
// Testbench: tb_dma_system
// Description:
//   Testbench for DMA system with AXI-Lite slave, DMA core,
//   and memory block. Performs 1-word transfer and displays
//   memory contents.
//============================================================

module tb_dma_system;

    // Clock and reset
    logic clk;
    logic rstn;

    always #5 clk = ~clk; // 100 MHz

    initial begin
        clk = 0;
        rstn = 0;
        #50 rstn = 1;
    end

    //============================================================
    // AXI-Lite CPU <-> Slave signals
    //============================================================
    logic        C_AWVALID, S_AWREADY;
    logic [31:0] C_AWADDR;
    logic        C_WVALID, S_WREADY;
    logic [31:0] C_WDATA;
    logic        S_BVALID, C_BREADY;
    logic        C_ARVALID, S_ARREADY;
    logic [31:0] C_ARADDR;
    logic        S_RVALID, C_RREADY;
    logic [31:0] S_RDATA;

    //============================================================
    // AXI-Lite DMA Master <-> Memory signals
    //============================================================
    logic        M_AWVALID, MEM_AWREADY;
    logic [31:0] M_AWADDR;
    logic        M_WVALID, MEM_WREADY;
    logic [31:0] M_WDATA;
    logic        MEM_BVALID, M_BREADY;
    logic        M_ARVALID, MEM_ARREADY;
    logic [31:0] M_ARADDR;
    logic        MEM_RVALID, M_RREADY;
    logic [31:0] MEM_RDATA;

    //============================================================
    // Control/Status wires
    //============================================================
    logic [31:0] src_addr, dst_addr, len;
    logic ctrl_start, status_done;

    //============================================================
    // DUT instantiations
    //============================================================

    // Slave (CPU <-> DMA regs)
    axi_lite_slave u_slave (
        .clk(clk),
        .rstn(rstn),
        .awvalid(C_AWVALID),
        .awaddr(C_AWADDR),
        .awready(S_AWREADY),
        .wvalid(C_WVALID),
        .wdata(C_WDATA),
        .wready(S_WREADY),
        .bready(C_BREADY),
        .bvalid(S_BVALID),
        .arvalid(C_ARVALID),
        .araddr(C_ARADDR),
        .arready(S_ARREADY),
        .rready(C_RREADY),
        .rvalid(S_RVALID),
        .rdata(S_RDATA),
        .o_src_addr(src_addr),
        .o_dst_addr(dst_addr),
        .o_len(len),
        .o_ctrl_start(ctrl_start),
        .i_status_done(status_done),
        .o_status_done()
    );

    // DMA core (Master)
    dma_core u_dma (
        .clk(clk),
        .rstn(rstn),
        .src_addr(src_addr),
        .dst_addr(dst_addr),
        .len(len),
        .ctrl_start(ctrl_start),
        .status_done(status_done),

        .awready(MEM_AWREADY),
        .awaddr(M_AWADDR),
        .awvalid(M_AWVALID),
        .wready(MEM_WREADY),
        .wdata(M_WDATA),
        .wvalid(M_WVALID),
        .bvalid(MEM_BVALID),
        .bready(M_BREADY),
        .arready(MEM_ARREADY),
        .araddr(M_ARADDR),
        .arvalid(M_ARVALID),
        .rdata(MEM_RDATA),
        .rvalid(MEM_RVALID),
        .rready(M_RREADY)
    );

    // Memory
    axi_lite_mem #(
        .ADDR_WIDTH(32),
        .DATA_WIDTH(32),
        .MEM_DEPTH(256)
    ) u_mem (
        .clk(clk),
        .rstn(rstn),
        .awvalid(M_AWVALID),
        .awaddr(M_AWADDR),
        .awready(MEM_AWREADY),
        .wvalid(M_WVALID),
        .wdata(M_WDATA),
        .wready(MEM_WREADY),
        .bvalid(MEM_BVALID),
        .bready(M_BREADY),
        .arvalid(M_ARVALID),
        .araddr(M_ARADDR),
        .arready(MEM_ARREADY),
        .rvalid(MEM_RVALID),
        .rdata(MEM_RDATA),
        .rready(M_RREADY)
    );

    //============================================================
    // Test sequence
    //============================================================
    initial begin
        // Default signals
        C_AWVALID = 0; C_AWADDR = 0;
        C_WVALID = 0; C_WDATA = 0;
        C_BREADY = 1;
        C_ARVALID = 0; C_ARADDR = 0;
        C_RREADY = 1;

        wait(rstn == 1);
        @(posedge clk);

        // --------------------------------------------------------
        // Preload source memory (mem[0])
        // --------------------------------------------------------
        u_mem.mem[4] = 32'hDDDD_DDDA;
        u_mem.mem[5] = 32'hDDDD_DDDB;
        u_mem.mem[6] = 32'hDDDD_DDDC;
        u_mem.mem[7] = 32'hDDDD_DDDD;

        // --------------------------------------------------------
        // Program slave registers via AXI-lite writes
        // --------------------------------------------------------
        axi_write(32'h00, 32'h4);  // src_addr = 4
        axi_write(32'h04, 32'ha); // dst_addr = 10
        axi_write(32'h08, 32'h4);  // len = 4 word
        axi_write(32'h0C, 32'h1);  // ctrl_start = 1

        // Wait for DMA to finish
        wait(status_done);
        $display("DMA completed!");

        // --------------------------------------------------------
        // Check destination memory
        // --------------------------------------------------------
        $display("Dest[0] (mem[4]) = %h", u_mem.mem[4]);
        $display("=== Memory Contents ===");
        for (int i = 0; i < 20; i = i + 1) begin
            $display("mem[%0d] = %h", i, u_mem.mem[i]);
        end

        #2050 $finish;
    end

    //============================================================
    // AXI-lite write task (CPU side)
    //============================================================
    task axi_write(input [31:0] addr, input [31:0] data);
        @(posedge clk);
        C_AWADDR  <= addr;
        C_AWVALID <= 1;
        C_WDATA   <= data;
        C_WVALID  <= 1;
        wait(S_AWREADY && S_WREADY);
        @(posedge clk);
        C_AWVALID <= 0;
        C_WVALID  <= 0;
        wait(S_BVALID);
        @(posedge clk);
    endtask

endmodule
