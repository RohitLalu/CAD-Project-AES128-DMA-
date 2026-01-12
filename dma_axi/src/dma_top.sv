`timescale 1ns / 1ps
module dma_top (
    input  logic clk,
    input  logic rstn,

    //============================================================
    // Slave (CPU <-> AXI-Lite slave) interface
    //============================================================
    input  logic        s_awvalid,
    input  logic [31:0] s_awaddr,
    output logic        s_awready,

    input  logic        s_wvalid,
    input  logic [31:0] s_wdata,
    output logic        s_wready,

    input  logic        s_bready,
    output logic        s_bvalid,

    input  logic        s_arvalid,
    input  logic [31:0] s_araddr,
    output logic        s_arready,

    input  logic        s_rready,
    output logic        s_rvalid,
    output logic [31:0] s_rdata
);

    //============================================================
    // Internal control/status wires (slave <-> core)
    //============================================================
    logic [31:0] c_src_addr, c_dst_addr, c_len;
    logic        c_ctrl_start, c_status_done;

    //============================================================
    // Interconnect wires (core <-> memory)
    //============================================================
    logic [31:0] m_awaddr, m_wdata, m_araddr, m_rdata;
    logic        m_awvalid, m_awready;
    logic        m_wvalid,  m_wready;
    logic        m_bvalid,  m_bready;
    logic        m_arvalid, m_arready;
    logic        m_rvalid,  m_rready;

    //============================================================
    // AXI-Lite Slave Instance
    //============================================================
    axi_lite_slave u_slave (
        .clk(clk), .rstn(rstn),

        // Write address/data/response
        .awvalid(s_awvalid), .awaddr(s_awaddr), .awready(s_awready),
        .wvalid(s_wvalid),   .wdata(s_wdata),   .wready(s_wready),
        .bready(s_bready),   .bvalid(s_bvalid),

        // Read address/data
        .arvalid(s_arvalid), .araddr(s_araddr), .arready(s_arready),
        .rready(s_rready),   .rvalid(s_rvalid), .rdata(s_rdata),

        // Outputs to DMA core
        .o_src_addr(c_src_addr),
        .o_dst_addr(c_dst_addr),
        .o_len(c_len),
        .o_ctrl_start(c_ctrl_start),

        // Input from DMA core
        .i_status_done(c_status_done),
        .o_status_done()
    );

    //============================================================
    // DMA Core Instance
    //============================================================
    dma_core u_dma (
        .clk(clk), .rstn(rstn),

        // Control from slave
        .src_addr(c_src_addr),
        .dst_addr(c_dst_addr),
        .len(c_len),
        .ctrl_start(c_ctrl_start),
        .status_done(c_status_done),

        // AXI memory interface
        .awready(m_awready),
        .awaddr(m_awaddr),
        .awvalid(m_awvalid),

        .wready(m_wready),
        .wdata(m_wdata),
        .wvalid(m_wvalid),

        .bvalid(m_bvalid),
        .bready(m_bready),

        .arready(m_arready),
        .araddr(m_araddr),
        .arvalid(m_arvalid),

        .rdata(m_rdata),
        .rvalid(m_rvalid),
        .rready(m_rready)
    );

    //============================================================
    // Memory Instance
    //============================================================
    axi_lite_mem #(
        .ADDR_WIDTH(32),
        .DATA_WIDTH(32),
        .MEM_DEPTH(256)
    ) u_mem (
        .clk(clk), .rstn(rstn),

        .awvalid(m_awvalid), .awaddr(m_awaddr), .awready(m_awready),
        .wvalid(m_wvalid),   .wdata(m_wdata),   .wready(m_wready),
        .bvalid(m_bvalid),   .bready(m_bready),

        .arvalid(m_arvalid), .araddr(m_araddr), .arready(m_arready),
        .rvalid(m_rvalid),   .rdata(m_rdata),   .rready(m_rready)
    );

endmodule
