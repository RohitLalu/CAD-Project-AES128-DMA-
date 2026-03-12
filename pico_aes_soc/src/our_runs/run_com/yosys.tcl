#!/usr/bin/env yosys

# Read AES modules first
# read_verilog -sv "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/aes_sbox.v"
# read_verilog -sv "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/aes_inv_sbox.v"
# read_verilog -sv "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/aes_key_mem.v"
# read_verilog -sv "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/aes_encipher_block.v"
# read_verilog -sv "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/aes_decipher_block.v"
# read_verilog -sv "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/aes_core.v"
# read_verilog -sv "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/aes.v"


#aes macro synth file
read_verilog -lib "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com/aes_synth.v"


# Read peripheral modules
read_verilog -sv "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/simpleuart.v"
read_verilog -sv "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/spimemio.v"

# Read SoC wrapper (MUST be before picorv32.v due to macro definitions!)
read_verilog -sv "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/picosoc_aes.v"

# Read CPU core LAST
read_verilog -sv "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/picorv32.v"


# Read SRAM macro behavioral model
read_verilog -lib "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com/sky130_sram_1kbyte_1rw1r_32x256_8.v"

log ""
ls

hierarchy -check -top picosoc

proc
flatten
opt

# picosoc_regs stays synthesized to flip-flops (it's small)
opt -full

# Technology-Independent Mapping

techmap
opt -fast

# Map flip-flops
dfflibmap -liberty "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"

# Map combinational logic
abc -liberty "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"

# Cleanup
clean
opt_clean -purge

log ""

# Write Verilog netlist
write_verilog -noattr -noexpr -nohex -nodec picosoc_syn.v

# Statistics
stat -liberty "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"

# Save stats to file
tee -o picosoc_syn_stats.txt stat -liberty "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"

log ""
log "========================================"
log "Synthesis Complete!"
log "========================================"
