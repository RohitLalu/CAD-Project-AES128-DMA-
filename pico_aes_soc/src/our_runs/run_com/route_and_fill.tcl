
# # #!/usr/bin/env openroad
# set_thread_count 7

# # # --- Macro Paths ---
# # set SRAM_LEF "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com/sky130_sram_1kbyte_1rw1r_32x256_8.lef"
# # set SRAM_LIB "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com/sky130_sram_1kbyte_1rw1r_32x256_8_TT_1p8V_25C.lib"
# # set AES_LEF  "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com/aes_abstract.lef"
# # set AES_LIB  "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com/aes_macro.lib" 

# # set PDK_ROOT "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af"
# # set PDK "sky130A"
# # set LIB "sky130_fd_sc_hd"

# # set TECH_LEF "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef"
# # set SC_LEF "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef"
# # set LIB_FILE "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"

# # puts "PicoSoC + AES macro + SRAM macro Flow"

# # puts "\n--- Reading design ---"

# # puts "\n--- Reading design ---"
# # read_lef $TECH_LEF
# # read_lef $SC_LEF
# # read_lef $SRAM_LEF
# # read_lef $AES_LEF

# # read_liberty $LIB_FILE
# # read_liberty $SRAM_LIB
# # read_liberty $AES_LIB

# # read_verilog picosoc_syn.v
# # link_design picosoc
# # puts "✓ Design loaded with Macros"

# # read_lef $TECH_LEF
# # read_lef $SC_LEF
# # read_liberty $LIB_FILE
# # read_verilog picosoc_aes_sram.v
# # link_design picosoc
# # puts "✓ Design loaded"

# # puts "\n--- Setting timing constraints ---"
# # read_sdc picosoc_aes.sdc

# #read_db 6_timing_antenna_optimized.odb

# puts "\n--- Pre-route legalization ---"
# # Ensure all cells including hold buffers are legally placed before routing
# set_placement_padding -global -left 0 -right 0
# detailed_placement
# puts "✓ Pre-route legalization complete"

# puts "\n--- Global routing ---"
# global_route -allow_congestion -congestion_report_file congestion.rpt -verbose
# puts "✓ Global routing complete"

# # puts "\n--- Repairing antenna violations ---"
# # repair_antennas sky130_fd_sc_hd__diode_2

# puts "\n--- Detailed routing ---"
# detailed_route \
#     -output_drc route_drc.rpt \
#     -droute_end_iter 15 \
#     -bottom_routing_layer met1 \
#     -top_routing_layer met5

# puts "\n--- Repairing antenna violations ---"
# repair_antennas sky130_fd_sc_hd__diode_2

# puts "\n✓ Routing complete!"
# write_db 7_routed.odb
# detailed_route \
#     -output_drc          route_drc_post_antenna.rpt \
#     -droute_end_iter     5 \
#     -bottom_routing_layer met1 \
#     -top_routing_layer   met5
# write_db 7_routed_antenna_fixed.odb
# puts "✓ Antenna repair complete"

# puts "\n--- Post-route optimization ---"
# estimate_parasitics -global_routing

# # # Final timing fix with extracted parasitics
# repair_timing -setup -setup_margin 0.05
# repair_timing -hold -hold_margin 0.0 -max_buffer_percent 10
# detailed_placement
# write_db 8_post_route_opt.odb


# puts "\n--- Filler cells ---"
# filler_placement sky130_fd_sc_hd__fill_*

# puts "✓ Fillers inserted"
# write_db 9_final.odb
#!/usr/bin/env openroad
# =============================================================================
# route_and_fill.tcl  —  Global route, detailed route, antenna, fillers
# =============================================================================
set_thread_count 8

# =============================================================================
# STEP 1: Remove internal probe/measurement cells left by repair_design
#
# repair_design inserts sky130_fd_sc_hd__probe_p_8 instances internally to
# measure slew and fanout on nets. In this OpenROAD build (edf00dff) they are
# NOT automatically cleaned up, so they remain in the ODB and reach
# detailed_route which errors with DRT-0085 because probe_p_8 has no valid
# routing access pattern (it is not a real placeable standard cell).
#
# Fix: iterate all instances and destroy any whose master name matches
# "*probe*". Two-pass approach (collect then destroy) avoids iterator
# invalidation from modifying the collection during traversal.
# =============================================================================
puts "\n--- Removing internal probe cells (DRT-0085 fix) ---"
set block [ord::get_db_block]
set probe_insts {}
foreach inst [$block getInsts] {
    set mname [[$inst getMaster] getName]
    if {[string match "*probe*" $mname] || [string match "*load_slew*" $mname]} {
        lappend probe_insts $inst
        puts "  Found probe cell: [$inst getName]  master=$mname"
    }
}
foreach inst $probe_insts {
    odb::dbInst_destroy $inst
}
puts "✓ Removed [llength $probe_insts] probe cell(s)"

# =============================================================================
# STEP 2: Pre-route legalization
# Hold buffers inserted by repair_timing need one final detailed_placement
# pass to compact them before the router sees the netlist.
# =============================================================================
puts "\n--- Pre-route legalization ---"
set_placement_padding -global -left 0 -right 0
detailed_placement
puts "✓ Pre-route legalization complete"

# =============================================================================
# STEP 3: Global routing
# -congestion_iterations 30: enough iterations to converge
# -verbose: show per-iteration overflow so we can see progress
# Note: -allow_congestion removed — it disables convergence checking and
# can loop indefinitely; GRT-0230 (overflow cannot be reduced further) is
# the correct stop condition and still produces a usable guide file.
# =============================================================================
puts "\n--- Global routing ---"
global_route \
    -congestion_iterations  30 \
    -congestion_report_file congestion.rpt \
    -verbose
puts "✓ Global routing complete"
write_db 7_global_route.odb

# =============================================================================
# STEP 4: Detailed routing
# =============================================================================
puts "\n--- Detailed routing ---"
detailed_route \
    -output_drc           route_drc.rpt \
    -droute_end_iter      15 \
    -bottom_routing_layer met1 \
    -top_routing_layer    met5
puts "✓ Detailed routing complete"
write_db 7_routed.odb

# =============================================================================
# STEP 5: Antenna repair + re-route
# =============================================================================
puts "\n--- Antenna repair ---"
repair_antennas sky130_fd_sc_hd__diode_2
detailed_route \
    -output_drc           route_drc_post_antenna.rpt \
    -droute_end_iter      5 \
    -bottom_routing_layer met1 \
    -top_routing_layer    met5
write_db 7_routed_antenna_fixed.odb
puts "✓ Antenna repair complete"

# =============================================================================
# STEP 6: Post-route timing optimisation
# =============================================================================
puts "\n--- Post-route timing ---"
estimate_parasitics -global_routing
repair_timing -setup -setup_margin 0.05
repair_timing -hold  -hold_margin  0.0 -max_buffer_percent 10
detailed_placement
write_db 8_post_route_opt.odb
puts "✓ Post-route optimisation complete"

# =============================================================================
# STEP 7: Filler cells
# =============================================================================
puts "\n--- Filler cells ---"
filler_placement sky130_fd_sc_hd__fill_*
puts "✓ Fillers inserted"
write_db 9_final.odb
puts "✓ Final database → 9_final.odb"

puts "\n================================================================"
puts "  Route + fill complete. Check route_drc.rpt for DRC violations."
puts "================================================================"