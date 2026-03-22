#!/usr/bin/env yosys

# yosys.tcl  —  PicoSoC + AES + SRAM synthesis for sky130

# AES — pre-synthesised gate-level netlist, treat as blackbox
read_verilog -lib "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com/aes_synth.v"

# SoC peripherals
read_verilog -sv "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/simpleuart.v"
read_verilog -sv "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/spimemio.v"

# SoC top — picosoc_aes_synth.v has the behavioural picosoc_mem REMOVED.
# It contains only: module picosoc (top) + module picosoc_regs (regs → FFs)
read_verilog -sv "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/picosoc_aes.v"

# CPU — must come AFTER picosoc_aes_synth.v sets the `define macros
read_verilog -sv "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/picorv32.v"

# SRAM macro — blackbox, port declarations only
read_verilog -lib "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com/sky130_sram_1kbyte_1rw1r_32x256_8.v"

# =============================================================================
# Stage 2: Elaborate
# =============================================================================
log ""
log "=== Loaded modules ==="
ls

hierarchy -check -top picosoc

# =============================================================================
# Stage 3: High-level synthesis
# =============================================================================
proc
flatten
opt

# CRITICAL: memory_map must run BEFORE techmap.
# picosoc_regs contains a reg array that Yosys infers as a $mem cell after
# flatten. memory_map converts it to mux+FF logic so that techmap and
# write_verilog never emit a behavioural reg array — which OpenROAD rejects.
memory_map

opt -full

# =============================================================================
# Stage 4: Technology mapping
# =============================================================================
techmap
opt -fast

dfflibmap -liberty "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"
abc       -liberty "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"

clean
opt_clean -purge

# =============================================================================
# Stage 5: Verify blackboxes survived
# =============================================================================
log ""
log "=== Blackbox instances (should show aes and sky130_sram) ==="
select -list t:aes
select -list t:sky130_sram_1kbyte_1rw1r_32x256_8

# =============================================================================
# Stage 6: Outputs
# =============================================================================
write_verilog -noattr -noexpr -nohex -nodec "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com/picosoc_syn.v"

stat -liberty "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"

tee -o picosoc_syn_stats.txt stat -liberty "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"

log ""
log "================================================"
log "  Synthesis complete → picosoc_syn.v"
log "================================================"