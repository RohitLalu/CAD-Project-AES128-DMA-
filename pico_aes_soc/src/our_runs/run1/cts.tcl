# ========================================================================
# OpenROAD CTS Script
# ========================================================================
# Pre-req: Cell placement must be completed (04_placement.odb)
# ========================================================================

puts "\[INFO\] Stage 5: Clock Tree Synthesis (CTS)"

# -------------------------------------------------------------------------
# 1. SETUP & PATHS
# -------------------------------------------------------------------------
set RESULTS_DIR "results"
set LOGS_DIR "logs"

# Create output directories if they don't exist
if {![file exists $RESULTS_DIR]} {
    file mkdir $RESULTS_DIR
}
if {![file exists $LOGS_DIR]} {
    file mkdir $LOGS_DIR
}

set DB_PLACE "${RESULTS_DIR}/04_placement.odb"
set DB_CTS "${RESULTS_DIR}/05_cts.odb"

# -------------------------------------------------------------------------
# 2. LOAD PREVIOUS STAGE DATABASE
# -------------------------------------------------------------------------
puts "\[INFO\] Loading placement database from: $DB_PLACE"
if {![file exists $DB_PLACE]} {
    puts "\[ERROR\] Placement database not found: $DB_PLACE"
    puts "\[ERROR\] Please run placement step first (place.tcl)"
    exit 1
}
read_db $DB_PLACE

# -------------------------------------------------------------------------
# 3. Read Constraints
# -------------------------------------------------------------------------
if {[file exists "picosoc.sdc"]} {
    puts "\[INFO\] Reading SDC constraints..."
    read_sdc picosoc.sdc
} else {
    puts "\[WARNING\] SDC file not found! Using default 40MHz clock."
    create_clock -name clk -period 25.0 [get_ports {clk}]
}

# -------------------------------------------------------------------------
# 4. Configure CTS
# -------------------------------------------------------------------------
puts "\[INFO\] Running Clock Tree Synthesis..."
clock_tree_synthesis \
    -buf_list {sky130_fd_sc_hd__clkbuf_2 sky130_fd_sc_hd__clkbuf_4 sky130_fd_sc_hd__clkbuf_8} \
    -sink_clustering_enable

# -------------------------------------------------------------------------
# 5. Finalize & Report
# -------------------------------------------------------------------------
set_propagated_clock [all_clocks]

puts "\[INFO\] Reporting Clock Skew..."
report_clock_skew

puts "\[SUCCESS\] Clock Tree Synthesis complete."

# -------------------------------------------------------------------------
# 6. SAVE INTERMEDIATE DATABASE
# -------------------------------------------------------------------------
puts "\[INFO\] Saving CTS database to: $DB_CTS"
write_db $DB_CTS

puts "\[INFO\] Clock Tree Synthesis step completed successfully!"