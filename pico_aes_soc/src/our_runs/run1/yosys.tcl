# #!/usr/bin/env yosys

# set TOP_MODULE "picosoc_aes"
# set PDK_ROOT "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A"
# set LIB_PATH "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"
# set OUTPUT_DIR "."

# # SRAM macro paths (adjust if your macros are elsewhere)
# set SRAM_MACRO_DIR "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_sram_macros"

# #RTL Files reading
# read_verilog -sv "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/picosoc_aes.v"
# read_verilog -sv "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/picorv32.v"
# read_verilog -sv "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/simpleuart.v"
# read_verilog -sv "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/spimemio.v"
# read_verilog -sv "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/aes_sbox.v"
# read_verilog -sv "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/aes_inv_sbox.v"
# read_verilog -sv "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/aes_key_mem.v"
# read_verilog -sv "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/aes_encipher_block.v"
# read_verilog -sv "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/aes_decipher_block.v"
# read_verilog -sv "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/aes_core.v"

# #yosys echo "Reading SRAM macro model..."
# #read_verilog ${SRAM_MACRO_DIR}/verilog/sky130_sram_1kbyte_1rw1r_32x256_8.v
# read_verilog "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_sram_macros/verilog/sky130_sram_1kbyte_1rw1r_32x256_8.v"


# yosys ls

# #Hierarchy 

# hierarchy -check -top picosoc_aes

# # Stage 3: High-Level Synthesis

# proc
# flatten
# opt

# # Stage 4: CRITICAL - Memory Handling for SRAM Macro
# # Prepare memories but DON'T map to flip-flops
# memory -nomap

# # IMPORTANT: Do NOT call memory_map!
# # This keeps memories as abstract $mem cells

# # Mark the memory modules as black boxes (to be replaced by macros)
# # The picosoc_mem module will be replaced with SRAM macro in OpenROAD
# yosys echo "Marking picosoc_mem as blackbox..."
# blackbox picosoc_mem

# # Note: The 32-entry register file (picosoc_regs) can stay synthesized
# # It's small enough (1Kb) that using flip-flops is acceptable
# # To also use macro for register file, uncomment:
# # blackbox picosoc_regs

# yosys echo "Memory strategy:"
# yosys echo "  - picosoc_mem (256x32 = 1KB): SRAM MACRO (blackbox)"
# yosys echo "  - picosoc_regs (32x32 = 1KB): Synthesized to flip-flops"

# opt -full

# # Stage 5: Technology-Independent Mapping
# techmap
# opt -fast

# # Stage 6: Sky130 Technology Mapping
# dfflibmap -liberty $LIB_PATH

# yosys echo "Mapping combinational logic with ABC..."
# abc -liberty $LIB_PATH

# clean
# opt_clean -purge

# # Stage 7: Generate Outputs
# set NETLIST_FILE "${OUTPUT_DIR}/${TOP_MODULE}_sram_synthesised.v"
# yosys echo "Writing netlist: $NETLIST_FILE"
# write_verilog -noattr -noexpr -nohex -nodec $NETLIST_FILE

# set JSON_FILE "${OUTPUT_DIR}/${TOP_MODULE}_sram.json"
# write_json $JSON_FILE

# stat -liberty $LIB_PATH

# tee -q -o "${OUTPUT_DIR}/${TOP_MODULE}_sram_stats.txt" stat -liberty $LIB_PATH

# yosys echo ""
# yosys echo "=========================================="
# yosys echo "Synthesis Complete with SRAM Macro!"
# yosys echo "=========================================="
# yosys echo ""
# yosys echo "Memory Configuration:"
# yosys echo "  ✓ picosoc_mem: BLACK BOX (will be SRAM macro)"
# yosys echo "    - Size: 256 words × 32 bits = 8 Kb"
# yosys echo "    - Macro: sky130_sram_1kbyte_1rw1r_32x256_8"
# yosys echo "  ✓ picosoc_regs: SYNTHESIZED (flip-flops)"
# yosys echo "    - Size: 32 words × 32 bits = 1 Kb"
# yosys echo ""
# yosys echo "Output files:"
# yosys echo "  - Netlist: $NETLIST_FILE"
# yosys echo "  - JSON: $JSON_FILE"

#!/usr/bin/env yosys
# ========================================================================
# Corrected Yosys Synthesis Script for PicoSoC + AES with SRAM
# ========================================================================
# Key fixes:
# 1. Top module is "picosoc" not "picosoc_aes"
# 2. Read aes.v (wrapper module)
# 3. Proper Tcl variable syntax
# 4. Correct file reading order
# ========================================================================

# Yosys doesn't support "set" in scripts - use Tcl directly
# Variables must be in ${} format when used

# ========================================================================
# Read RTL Files (ORDER MATTERS!)
# ========================================================================

# Read AES modules first
read_verilog -sv "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/aes_sbox.v"
read_verilog -sv "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/aes_inv_sbox.v"
read_verilog -sv "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/aes_key_mem.v"
read_verilog -sv "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/aes_encipher_block.v"
read_verilog -sv "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/aes_decipher_block.v"
read_verilog -sv "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/aes_core.v"
read_verilog -sv "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/aes.v"

# Read peripheral modules
read_verilog -sv "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/simpleuart.v"
read_verilog -sv "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/spimemio.v"

# Read SoC wrapper (MUST be before picorv32.v due to macro definitions!)
read_verilog -sv "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/picosoc_aes.v"

# Read CPU core LAST
read_verilog -sv "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/picorv32.v"

# Read SRAM macro behavioral model
read_verilog "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_sram_macros/verilog/sky130_sram_1kbyte_1rw1r_32x256_8.v"

# ========================================================================
# Check what modules were loaded
# ========================================================================
ls

# ========================================================================
# Set Hierarchy (CRITICAL: Module name is "picosoc" not "picosoc_aes"!)
# ========================================================================
hierarchy -check -top picosoc

# ========================================================================
# High-Level Synthesis
# ========================================================================
proc
flatten
opt

# ========================================================================
# Memory Handling for SRAM Macro
# ========================================================================

# Prepare memories but DON'T map to flip-flops
memory -nomap
memory_map
# Mark picosoc_mem as blackbox (will be SRAM macro in OpenROAD)
#blackbox picosoc_mem

# picosoc_regs stays synthesized to flip-flops (it's small)

opt -full

# ========================================================================
# Technology-Independent Mapping
# ========================================================================
techmap
opt -fast

# ========================================================================
# Sky130 Technology Mapping
# ========================================================================

# Map flip-flops
dfflibmap -liberty "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"

# Map combinational logic
abc -liberty "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"

# Cleanup
clean
opt_clean -purge

# ========================================================================
# Generate Outputs
# ========================================================================

# Write Verilog netlist
write_verilog -noattr -noexpr -nohex -nodec picosoc_aes_sram.v

# Write JSON
write_json picosoc_aes_sram.json

# Statistics
stat -liberty "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"

# Save stats to file
tee -o picosoc_aes_sram_stats.txt stat -liberty "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"

# ========================================================================
# Summary
# ========================================================================
log ""
log "========================================"
log "Synthesis Complete!"
log "========================================"
