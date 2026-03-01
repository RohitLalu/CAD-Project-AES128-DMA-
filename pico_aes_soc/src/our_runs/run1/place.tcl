# ========================================================================
# OpenROAD Cell Placement Script
# ========================================================================
# Usage: source place.tcl
# Pre-req: PDN generation must be completed (03_pdn.odb)
# ========================================================================

puts "\[INFO\] Stage 4: Cell Placement"

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

set DB_PDN "${RESULTS_DIR}/03_pdn.odb"
set DB_PLACE "${RESULTS_DIR}/04_placement.odb"

# -------------------------------------------------------------------------
# 2. LOAD PREVIOUS STAGE DATABASE
# -------------------------------------------------------------------------
puts "\[INFO\] Loading PDN database from: $DB_PDN"
if {![file exists $DB_PDN]} {
    puts "\[ERROR\] PDN database not found: $DB_PDN"
    puts "\[ERROR\] Please run PDN generation step first (pdn.tcl)"
    exit 1
}
read_db $DB_PDN

# -------------------------------------------------------------------------
# 3. Global Placement (GPL)
# -------------------------------------------------------------------------

puts "\[INFO\] Running Global Placement..."
global_placement -density 0.71

# -------------------------------------------------------------------------
# 4. Detailed Placement (DPL)
# -------------------------------------------------------------------------

puts "\[INFO\] Running Detailed Placement..."
detailed_placement

# -------------------------------------------------------------------------
# 5. Post-Placement Validation
# -------------------------------------------------------------------------

puts "\[INFO\] Validating placement..."
check_placement

puts "\[SUCCESS\] Placement complete and verified."

# -------------------------------------------------------------------------
# 6. SAVE INTERMEDIATE DATABASE
# -------------------------------------------------------------------------
puts "\[INFO\] Saving placement database to: $DB_PLACE"
write_db $DB_PLACE

puts "\[INFO\] Cell placement step completed successfully!"