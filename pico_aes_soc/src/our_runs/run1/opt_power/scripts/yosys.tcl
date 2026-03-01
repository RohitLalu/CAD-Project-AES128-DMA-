# ========================================================================
# Yosys Synthesis Script (Tcl Mode) — Power Optimized
# ========================================================================
# Usage: yosys -c yosys.tcl
# ========================================================================

# 1. IMPORT YOSYS COMMANDS
yosys -import

# 2. SETUP PATHS
puts "\[INFO\] Setting up environment..."

set HOME         $env(HOME)
set PROJECT_ROOT "$HOME/CAD-Project-AES128-DMA-/pico_aes_soc/src"
set SKY130_ROOT  "$HOME/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af"

# Use multi-voltage libs for power optimization
# HVT cells leak less — prefer them for power reduction
set LIB_FILE     "$SKY130_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"
set LIB_HVT      "$SKY130_ROOT/sky130A/libs.ref/sky130_fd_sc_hvt/lib/sky130_fd_sc_hvt__tt_025C_1v80.lib"

set OUTPUT_DIR   "$PROJECT_ROOT/our_runs/run1/opt_power/outputs"
set REPORT_FILE  "$OUTPUT_DIR/synthesis_report.txt"

file mkdir $OUTPUT_DIR
set TMP_DIR "$PROJECT_ROOT/our_runs/run1/opt_power/tmp"
file mkdir $TMP_DIR
set env(TMPDIR) $TMP_DIR

# 3. READ RTL FILES
puts "\[INFO\] Reading RTL files..."

read_verilog -sv "$PROJECT_ROOT/aes_sbox.v"
read_verilog -sv "$PROJECT_ROOT/aes_inv_sbox.v"
read_verilog -sv "$PROJECT_ROOT/aes_key_mem.v"
read_verilog -sv "$PROJECT_ROOT/aes_encipher_block.v"
read_verilog -sv "$PROJECT_ROOT/aes_decipher_block.v"
read_verilog -sv "$PROJECT_ROOT/aes_core.v"
read_verilog -sv "$PROJECT_ROOT/aes.v"
read_verilog -sv "$PROJECT_ROOT/simpleuart.v"
read_verilog -sv "$PROJECT_ROOT/spimemio.v"
read_verilog -sv "$PROJECT_ROOT/picosoc_aes.v"
read_verilog -sv "$PROJECT_ROOT/picorv32.v"

# 4. PREPARE HIERARCHY
puts "\[INFO\] Checking hierarchy..."
hierarchy -check -top picosoc

# 5. SYNTHESIS — POWER OPTIMIZED
puts "\[INFO\] Running power-optimized synthesis..."

yosys proc
opt -full

# FSM: one-hot encoding for power
# One-hot has fewer bit transitions per state change → less dynamic power
# Binary encoding (used in area opt) toggles more bits per transition
fsm -encoding one-hot
opt -full

memory -nomap
memory_map
opt -full

techmap
opt -full

flatten
opt -full

# share reduces switching activity by merging redundant logic
share
opt -full
peepopt
opt_clean
opt -full

# 6. MAPPING TO SKY130
puts "\[INFO\] Mapping to Sky130 (power mode)..."

dfflibmap -liberty $LIB_FILE

# ABC power-aware mapping:
# No -D flag — let ABC optimize for area/power balance
# Smaller cells switch faster but draw less current per switch
# abc will prefer lower-drive cells which have less capacitance
abc -liberty $LIB_FILE -nocleanup -showtmp

opt_clean -purge
clean

# 7. WRITE OUTPUTS
puts "\[INFO\] Writing outputs..."

write_verilog -noattr -noexpr -nohex -nodec "$OUTPUT_DIR/netlist.v"

# 8. FINAL REPORT
tee -o $REPORT_FILE stat -liberty $LIB_FILE

puts "\[SUCCESS\] Power-Optimized Synthesis Done!"
puts "\[INFO\]    Netlist : $OUTPUT_DIR/netlist.v"
puts "\[INFO\]    Report  : $REPORT_FILE"