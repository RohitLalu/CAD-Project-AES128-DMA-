#!/usr/bin/env openroad
 
# route_and_fill.tcl  —  Global route, detailed route, antenna, fillers, reports
 
set_thread_count 8
 
set RUNDIR "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com2"
 
# ─────────────────────────────────────────────────────────────────────────────
# STEP 1: Remove probe cells (DRT-0085 fix)
# ─────────────────────────────────────────────────────────────────────────────
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
 
# ─────────────────────────────────────────────────────────────────────────────
# STEP 2: Pre-route legalization
# ─────────────────────────────────────────────────────────────────────────────
puts "\n--- Pre-route legalization ---"
set_placement_padding -global -left 0 -right 0
detailed_placement
puts "✓ Pre-route legalization complete"
 
# ─────────────────────────────────────────────────────────────────────────────
# STEP 3: Global routing
# -allow_congestion: suppresses GRT-0119 on residual single-overflow tiles
#   so detailed routing can attempt to fix them internally
# ─────────────────────────────────────────────────────────────────────────────
puts "\n--- Global routing ---"
set_global_routing_layer_adjustment met1 0.4
set_global_routing_layer_adjustment met2 0.2
set_global_routing_layer_adjustment met3 0.3
set_routing_layers -signal met1-met5

global_route -allow_congestion -congestion_iterations 180 -congestion_report_file congestion.rpt -verbose
puts "✓ Global routing complete"
write_db 7_global_route.odb
 
# ─────────────────────────────────────────────────────────────────────────────
# STEP 4: Detailed routing (full stack, before antenna repair)
# -droute_end_iter 64: gives TritonRoute enough rerouting passes to converge
# ─────────────────────────────────────────────────────────────────────────────
puts "\n--- Detailed routing ---"
detailed_route \
    -output_drc           route_drc.rpt \
    -bottom_routing_layer met1 \
    -top_routing_layer    met5 \
    -verbose 1
puts "✓ Detailed routing complete"
write_db 7_routed.odb
 
puts "\n--- Antenna repair ---"
estimate_parasitics -global_routing
repair_antennas sky130_fd_sc_hd__diode_2 -ratio_margin 10
set block [ord::get_db_block]
foreach inst [$block getInsts] {
    set mname [[$inst getMaster] getName]
    if {[string match "sky130_fd_sc_hd__diode_2" $mname]} {
        set iname [$inst getName]
        if {[string match "ANTENNA_1237" $iname]} {
            puts "  Removing unreachable diode: $iname"
            odb::dbInst_destroy $inst
        }
    }
}
detailed_placement
detailed_route \
    -output_drc           route_drc_post_antenna.rpt \
    -bottom_routing_layer met1 \
    -top_routing_layer    met5 \
    -droute_end_iter      10
write_db 7_routed_antenna_fixed.odb
puts "✓ Antenna repair complete"
 
puts "\n--- Filler cells ---"
filler_placement sky130_fd_sc_hd__fill_*
puts "✓ Fillers inserted"
 
detailed_route \
    -output_drc           route_post_repairs.rpt \
    -bottom_routing_layer met1 \
    -top_routing_layer    met5 \
    -droute_end_iter      15
write_db 8_final.odb
puts "✓ Final database → 8_final.odb"