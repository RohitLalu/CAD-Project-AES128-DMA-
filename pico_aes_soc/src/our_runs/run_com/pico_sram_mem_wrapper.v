// // =============================================================================
// // picosoc_mem_sram.v
// // SRAM Wrapper: Bridges picosoc_mem → sky130_sram_1kbyte_1rw1r_32x256_8
// //
// // Source macro: SkyWater sky130 PDK pre-built SRAM
// //   $PDK_ROOT/sky130A/libs.ref/sky130_sram_macros/
// //   NOT OpenRAM-generated — use the PDK files directly.
// //
// // Macro ports:
// //   Port 0 (RW): clk0, csb0, web0, wmask0[3:0], addr0[7:0], din0[31:0], dout0[31:0]
// //   Port 1 (R) : clk1, csb1, addr1[7:0], dout1[31:0]
// //
// // picosoc drives a single RW bus → Port 0 is used, Port 1 is tied off.
// //
// // picosoc_mem interface (picosoc_aes.v):
// //   clk, wen[3:0], addr[21:0], wdata[31:0], rdata[31:0]
// //
// // Signal mapping:
// //   clk0   ← clk
// //   csb0   ← 1'b0          always selected (single master, no power gating)
// //   web0   ← ~(|wen)       active-LOW: 0=write, 1=read
// //   wmask0 ← wen[3:0]      byte-lane enables passed through
// //   addr0  ← addr[7:0]     lower 8 bits of 22-bit PicoRV32 word address
// //   din0   ← wdata
// //   rdata  ← dout0
// //
// //   Port 1 tie-off:
// //   clk1   ← clk           (clock must be driven even when port is unused)
// //   csb1   ← 1'b1          deselect port 1 permanently (active-LOW CS)
// //   addr1  ← 8'b0          don't-care, port is deselected
// // =============================================================================

// `ifndef PICOSOC_MEM
// `define PICOSOC_MEM picosoc_mem
// `endif

// module picosoc_mem #(
//     parameter integer WORDS = 256   // Must be 256 — fixed by macro geometry
// ) (
//     input              clk,
//     input  [3:0]       wen,
//     input  [21:0]      addr,
//     input  [31:0]      wdata,
//     output [31:0]      rdata
// );

//     // ── Port 0 control signals ────────────────────────────────────────────────

//     // csb0: permanently asserted so reads are available every cycle
//     wire        csb0   = 1'b0;

//     // web0: active-LOW write enable — driven LOW only when wen is non-zero
//     wire        web0   = ~(|wen);

//     // wmask0: byte-lane write mask, one bit per byte (active-HIGH)
//     wire [3:0]  wmask0 = wen;

//     // addr0: 256-deep → 8-bit address; take lower bits of PicoRV32 word addr
//     wire [7:0]  addr0  = addr[7:0];

//     // ── Port 1 tie-off ────────────────────────────────────────────────────────
//     // csb1 = 1'b1 permanently deselects port 1.
//     // addr1 must still be driven to avoid X-propagation in simulation.
//     wire        csb1   = 1'b1;
//     wire [7:0]  addr1  = 8'b0;

//     // ── Macro instantiation ───────────────────────────────────────────────────
//     sky130_sram_1kbyte_1rw1r_32x256_8 sram_macro (
//         // Port 0 — RW, used by PicoRV32
//         .clk0   (clk),
//         .csb0   (csb0),
//         .web0   (web0),
//         .wmask0 (wmask0),
//         .addr0  (addr0),
//         .din0   (wdata),
//         .dout0  (rdata),

//         // Port 1 — R-only, permanently deselected
//         .clk1   (clk),
//         .csb1   (csb1),
//         .addr1  (addr1),
//         .dout1  ()          // output left unconnected
//     );

// endmodule