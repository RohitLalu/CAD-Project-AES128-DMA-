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

global_route -congestion_iterations 180 -congestion_report_file congestion.rpt -verbose
puts "✓ Global routing complete"
write_db 7_global_route.odb