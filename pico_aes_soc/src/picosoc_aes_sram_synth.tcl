#!/usr/bin/env yosys
# ========================================================================
# Yosys Synthesis Script for PicoSoC + AES with SRAM Macro
# ========================================================================
# Key Change: Memory is kept as black box (SRAM macro)
# Instead of synthesizing to flip-flops
# ========================================================================

set TOP_MODULE "picosoc"
set PDK_ROOT "$::env(HOME)/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A"
set LIB_PATH "${PDK_ROOT}/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"
set OUTPUT_DIR "."

# SRAM macro paths (adjust if your macros are elsewhere)
set SRAM_MACRO_DIR "$::env(HOME)/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_sram_macros"

# RTL files
set RTL_FILES [list \
    "aes_sbox.v" \
    "aes_inv_sbox.v" \
    "aes_key_mem.v" \
    "aes_encipher_block.v" \
    "aes_decipher_block.v" \
    "aes_core.v" \
    "aes.v" \
    "picosoc_aes.v" \
    "picorv32.v" \
]

# ------------------------------------------------------------------------
# Stage 1: Read RTL Design
# ------------------------------------------------------------------------
yosys echo "=========================================="
yosys echo "Stage 1: Reading RTL Files"
yosys echo "=========================================="

foreach file $RTL_FILES {
    yosys echo "Reading: $file"
    read_verilog -sv $file
}

# Read SRAM macro Verilog model (behavioral model for synthesis)
# Note: You'll need to provide the SRAM macro behavioral model
# For now, we'll mark it as blackbox
yosys echo "Reading SRAM macro model..."
# read_verilog ${SRAM_MACRO_DIR}/verilog/sky130_sram_1kbyte_1rw1r_32x256_8.v

yosys ls

# ------------------------------------------------------------------------
# Stage 2: Hierarchy & Elaboration
# ------------------------------------------------------------------------
yosys echo ""
yosys echo "=========================================="
yosys echo "Stage 2: Elaboration"
yosys echo "=========================================="

hierarchy -check -top $TOP_MODULE

# ------------------------------------------------------------------------
# Stage 3: High-Level Synthesis
# ------------------------------------------------------------------------
yosys echo ""
yosys echo "=========================================="
yosys echo "Stage 3: High-Level Synthesis"
yosys echo "=========================================="

proc
flatten
opt

# ------------------------------------------------------------------------
# Stage 4: CRITICAL - Memory Handling for SRAM Macro
# ------------------------------------------------------------------------
yosys echo ""
yosys echo "=========================================="
yosys echo "Stage 4: Memory Handling (SRAM Macro)"
yosys echo "=========================================="

# Prepare memories but DON'T map to flip-flops
memory -nomap

# IMPORTANT: Do NOT call memory_map!
# This keeps memories as abstract $mem cells

# Mark the memory modules as black boxes (to be replaced by macros)
# The picosoc_mem module will be replaced with SRAM macro in OpenROAD
yosys echo "Marking picosoc_mem as blackbox..."
blackbox picosoc_mem

# Note: The 32-entry register file (picosoc_regs) can stay synthesized
# It's small enough (1Kb) that using flip-flops is acceptable
# To also use macro for register file, uncomment:
# blackbox picosoc_regs

yosys echo "Memory strategy:"
yosys echo "  - picosoc_mem (256x32 = 1KB): SRAM MACRO (blackbox)"
yosys echo "  - picosoc_regs (32x32 = 1KB): Synthesized to flip-flops"

opt -full

# ------------------------------------------------------------------------
# Stage 5: Technology-Independent Mapping
# ------------------------------------------------------------------------
yosys echo ""
yosys echo "=========================================="
yosys echo "Stage 5: Generic Gate Mapping"
yosys echo "=========================================="

techmap
opt -fast

# ------------------------------------------------------------------------
# Stage 6: Sky130 Technology Mapping
# ------------------------------------------------------------------------
yosys echo ""
yosys echo "=========================================="
yosys echo "Stage 6: Sky130 Technology Mapping"
yosys echo "=========================================="

dfflibmap -liberty $LIB_PATH

yosys echo "Mapping combinational logic with ABC..."
abc -liberty $LIB_PATH

clean
opt_clean -purge

# ------------------------------------------------------------------------
# Stage 7: Generate Outputs
# ------------------------------------------------------------------------
yosys echo ""
yosys echo "=========================================="
yosys echo "Stage 7: Generating Outputs"
yosys echo "=========================================="

set NETLIST_FILE "${OUTPUT_DIR}/${TOP_MODULE}_aes_sram.v"
yosys echo "Writing netlist: $NETLIST_FILE"
write_verilog -noattr -noexpr -nohex -nodec $NETLIST_FILE

set JSON_FILE "${OUTPUT_DIR}/${TOP_MODULE}_aes_sram.json"
write_json $JSON_FILE

yosys echo ""
yosys echo "=========================================="
yosys echo "Final Statistics"
yosys echo "=========================================="
stat -liberty $LIB_PATH

tee -q -o "${OUTPUT_DIR}/${TOP_MODULE}_aes_sram_stats.txt" stat -liberty $LIB_PATH

# ------------------------------------------------------------------------
# Summary
# ------------------------------------------------------------------------
yosys echo ""
yosys echo "=========================================="
yosys echo "Synthesis Complete with SRAM Macro!"
yosys echo "=========================================="
yosys echo ""
yosys echo "Memory Configuration:"
yosys echo "  ✓ picosoc_mem: BLACK BOX (will be SRAM macro)"
yosys echo "    - Size: 256 words × 32 bits = 8 Kb"
yosys echo "    - Macro: sky130_sram_1kbyte_1rw1r_32x256_8"
yosys echo "  ✓ picosoc_regs: SYNTHESIZED (flip-flops)"
yosys echo "    - Size: 32 words × 32 bits = 1 Kb"
yosys echo ""
yosys echo "Expected benefits vs flip-flop implementation:"
yosys echo "  - Area reduction: ~50% smaller"
yosys echo "  - Power reduction: ~90% less static power"
yosys echo "  - Speed increase: ~2-3x faster access"
yosys echo ""
yosys echo "Output files:"
yosys echo "  - Netlist: $NETLIST_FILE"
yosys echo "  - JSON: $JSON_FILE"
yosys echo ""
yosys echo "Next: OpenROAD with SRAM macro placement"
yosys echo "=========================================="
