# ========================================================================
# Yosys Synthesis Script (Tcl Mode)
# ========================================================================
# Usage: yosys -c yosys.tcl
# ========================================================================

# 1. IMPORT YOSYS COMMANDS
# This is required when running in Tcl mode (-c)
yosys -import

# 2. SETUP PATHS
puts "\[INFO\] Setting up environment..."

# Define your paths using Tcl variables for cleaner code
set HOME $env(HOME)
set PROJECT_ROOT "$HOME/CAD-Project-AES128-DMA-/pico_aes_soc/src"
set SKY130_ROOT  "$HOME/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af"

# Standard Cell Library (Timing info for synthesis)
set LIB_FILE "$SKY130_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"

# 3. READ RTL FILES
puts "\[INFO\] Reading RTL files..."

# Read AES Modules
read_verilog -sv "$PROJECT_ROOT/aes_sbox.v"
read_verilog -sv "$PROJECT_ROOT/aes_inv_sbox.v"
read_verilog -sv "$PROJECT_ROOT/aes_key_mem.v"
read_verilog -sv "$PROJECT_ROOT/aes_encipher_block.v"
read_verilog -sv "$PROJECT_ROOT/aes_decipher_block.v"
read_verilog -sv "$PROJECT_ROOT/aes_core.v"
read_verilog -sv "$PROJECT_ROOT/aes.v"

# Read Peripherals
read_verilog -sv "$PROJECT_ROOT/simpleuart.v"
read_verilog -sv "$PROJECT_ROOT/spimemio.v"

# Read SoC Wrapper
read_verilog -sv "$PROJECT_ROOT/picosoc_aes.v"

# Read CPU Core
read_verilog -sv "$PROJECT_ROOT/picorv32.v"

# NOTE: We do NOT read the SRAM behavioral model here.
# We want Yosys to see the SRAM as a Blackbox so we can place the real Macro in OpenROAD.

# 4. PREPARE HIERARCHY
puts "\[INFO\] Checking hierarchy..."
hierarchy -check -top picosoc

# 5. SYNTHESIS STEPS
puts "\[INFO\] Running synthesis..."

# Convert high-level logic
yosys proc
opt

# Handle Memories
# -nomap: Don't turn the large SRAM into flip-flops (keep it as a memory block)
memory -nomap
memory_map
opt

# Technology Mapping (Generic)
techmap
opt

# 6. MAPPING TO SKY130
puts "\[INFO\] Mapping to Sky130..."

# Map Flip-Flops
dfflibmap -liberty $LIB_FILE

# Map Logic Gates
abc -liberty $LIB_FILE

# Clean up
clean
opt_clean

# 7. WRITE OUTPUTS
puts "\[INFO\] Writing outputs..."

# Write the synthesized netlist
write_verilog -noattr -noexpr -nohex -nodec picosoc_aes_sram.v

# Print Area Statistics
stat -liberty $LIB_FILE

puts "\[SUCCESS\] Synthesis Done! Output: picosoc_aes_sram.v"
