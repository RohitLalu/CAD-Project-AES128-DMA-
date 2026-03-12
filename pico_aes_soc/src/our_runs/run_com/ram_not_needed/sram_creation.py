
# ── Technology ────────────────────────────────────────────────────────────────
tech_name        = "sky130"
process_corners  = ["TT"]          # Typical-Typical corner
supply_voltages  = [1.8]           # Sky130 nominal VDD
temperatures     = [25]            # Room temperature

# ── Memory geometry ───────────────────────────────────────────────────────────
word_size    = 32    # bits per word  (matches picosoc 32-bit data bus)
num_words    = 256   # depth          (matches MEM_WORDS = 256 in picosoc_aes.v)
num_banks    = 1     # single bank

# words_per_row: 8 gives a more square aspect ratio for 256×32;
# 4 is also fine – choose 8 for better area at the cost of slightly wider mux.
words_per_row = 8

# ── Port configuration ────────────────────────────────────────────────────────
# One combined read/write port (port 0).
# picosoc drives a single address/data bus – no separate read port needed.
num_rw_ports = 1
num_r_ports  = 0
num_w_ports  = 0

# ── Write mask ────────────────────────────────────────────────────────────────
# write_size = 8  →  wmask0[3:0], one bit per byte lane.
# Directly driven by picosoc's wen[3:0] in the wrapper.
write_size = 8

# ── Output names / paths ──────────────────────────────────────────────────────
output_name = "sram_1kbyte_1rw1r_32x256_8"
output_path = "sram_macro_output/"

# ── Netlist / layout options ──────────────────────────────────────────────────
netlist_only    = True   # generate full GDS layout
route_supplies  = True    # route VDD/VSS straps inside the macro

# ── Characterisation ──────────────────────────────────────────────────────────
analytical_delay = True   # use analytical (fast) delay model

# ── Verification ──────────────────────────────────────────────────────────────
# Set both to True for a production-quality run.
# Disable during initial bring-up to save time.
check_lvsdrc  = False
inline_lvsdrc = False

# ── Verbosity ─────────────────────────────────────────────────────────────────
verbose_level = 1
