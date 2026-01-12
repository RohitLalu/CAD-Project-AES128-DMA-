`timescale 1ns / 1ps
//============================================================
// Module: axi_lite_mem
// Description:
//   AXI4-Lite compatible memory block.
//   Provides a memory-mapped read/write interface with
//   single-cycle ready/valid handshakes.
//
// Parameters:
//   ADDR_WIDTH - Width of AXI address bus (default 32)
//   DATA_WIDTH - Width of AXI data bus (default 32)
//   MEM_DEPTH  - Number of words in memory (default 256)
//
// Notes:
//   - Memory array is simple reg array (for simulation or FPGA).
//============================================================

module axi_lite_mem #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter MEM_DEPTH  = 256
)(
    input  logic                  clk,
    input  logic                  rstn,

    // AXI4-Lite Write Address Channel
    input  logic                  awvalid,
    input  logic [ADDR_WIDTH-1:0] awaddr,
    output logic                  awready,

    // AXI4-Lite Write Data Channel
    input  logic                  wvalid,
    input  logic [DATA_WIDTH-1:0] wdata,
    output logic                  wready,

    // AXI4-Lite Write Response Channel
    output logic                  bvalid,
    input  logic                  bready,

    // AXI4-Lite Read Address Channel
    input  logic                  arvalid,
    input  logic [ADDR_WIDTH-1:0] araddr,
    output logic                  arready,

    // AXI4-Lite Read Data Channel
    output logic                  rvalid,
    output logic [DATA_WIDTH-1:0] rdata,
    input  logic                  rready
);

    //============================================================
    // Internal Memory Array
    //============================================================
    logic [DATA_WIDTH-1:0] mem [0:MEM_DEPTH-1];
    logic [ADDR_WIDTH-1:0] awaddr_reg, araddr_reg;

    //============================================================
    // Write Address Channel
    //============================================================
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            awready    <= 0;
            awaddr_reg <= '0;
        end else begin
            if (!awready && awvalid) begin
                awready    <= 1;
                awaddr_reg <= awaddr;
            end else begin
                awready <= 0; // pulse 1 cycle
            end
        end
    end

    //============================================================
    // Write Data Channel
    //============================================================
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            wready <= 0;
        end else begin
            if (!wready && wvalid) begin
                wready <= 1;
                mem[awaddr] <= wdata; 
            end else begin
                wready <= 0; // pulse 1 cycle
            end
        end
    end

    //============================================================
    // Write Response Channel
    //============================================================
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            bvalid <= 0;
        end else begin
            if (wvalid && wready)
                bvalid <= 1;       // issue response
            else if (bvalid && bready)
                bvalid <= 0;       // clear after handshake
        end
    end

    //============================================================
    // Read Address Channel
    //============================================================
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            arready    <= 0;
            araddr_reg <= '0;
        end else begin
            if (!arready && arvalid) begin
                arready    <= 1;
                araddr_reg <= araddr;
            end else begin
                arready <= 0; // pulse 1 cycle
            end
        end
    end

    //============================================================
    // Read Data Channel
    //============================================================
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            rvalid <= 0;
            rdata  <= '0;
        end else begin
            if (arvalid && arready) begin
                rvalid <= 1;
                rdata  <= mem[araddr]; 
            end else if (rvalid && rready) begin
                rvalid <= 0;
            end
        end
    end

endmodule
