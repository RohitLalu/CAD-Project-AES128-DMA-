// ========================================================================
// SRAM Wrapper - Adapts OpenRAM SRAM to picosoc_mem Interface
// ========================================================================
// This wrapper converts between:
//   - picosoc_mem interface (original)
//   - OpenRAM SRAM interface (generated)
// ========================================================================

module picosoc_mem #(
    parameter integer WORDS = 256
) (
    input clk,
    input [3:0] wen,           // Write enable (byte-wise, active high)
    input [21:0] addr,         // Address (only lower 8 bits used for 256 words)
    input [31:0] wdata,        // Write data
    output [31:0] rdata        // Read data
);

    // ====================================================================
    // Signal Conversion for OpenRAM SRAM
    // ====================================================================
    
    // Chip select: always enabled in picosoc_mem
    wire csb = 1'b0;  // Active low, so 0 = enabled
    
    // Write enable: active when any byte is being written
    // OpenRAM uses active-low web, picosoc uses active-high wen
    wire web = ~(|wen);  // Active low: 0 = write, 1 = read
    
    // Write mask: Direct mapping (OpenRAM wmask is active high like wen)
    wire [3:0] wmask = wen;
    
    // Address: Use lower 8 bits for 256 words
    wire [7:0] sram_addr = addr[7:0];
    
    // ====================================================================
    // Instantiate OpenRAM SRAM
    // ====================================================================
    // NOTE: Replace module name with actual generated name from OpenRAM
    // Typically: sram_1kbyte_1rw1r_32x256_8
    
    sram_1kbyte_1rw1r_32x256_8 sram_inst (
        // Port 0: Read/Write
        .clk0(clk),
        .csb0(csb),           // Chip select (active low, always enabled)
        .web0(web),           // Write enable (active low)
        .wmask0(wmask),       // Write mask (4 bits for 4 bytes)
        .addr0(sram_addr),    // Address (8 bits for 256 words)
        .din0(wdata),         // Data in
        .dout0(rdata)         // Data out
    );

endmodule

// ========================================================================
// Alternative: If OpenRAM generates different port names
// ========================================================================
// Check the generated sram.v file for actual port names and update above
// Common variations:
//   - clk/CLK, csb/CSB, web/WEB, wmask/WMASK
//   - addr/ADDR, din/DIN, dout/DOUT
// ========================================================================