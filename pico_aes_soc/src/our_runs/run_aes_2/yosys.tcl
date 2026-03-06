
# Read AES modules first
read_verilog -sv "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/aes_sbox.v"
read_verilog -sv "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/aes_inv_sbox.v"
read_verilog -sv "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/aes_key_mem.v"
read_verilog -sv "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/aes_encipher_block.v"
read_verilog -sv "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/aes_decipher_block.v"
read_verilog -sv "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/aes_core.v"
read_verilog -sv "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/aes.v"

# Check what modules were loaded
ls

hierarchy -check -top aes

# High-Level Synthesis

proc
flatten
opt -full


# Prepare memories mapping to flip-flops
# memory -nomap
# memory_map

# Technology-Independent Mapping

techmap
opt -fast

# Sky130 Technology Mapping
synth -top aes

# Map flip-flops
dfflibmap -liberty "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"

# Map combinational logic
abc -liberty "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"

# Cleanup
clean
opt_clean -purge

# Generate Outputs
# Write Verilog netlist
write_verilog -noattr -noexpr -nohex -nodec aes_synth.v

# Save stats to file
tee -o aes_stats.txt stat -liberty "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"

stat

log ""
log "========================================"
log "Synthesis Complete!"
log "========================================"
