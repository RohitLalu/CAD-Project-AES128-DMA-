#!/usr/bin/env openroad
# =============================================================================
# gen_aes_lef.tcl  —  Generate aes_abstract.lef from aes_macro.def
# Run: openroad -exit gen_aes_lef.tcl 2>&1 | tee gen_aes_lef.log
# =============================================================================

set PDK_ROOT "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af"
set RUNDIR   "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com"

set TECH_LEF "$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef"
set SC_LEF   "$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef"
set LIB_FILE "$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"

puts "=== Generating AES abstract LEF from routed DEF ==="

read_lef $TECH_LEF
read_lef $SC_LEF
read_liberty $LIB_FILE

puts "Reading AES DEF..."
read_def $RUNDIR/aes_macro.def
# DEF already defines the die area — link_design picks it up automatically

puts "Writing abstract LEF..."
write_abstract_lef \
    -bloat_occupied_layers \
    $RUNDIR/aes_abstract.lef

puts "✓ Written: $RUNDIR/aes_abstract.lef"

# Fix SIZE 0 BY 0 — write_abstract_lef emits 0x0 when the die boundary
# isn't explicitly initialised via initialize_floorplan. Patch it via shell.
set size_check [exec grep "SIZE" $RUNDIR/aes_abstract.lef]
puts "Current SIZE: $size_check"

if {[string match "*SIZE 0 BY 0*" $size_check]} {
    puts "SIZE is 0x0 — applying fix (884.0 x 884.0 from DEF DIEAREA)..."
    exec python3 $RUNDIR/fix_aes_lef.py
} else {
    puts "SIZE looks correct, no fix needed"
}

puts ""
puts "Final verification:"
exec sh -c "grep -E '^MACRO|^  SIZE|^  CLASS|^  PIN ' $RUNDIR/aes_abstract.lef | head -10"