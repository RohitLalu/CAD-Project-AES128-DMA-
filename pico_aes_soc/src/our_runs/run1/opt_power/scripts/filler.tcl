# ========================================================================
# OpenROAD Filler Placement Script
# ========================================================================
# Usage: source filler.tcl
# Pre-req: Routing must be completed (06_routing.odb)
# This step fills empty gaps in rows to ensure N-well continuity.
# ========================================================================

puts "\[INFO\] Stage 7: Filler Placement"

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

set DB_ROUTE "${RESULTS_DIR}/06_routing.odb"
set DB_FILLER "${RESULTS_DIR}/07_filler.odb"

# -------------------------------------------------------------------------
# 2. LOAD PREVIOUS STAGE DATABASE
# -------------------------------------------------------------------------
puts "\[INFO\] Loading routing database from: $DB_ROUTE"
if {![file exists $DB_ROUTE]} {
    puts "\[ERROR\] Routing database not found: $DB_ROUTE"
    puts "\[ERROR\] Please run routing step first (route.tcl)"
    exit 1
}
read_db $DB_ROUTE

# -------------------------------------------------------------------------
# 3. Define Filler Cells
# -------------------------------------------------------------------------
set fillers {
    sky130_fd_sc_hd__fill_8
    sky130_fd_sc_hd__fill_4
    sky130_fd_sc_hd__fill_2
    sky130_fd_sc_hd__fill_1
}

# -------------------------------------------------------------------------
# 4. Run Placement
# -------------------------------------------------------------------------

puts "\[INFO\] Placing filler cells..."
filler_placement $fillers

# -------------------------------------------------------------------------
# 5. Verification
# -------------------------------------------------------------------------

puts "\[INFO\] Checking connectivity..."
report_floating_nets

puts "\[SUCCESS\] Filler placement complete."

# -------------------------------------------------------------------------
# 6. SAVE INTERMEDIATE DATABASE
# -------------------------------------------------------------------------
puts "\[INFO\] Saving filler placement database to: $DB_FILLER"
write_db $DB_FILLER

puts "\[INFO\] Filler placement step completed successfully!"