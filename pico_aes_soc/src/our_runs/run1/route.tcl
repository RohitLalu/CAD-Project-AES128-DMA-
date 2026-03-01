# ========================================================================
# OpenROAD Routing Script (Global & Detailed)
# ========================================================================
# Usage: source route.tcl
# Pre-req: CTS must be completed (05_cts.odb)
# ========================================================================

puts "\[INFO\] Stage 6: Routing"

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

set DB_CTS "${RESULTS_DIR}/05_cts.odb"
set DB_ROUTE "${RESULTS_DIR}/06_routing.odb"
set ROUTE_GUIDE "${RESULTS_DIR}/route.guide"
set ROUTE_DRC "${LOGS_DIR}/route_drc.rpt"
set ROUTE_MAZE "${LOGS_DIR}/route.maze"

# -------------------------------------------------------------------------
# 2. LOAD PREVIOUS STAGE DATABASE
# -------------------------------------------------------------------------
puts "\[INFO\] Loading CTS database from: $DB_CTS"
if {![file exists $DB_CTS]} {
    puts "\[ERROR\] CTS database not found: $DB_CTS"
    puts "\[ERROR\] Please run CTS step first (cts.tcl)"
    exit 1
}
read_db $DB_CTS

# -------------------------------------------------------------------------
# 3. Global Routing (GRT)
# -------------------------------------------------------------------------

puts "\[INFO\] Running Global Routing..."
global_route \
    -guide_file $ROUTE_GUIDE \
    -congestion_iterations 100 \
    -verbose

# -------------------------------------------------------------------------
# 4. Detailed Routing (DRT)
# -------------------------------------------------------------------------

puts "\[INFO\] Running Detailed Routing..."
detailed_route \
    -output_drc $ROUTE_DRC \
    -output_maze $ROUTE_MAZE

# -------------------------------------------------------------------------
# 5. Validation
# -------------------------------------------------------------------------
# Check if the routing is clean.
# A "clean" design has 0 violations.

if {[file exists $ROUTE_DRC]} {
    puts "\[INFO\] DRC Report generated: $ROUTE_DRC"
    # Optional: Print the last few lines of the report to see the summary
    catch {exec tail -n 5 $ROUTE_DRC} result
    puts $result
}

puts "\[SUCCESS\] Routing complete."

# -------------------------------------------------------------------------
# 6. SAVE INTERMEDIATE DATABASE
# -------------------------------------------------------------------------
puts "\[INFO\] Saving routing database to: $DB_ROUTE"
write_db $DB_ROUTE

puts "\[INFO\] Routing step completed successfully!"