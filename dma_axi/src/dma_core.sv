`timescale 1ns / 1ps
//============================================================
// Module: dma_core
// Description:
//   Simple DMA controller core with AXI4-Lite style handshake.
//   Transfers data from a source address to a destination
//   address over a memory-mapped interface.
//============================================================

module dma_core (
    input  logic        clk,
    input  logic        rstn,

    // Control/Status from AXI-Lite slave
    input  logic [31:0] src_addr,     // Source start address
    input  logic [31:0] dst_addr,     // Destination start address
    input  logic [31:0] len,          // Transfer length (words)
    input  logic        ctrl_start,   // Start trigger
    output logic        status_done,  // Done flag

    // Memory interface (AXI-like signals)
    // Write address channel
    input  logic        awready,
    output logic [31:0] awaddr,
    output logic        awvalid,

    // Write data channel
    input  logic        wready,
    output logic [31:0] wdata,
    output logic        wvalid,

    // Write response channel
    input  logic        bvalid,
    output logic        bready,

    // Read address channel
    input  logic        arready,
    output logic [31:0] araddr,
    output logic        arvalid,

    // Read data channel
    input  logic [31:0] rdata,
    input  logic        rvalid,
    output logic        rready
);

    //============================================================
    // State Machine Definition
    //============================================================
    typedef enum logic [2:0] {
        IDLE,        // Wait for start
        READ_ADDR,   // Send read address
        READ_DATA,   // Capture read data
        WRITE_ADDR,  // Send write address
        WRITE_DATA,  // Send write data
        WRITE_RESP,  // Wait for write response
        DONE         // Transfer complete
    } state_t;

    state_t state, next_state;

    //============================================================
    // Internal registers
    //============================================================
    logic [31:0] src_ptr;       // Current source pointer
    logic [31:0] dst_ptr;       // Current destination pointer
    logic [31:0] remaining_len; // Remaining words to transfer
    logic [31:0] data_buffer;   // Temporary buffer for read data

    //============================================================
    // Handshake Signals
    //============================================================
    logic aw_handshake, w_handshake, b_handshake;
    logic ar_handshake, r_handshake;

    assign aw_handshake = awvalid && awready;
    assign w_handshake  = wvalid  && wready;
    assign b_handshake  = bvalid  && bready;

    assign ar_handshake = arvalid && arready;
    assign r_handshake  = rvalid  && rready;

    //============================================================
    // State Register
    //============================================================
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn)
            state <= IDLE;
        else
            state <= next_state;
    end

   //============================================================
    // Next-State Logic
    //============================================================
    always_comb begin
        next_state = state;
        case (state)
            IDLE:       if (ctrl_start)   next_state = READ_ADDR;
            READ_ADDR:  if (ar_handshake) next_state = READ_DATA;
            READ_DATA:  if (r_handshake)  next_state = WRITE_ADDR;
            WRITE_ADDR: if (aw_handshake) next_state = WRITE_DATA;
            WRITE_DATA: if (w_handshake)  next_state = WRITE_RESP;
            WRITE_RESP: if (b_handshake) begin
                            if (remaining_len > 0)   // still more words
                                next_state = READ_ADDR;
                            else
                                next_state = DONE;
                        end
            DONE:       next_state = DONE; // or back to IDLE on next ctrl_start
        endcase
    end

    //============================================================
    // Output Logic (driven by state)
    //============================================================

    // Read address channel
    assign arvalid = (state == READ_ADDR);
    assign araddr  = src_ptr;  // stable while arvalid=1

    // Read data channel
    assign rready  = (state == READ_DATA);

    // Write address channel
    assign awvalid = (state == WRITE_ADDR);
    assign awaddr  = dst_ptr;  // stable while awvalid=1

    // Write data channel
    assign wvalid  = (state == WRITE_DATA);
    assign wdata   = data_buffer;  // stable while wvalid=1

    // Write response channel
    assign bready  = (state == WRITE_RESP);

    // Done flag
    assign status_done = (state == DONE)&&(remaining_len == 0);

    //============================================================
    // Sequential Logic: Pointers, Buffers, Registers
    //============================================================
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            src_ptr       <= 32'b0;
            dst_ptr       <= 32'b0;
            remaining_len <= 32'b0;
            data_buffer   <= 32'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (ctrl_start) begin
                        src_ptr       <= src_addr;
                        dst_ptr       <= dst_addr;
                        remaining_len <= len;
                    end
                end

                READ_DATA: begin
                    if (r_handshake)
                        data_buffer <= rdata;
                end
                
                WRITE_DATA: begin
                    if (w_handshake) begin
                        src_ptr       <= src_ptr + 1;  // next word source,not yet implemented, for future updates
                        dst_ptr       <= dst_ptr + 1;  // next word dest,not yet implemented, for future updates
                        remaining_len <= remaining_len - 1;
                    end
                end
            endcase
        end
    end

endmodule
