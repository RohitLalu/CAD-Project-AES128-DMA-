`timescale 1ns/1ps
module tb_dma_top;

    // ============================================================
    // Clock and Reset
    // ============================================================
    logic clk;
    logic rstn;
    always #5 clk = ~clk; // 100 MHz

    initial begin
        clk  = 0;
        rstn = 0;
        #50 rstn = 1;
    end

    // ============================================================
    // AXI-lite Slave (TB acts like CPU driving these)
    // ============================================================
    logic s_awvalid, s_awready; logic [31:0] s_awaddr;
    logic s_wvalid,  s_wready;  logic [31:0] s_wdata;
    logic s_bvalid,  s_bready;
    logic s_arvalid, s_arready; logic [31:0] s_araddr;
    logic s_rvalid,  s_rready;  logic [31:0] s_rdata;

    // ============================================================
    // DUT instantiation (dma_top)
    // ============================================================
    dma_top u_top (
        .clk(clk),
        .rstn(rstn),

        // Slave interface (control registers)
        .s_awvalid(s_awvalid), .s_awready(s_awready), .s_awaddr(s_awaddr),
        .s_wvalid(s_wvalid),   .s_wready(s_wready),   .s_wdata(s_wdata),
        .s_bvalid(s_bvalid),   .s_bready(s_bready),
        .s_arvalid(s_arvalid), .s_arready(s_arready), .s_araddr(s_araddr),
        .s_rvalid(s_rvalid),   .s_rready(s_rready),   .s_rdata(s_rdata)
    );

    // ============================================================
    // Test sequence
    // ============================================================
    initial begin
        // Default signals
        s_awvalid = 0; s_awaddr = 0;
        s_wvalid  = 0; s_wdata  = 0;
        s_bready  = 1;
        s_arvalid = 0; s_araddr = 0;
        s_rready  = 1;

        wait(rstn == 1);
        @(posedge clk);

        // --------------------------------------------------------
        // Preload source memory (mem[0] = 17)
        // --------------------------------------------------------
        u_top.u_mem.mem[0] = 32'd17;

        // --------------------------------------------------------
        // Program slave registers via AXI-lite writes (1 transfer)
        // --------------------------------------------------------
        axi_write(32'h00, 32'h0);   // src_addr = 0
        axi_write(32'h04, 32'h6);  // dst_addr = 0x06 ? mem[6]
        axi_write(32'h08, 32'h1);   // len = 1 word
        axi_write(32'h0C, 32'h1);   // ctrl_start = 1

        // Wait for DMA to finish
        wait(u_top.c_status_done);
        
        $display("DMA completed!");

        // --------------------------------------------------------
        // Dump memory contents after DMA
        // --------------------------------------------------------
        for (int i = 0; i < 20; i++) begin
            $display("mem[%0d] = %0d", i, u_top.u_mem.mem[i]);
        end

        #200 $finish;
    end

    // ============================================================
    // AXI-lite write task
    // ============================================================
    task axi_write(input [31:0] addr, input [31:0] data);
        @(posedge clk);
        s_awaddr  <= addr;
        s_awvalid <= 1;
        s_wdata   <= data;
        s_wvalid  <= 1;

        wait(s_awready && s_wready);
        @(posedge clk);
        s_awvalid <= 0;
        s_wvalid  <= 0;

        wait(s_bvalid);
        @(posedge clk);
    endtask

endmodule
