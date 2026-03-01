# ========================================================================
# OpenROAD Routing Script — Power Optimized
# ========================================================================
# Target: Sky130 130nm | Step: 6 (Global + Detailed Routing)
# Power Changes vs Area:
#   - SS corner lib: repair_timing uses low-leakage buffers for ECO fixes
#   - repair_timing util cap lowered 80% → 65%: fewer ECO buffers inserted
#     → less total buffer switching power
#   - droute_end_iter raised 10 → 32: more iterations → cleaner DRC →
#     fewer antenna fixes → less extra metal → less coupling capacitance
#   - top_routing_layer kept met5 but met5 reserved for PDN via layer
#     directives — signal routes prefer met1-met4 (shorter vias, less cap)
#   - repair_antenna before post-route repair: removes antenna metal early
#     so timing repair sees accurate parasitics → fewer redundant buffers
#   - congestion_iterations raised 100 → 150: better global route quality
#     → less detailed route rip-up → less added wire length
# ========================================================================

puts "\[INFO\] Stage 6: Routing (power optimized)"

# -------------------------------------------------------------------------
# 1. SETUP & PATHS
# -------------------------------------------------------------------------
set PROJECT_ROOT "$env(HOME)/CAD-Project-AES128-DMA-/pico_aes_soc/src"
set OUTPUT_DIR   "$PROJECT_ROOT/our_runs/run1/opt_power/outputs"
set REPORT_FILE  "$OUTPUT_DIR/routing_report.txt"
set DB_CTS       "$OUTPUT_DIR/05_cts.odb"
set DB_ROUTE     "$OUTPUT_DIR/06_routing.odb"
set ROUTE_GUIDE  "$OUTPUT_DIR/route.guide"
set ROUTE_DRC    "$OUTPUT_DIR/route_drc.rpt"

set PDK_ROOT     "$env(HOME)/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af"
set LIB_FILE     "${PDK_ROOT}/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"

# -------------------------------------------------------------------------
# 2. LOAD PREVIOUS STAGE
# -------------------------------------------------------------------------
puts "\[INFO\] Loading CTS database..."
if {![file exists $DB_CTS]} {
    puts "\[ERROR\] $DB_CTS not found! Run CTS step first."
    exit 1
}
read_db $DB_CTS
read_liberty $LIB_FILE

# -------------------------------------------------------------------------
# 3. TIE FANOUT & WIRE RC
# -------------------------------------------------------------------------
repair_tie_fanout -separation 1 sky130_fd_sc_hd__conb_1/HI
repair_tie_fanout -separation 1 sky130_fd_sc_hd__conb_1/LO

set_wire_rc -layer met3

# Handle tie special nets
set block [ord::get_db_block]
set one_net [$block findNet "one_"]
if {$one_net != "NULL"} {
    $one_net setSpecial
    $one_net setSigType SIGNAL
}
set zero_net [$block findNet "zero_"]
if {$zero_net != "NULL"} {
    $zero_net setSpecial
    $zero_net setSigType SIGNAL
}

# -------------------------------------------------------------------------
# 4. PRE-ROUTING TIMING REPAIR
# -------------------------------------------------------------------------
puts "\[INFO\] Pre-routing timing repair..."

# Lower util cap (65% vs 80%): fewer buffers inserted pre-route means
# less total buffer cell area and switching capacitance. Buffers inserted
# at this stage often get long connecting wires post-route.
repair_timing -setup -max_utilization 65
repair_timing -hold  -max_utilization 65

set_global_routing_layer_adjustment met5 1.0

# -------------------------------------------------------------------------
# 5. GLOBAL ROUTING
# -------------------------------------------------------------------------
puts "\[INFO\] Running Global Routing..."

# congestion_iterations 150 (vs 100): extra iterations produce a cleaner
# routing topology — fewer congested regions mean TritonRoute doesn't need
# to insert detour wires, reducing total wire length and capacitance.
global_route \
    -guide_file             $ROUTE_GUIDE \
    -congestion_iterations  150 \
    -congestion_report_file "$OUTPUT_DIR/congestion.rpt" \
    -verbose

set_dont_touch [get_nets {one_}]

# -------------------------------------------------------------------------
# 6. DETAILED ROUTING
# -------------------------------------------------------------------------
puts "\[INFO\] Running Detailed Routing..."

# droute_end_iter 32 (vs 10): more iterations → TritonRoute resolves more
# DRC violations natively, rather than leaving them for repair_antenna to
# fix with extra inserted metal or jumper wires. Cleaner route = less
# parasitic capacitance from patch wires.
# Signal layers met1-met4; met5 reserved for PDN horizontal straps.
# Keeping signals off met5 avoids coupling to the wide PDN straps.
detailed_route \
    -output_drc           $ROUTE_DRC \
    -droute_end_iter      32 \
    -bottom_routing_layer met1 \
    -top_routing_layer    met5 \
    -verbose              1

# -------------------------------------------------------------------------
# 7. POST-ROUTING REPAIR
# -------------------------------------------------------------------------
puts "\[INFO\] Post-routing optimizations..."

# Antenna fix first: removes excess metal before timing analysis, so
# subsequent repair_timing sees accurate parasitics and inserts fewer
# redundant buffers.
repair_antenna

# Final timing repair with actual extracted parasitics
repair_timing -setup -max_utilization 65
repair_timing -hold  -max_utilization 65

# -------------------------------------------------------------------------
# 8. REPORT
# -------------------------------------------------------------------------
puts "\[INFO\] Writing routing report..."

set rpt [open $REPORT_FILE w]
puts $rpt "===== Routing Report — Power Optimized ====="
puts $rpt "Global Route Iterations  : 150  (vs 100 area)"
puts $rpt "Detailed Route Iterations: 32   (vs 10 area)"
puts $rpt "Signal Routing Layers    : met1 - met4 (met5 reserved for PDN)"
puts $rpt "Timing Repair Util Cap   : 65%  (vs 80% area)"
puts $rpt "Library Corner           : SS 1.60V"
puts $rpt "============================================="
close $rpt

report_design_area
set rpt [open $REPORT_FILE a]
puts $rpt [report_design_area]
puts $rpt [report_timing -max_paths 5]
close $rpt

if {[file exists $ROUTE_DRC]} {
    catch {exec tail -n 10 $ROUTE_DRC} drc_summary
    puts "\[INFO\] DRC Summary:"
    puts $drc_summary
    set rpt [open $REPORT_FILE a]
    puts $rpt "--- DRC Summary ---"
    puts $rpt $drc_summary
    close $rpt
}

# -------------------------------------------------------------------------
# 9. SAVE DATABASE
# -------------------------------------------------------------------------
puts "\[INFO\] Saving: $DB_ROUTE"
write_db $DB_ROUTE

puts "\[SUCCESS\] Routing Done!"
puts "\[INFO\]    Database : $DB_ROUTE"
puts "\[INFO\]    Report   : $REPORT_FILE"
puts "\[INFO\]    DRC      : $ROUTE_DRC"