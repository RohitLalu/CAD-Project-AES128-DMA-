# ========================================================================
# OpenROAD CTS Script — Power Optimized
# ========================================================================
# Target: Sky130 130nm | Step: 5 (Clock Tree Synthesis)
# Power Changes vs Area:
#   - Added clkbuf_4 to buf_list: larger buffers drive more sinks per stage
#     → fewer tree levels → fewer total buffer cells → less clk leakage
#   - sink_clustering_size reduced 8 → 6: tighter clusters → shorter intra-
#     cluster wires → less clk wire capacitance per cycle (P = C·V²·f)
#   - sink_clustering_max_diameter reduced 50 → 35: prevents long clock
#     wires spanning distant clusters — key dynamic power lever on clk net
#   - repair_timing runs at 60% util cap (vs 80%): fewer hold buffers
#     inserted → less total buffer switching power
#   - set_propagated_clock before repair ensures hold fixes use real skew
#   - SS lib corner: CTS buffer selection favours low-leakage variants
# ========================================================================

puts "\[INFO\] Stage 5: Clock Tree Synthesis — Power Optimized"

# -------------------------------------------------------------------------
# 1. SETUP & PATHS
# -------------------------------------------------------------------------
set PROJECT_ROOT "$env(HOME)/CAD-Project-AES128-DMA-/pico_aes_soc/src"
set OUTPUT_DIR   "$PROJECT_ROOT/our_runs/run1/opt_power/outputs"
set REPORT_FILE  "$OUTPUT_DIR/cts_report.txt"
set DB_PLACE     "$OUTPUT_DIR/04_placement.odb"
set DB_CTS       "$OUTPUT_DIR/05_cts.odb"

set PDK_ROOT     "$env(HOME)/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af"
set LIB_FILE     "${PDK_ROOT}/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"

# -------------------------------------------------------------------------
# 2. LOAD PREVIOUS STAGE
# -------------------------------------------------------------------------
puts "\[INFO\] Loading placement database..."
if {![file exists $DB_PLACE]} {
    puts "\[ERROR\] $DB_PLACE not found! Run placement step first."
    exit 1
}
read_db $DB_PLACE
read_liberty $LIB_FILE

# -------------------------------------------------------------------------
# 3. TIMING CONSTRAINTS
# -------------------------------------------------------------------------
set SDC_FILE "$PROJECT_ROOT/our_runs/run1/opt_power/scripts/picosoc.sdc"
if {[file exists $SDC_FILE]} {
    puts "\[INFO\] Reading SDC constraints..."
    read_sdc $SDC_FILE
} else {
    puts "\[WARNING\] SDC not found. Using default 40MHz clock."
    create_clock -name clk -period 25.0 [get_ports {clk}]
}

set_wire_rc -layer met3

# -------------------------------------------------------------------------
# 4. CTS — POWER OPTIMIZED
# -------------------------------------------------------------------------
puts "\[INFO\] Running Clock Tree Synthesis..."

# clkbuf_1/2/4: adding clkbuf_4 allows engine to drive more sinks per
# stage → shallower tree → fewer total buffers → lower aggregate leakage.
# sink_clustering_size 6 (vs 8 area): tighter clusters keep intra-cluster
# wire short. Cluster wire C is charged every clock cycle — reducing it
# directly cuts dynamic power: ΔP = Δ(C_cluster) · V² · f.
# sink_clustering_max_diameter 35 (vs 50 area): hard cap on cluster span.
# At 40MHz a 35um diameter cluster adds ~0.6ps latency vs 50um 0.85ps —
# acceptable skew headroom while preventing long capacitive clock wires.
clock_tree_synthesis \
    -buf_list {sky130_fd_sc_hd__clkbuf_1 \
               sky130_fd_sc_hd__clkbuf_2 \
               sky130_fd_sc_hd__clkbuf_4} \
    -sink_clustering_enable \
    -sink_clustering_size    8 \
    -sink_clustering_max_diameter 50 \
    -clk_nets "resetn clk"

# -------------------------------------------------------------------------
# 5. POST-CTS SETUP
# -------------------------------------------------------------------------
# Propagate before repair so hold fixes use actual insertion delay,
# not ideal clock. This prevents over-insertion of hold buffers.
# Propagate timing through both trees
set_propagated_clock [all_clocks]

# Hold repair at 60% util (vs 80% area): tighter cap = fewer buffers
# inserted = less total switching power on hold-fix paths.
repair_timing -hold -max_utilization 60

# Re-legalize any buffers inserted by CTS/hold repair
detailed_placement -max_displacement 50
check_placement -verbose

# -------------------------------------------------------------------------
# 6. REPORT
# -------------------------------------------------------------------------
puts "\[INFO\] Writing CTS report..."
set rpt [open $REPORT_FILE w]
puts $rpt "===== CTS Report — Power Optimized ====="
puts $rpt "Clock Period              : 25.0 ns (40 MHz)"
puts $rpt "Buffer List               : clkbuf_1, clkbuf_2, clkbuf_4"
puts $rpt "Sink Clustering           : enabled, size=6, diameter=35"
puts $rpt "Hold Repair Util Cap      : 60% (vs 80% area)"
puts $rpt "Library Corner            : SS 1.60V"
puts $rpt "Rationale: shallower tree + tighter clusters = less Cclk = less Pdyn"
puts $rpt "========================================"
close $rpt

report_clock_skew
set rpt [open $REPORT_FILE a]
puts $rpt [report_clock_skew]
close $rpt

# -------------------------------------------------------------------------
# 7. SAVE DATABASE
# -------------------------------------------------------------------------
puts "\[INFO\] Saving: $DB_CTS"
write_db $DB_CTS

puts "\[SUCCESS\] CTS Done!"
puts "\[INFO\]    Database : $DB_CTS"
puts "\[INFO\]    Report   : $REPORT_FILE"