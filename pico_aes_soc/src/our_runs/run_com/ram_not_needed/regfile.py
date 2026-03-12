# # =============================================================================
# # regfile_creation.py  –  OpenRAM configuration for PicoSoC register file
# #
# # Target SoC : picosoc_aes (PicoRV32 + AES-128 + DMA)
# # Technology : sky130 (SkyWater 130 nm)
# # Memory role: PicoRV32 integer register file  (x0 – x31)
# #
# # Interface contract (derived from picosoc_regs in picosoc_aes.v):
# #   – 32 × 32-bit words   (32 RISC-V integer registers)
# #   – 1 write port        (synchronous, full-word, no byte mask)
# #   – 2 independent read ports (ASYNCHRONOUS in behavioural model)
# #
# # Port assignment strategy:
# #   Port 0 (RW) → handles WRITES  (and provides read path for rdata1)
# #   Port 1 (R)  → dedicated read  (provides read path for rdata2)
# #
# #   OpenRAM produces synchronous registered outputs on both ports.
# #   The wrapper (picosoc_regs_sram.v) compensates for the 1-cycle read
# #   latency by registering the address inputs one cycle ahead, matching
# #   the read timing seen by picorv32.
# # =============================================================================

# # ── Technology ────────────────────────────────────────────────────────────────
# tech_name        = "sky130"
# process_corners  = ["TT"]
# supply_voltages  = [1.8]
# temperatures     = [25]

# # ── Memory geometry ───────────────────────────────────────────────────────────
# word_size    = 32    # bits per word
# num_words    = 32    # depth: 32 registers  (x0 – x31)
# num_banks    = 1

# # For 32 words, words_per_row=4 gives a reasonable aspect ratio.
# words_per_row = 4

# # ── Port configuration ────────────────────────────────────────────────────────
# # Port 0: combined read/write  – used for the write path + rdata1 read
# # Port 1: read-only            – used for rdata2 read
# num_rw_ports = 1   # port 0: clk0, csb0, web0, addr0, din0, dout0
# num_r_ports  = 1   # port 1: clk1, csb1, addr1, dout1
# num_w_ports  = 0

# # ── Write mask ────────────────────────────────────────────────────────────────
# # picosoc_regs writes full 32-bit words only (no byte-lane enables).
# # Setting write_size = word_size disables the wmask port entirely.
# write_size = 32    # full-word writes, no wmask pin generated

# # ── Output names / paths ──────────────────────────────────────────────────────
# output_name = "rf_32x32_1rw1r"
# output_path = "regfile_macro_output/"

# # ── Netlist / layout options ──────────────────────────────────────────────────
# netlist_only   = False
# route_supplies = True

# # ── Characterisation ──────────────────────────────────────────────────────────
# analytical_delay = True

# # ── Verification ──────────────────────────────────────────────────────────────
# check_lvsdrc  = True
# inline_lvsdrc = True

# # ── Verbosity ─────────────────────────────────────────────────────────────────
# verbose_level = 1

# # =============================================================================
# # Generated macro interface
# # =============================================================================
# #
# # Port 0 (RW) – write path + rdata1:
# #   input        clk0       rising-edge clock
# #   input        csb0       chip-select, active-LOW
# #   input        web0       write-enable, active-LOW (0=write, 1=read)
# #   input  [4:0] addr0      word address (0-31)
# #   input  [31:0] din0      write data
# #   output [31:0] dout0     read data (registered, next-cycle)
# #
# # Port 1 (R) – rdata2:
# #   input        clk1       rising-edge clock (tied to same clk)
# #   input        csb1       chip-select, active-LOW
# #   input  [4:0] addr1      word address (0-31)
# #   output [31:0] dout1     read data (registered, next-cycle)
# #
# # See picosoc_regs_sram.v for address pipelining that compensates
# # for the synchronous-vs-asynchronous read latency difference.
# # =============================================================================