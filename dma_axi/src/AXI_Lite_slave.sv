`timescale 1ns / 1ps
//============================================================
// Module: axi_lite_slave
// Description:
//   Simple AXI4-Lite slave interface to control a DMA engine.
//   Provides memory-mapped registers for source address,
//   destination address, transfer length, and control/status.
//
// Register Map (offsets in bytes):
//   0x00 : SRC_ADDR     (RW)  Source start address
//   0x04 : DST_ADDR     (RW)  Destination start address
//   0x08 : LEN          (RW)  Transfer length (words)
//   0x0C : CTRL_START   (RW)  [0] = Start trigger
//   0x10 : STATUS_DONE  (RO)  [0] = Transfer complete
//
// Notes:
//   - Uses single-cycle ready/valid handshakes.
//   - Returns 0xDEAD_BEEF on invalid read addresses.
//   - `o_ctrl_start` is level-based (no auto-clear).
//
// Author: Daniel
//============================================================

module axi_lite_slave (
    input  logic        clk,
    input  logic        rstn,

    // AXI4-Lite Write Address Channel
    input  logic        awvalid,
    input  logic [31:0] awaddr,
    output logic        awready,

    // AXI4-Lite Write Data Channel
    input  logic        wvalid,
    input  logic [31:0] wdata,
    output logic        wready,

    // AXI4-Lite Write Response Channel
    input  logic        bready,
    output logic        bvalid,

    // AXI4-Lite Read Address Channel
    input  logic        arvalid,
    input  logic [31:0] araddr,
    output logic        arready,

    // AXI4-Lite Read Data Channel
    input  logic        rready,
    output logic        rvalid,
    output logic [31:0] rdata,

    // Outputs to DMA engine
    output logic [31:0] o_src_addr,
    output logic [31:0] o_dst_addr,
    output logic [31:0] o_len,
    output logic        o_ctrl_start,

    // Input from DMA engine
    input  logic        i_status_done,
    output logic        o_status_done
);

    //============================================================
    // Internal Control Registers
    //============================================================
    logic [31:0] src_addr;     // Register 0x00
    logic [31:0] dst_addr;     // Register 0x04
    logic [31:0] len;          // Register 0x08
    logic        ctrl_start;   // Register 0x0C

    // Latched handshake signals
    logic [31:0] awaddr_reg;
    logic [31:0] wdata_reg;
    logic [31:0] araddr_reg;
    logic        aw_handshake, w_handshake;

    //============================================================
    // Write Address Channel
    //============================================================
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            awready      <= 0;
            awaddr_reg   <= 0;
            aw_handshake <= 0;
        end else begin
            if (!awready && awvalid) begin
                awready      <= 1;
                awaddr_reg   <= awaddr;
                aw_handshake <= 1;
            end else begin
                awready <= 0; // pulse for 1 cycle
                if (aw_handshake && w_handshake)
                    aw_handshake <= 0;
            end
        end
    end

    //============================================================
    // Write Data Channel
    //============================================================
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            wready      <= 0;
            wdata_reg   <= 0;
            w_handshake <= 0;
        end else begin
            if (!wready && wvalid) begin
                wready      <= 1;
                wdata_reg   <= wdata;
                w_handshake <= 1;
            end else begin
                wready <= 0; // pulse for 1 cycle
                if (aw_handshake && w_handshake)
                    w_handshake <= 0;
            end
        end
    end

    //============================================================
    // Register Write (AW + W handshake complete)
    //============================================================
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            src_addr   <= 0;
            dst_addr   <= 0;
            len        <= 0;
            ctrl_start <= 0;
        end else begin
            if (aw_handshake && w_handshake) begin
                case (awaddr_reg[7:0])
                    8'h00: src_addr   <= wdata_reg;
                    8'h04: dst_addr   <= wdata_reg;
                    8'h08: len        <= wdata_reg;
                    8'h0C: ctrl_start <= wdata_reg[0];
                    default: ; // ignore invalid writes
                endcase
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
            if (aw_handshake && w_handshake)
                bvalid <= 1;        // issue response
            else if (bvalid && bready)
                bvalid <= 0;        // clear after handshake
        end
    end

    //============================================================
    // Read Address Channel
    //============================================================
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            arready    <= 0;
            araddr_reg <= 0;
        end else begin
            if (!arready && arvalid) begin
                arready    <= 1;
                araddr_reg <= araddr;
            end else begin
                arready <= 0; // pulse for 1 cycle
            end
        end
    end

    //============================================================
    // Read Data Channel
    //============================================================
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            rvalid <= 0;
            rdata  <= 0;
        end else begin
            if (arvalid && arready) begin
                rvalid <= 1;
                case (araddr_reg[7:0])
                    8'h00: rdata <= src_addr;
                    8'h04: rdata <= dst_addr;
                    8'h08: rdata <= len;
                    8'h0C: rdata <= {31'b0, ctrl_start};
                    8'h10: rdata <= {31'b0, i_status_done};
                    default: rdata <= 32'hDEAD_BEEF; // invalid address
                endcase
            end else if (rvalid && rready) begin
                rvalid <= 0;
            end
        end
    end

    //============================================================
    // Outputs to DMA
    //============================================================
    assign o_src_addr    = src_addr;
    assign o_dst_addr    = dst_addr;
    assign o_len         = len;
    assign o_ctrl_start  = ctrl_start;
    assign o_status_done = i_status_done;

endmodule
