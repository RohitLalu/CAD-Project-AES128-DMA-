# ========================================================================
# OpenROAD PDN Generation Script (Sky130)
# ========================================================================
# Usage: source pdn.tcl
# Pre-req: Pin placement must be completed (02_pins.odb)
# This script builds the power grid: Rings, Straps, and Rails.
# ========================================================================

puts "\[INFO\] Stage 3: PDN Generation"

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

set DB_PINS "${RESULTS_DIR}/02_pins.odb"
set DB_PDN "${RESULTS_DIR}/03_pdn.odb"

# -------------------------------------------------------------------------
# 2. LOAD PREVIOUS STAGE DATABASE
# -------------------------------------------------------------------------
puts "\[INFO\] Loading pin placement database from: $DB_PINS"
if {![file exists $DB_PINS]} {
    puts "\[ERROR\] Pin placement database not found: $DB_PINS"
    puts "\[ERROR\] Please run pin placement step first (pins.tcl)"
    exit 1
}
read_db $DB_PINS

# -------------------------------------------------------------------------
# 3. Global Connections
# -------------------------------------------------------------------------

# Connect Power (VPWR)
add_global_connection -net {VPWR} -inst_pattern {.*} -pin_pattern {^VPWR$} -power
add_global_connection -net {VPWR} -inst_pattern {.*} -pin_pattern {^VPB$}  -power

# Connect Ground (VGND)
add_global_connection -net {VGND} -inst_pattern {.*} -pin_pattern {^VGND$} -ground
add_global_connection -net {VGND} -inst_pattern {.*} -pin_pattern {^VNB$}  -ground

# -------------------------------------------------------------------------
# 4. Voltage Domain Definition
# -------------------------------------------------------------------------
set_voltage_domain -name {CORE} -power {VPWR} -ground {VGND}

# -------------------------------------------------------------------------
# 5. Define PDN Grid
# -------------------------------------------------------------------------
define_pdn_grid -name {stdcell_grid} -voltage_domains {CORE}

# -------------------------------------------------------------------------
# 6. Standard Cell Rails (Metal 1)
# -------------------------------------------------------------------------
add_pdn_stripe -grid {stdcell_grid} \
    -layer {met1} \
    -width {0.48} \
    -pitch {2.72} \
    -offset {0} \
    -followpins

# -------------------------------------------------------------------------
# 7. Core Power Ring (Metal 4 & Metal 5)
# -------------------------------------------------------------------------
add_pdn_ring -grid {stdcell_grid} \
    -layers {met4 met5} \
    -widths {5.0 5.0} \
    -spacings {2.0 2.0} \
    -core_offsets {5.0 5.0}

# -------------------------------------------------------------------------
# 8. Power Straps (Metal 4 & Metal 5)
# -------------------------------------------------------------------------

# Vertical Straps (Metal 4)
add_pdn_stripe -grid {stdcell_grid} \
    -layer {met4} \
    -width {1.6} \
    -pitch {40.0} \
    -offset {13.570}

# Horizontal Straps (Metal 5)
add_pdn_stripe -grid {stdcell_grid} \
    -layer {met5} \
    -width {1.6} \
    -pitch {40.0} \
    -offset {13.600}

# -------------------------------------------------------------------------
# 9. Vias / Connections
# -------------------------------------------------------------------------
add_pdn_connect -grid {stdcell_grid} -layers {met1 met4}

# Connect Vertical Straps (met4) to Horizontal Straps/Ring (met5)
add_pdn_connect -grid {stdcell_grid} -layers {met4 met5}

# -------------------------------------------------------------------------
# 10. Generate Grid
# -------------------------------------------------------------------------
puts "\[INFO\] Generating PDN..."
pdngen

puts "\[SUCCESS\] PDN generation complete."

# -------------------------------------------------------------------------
# 11. SAVE INTERMEDIATE DATABASE
# -------------------------------------------------------------------------
puts "\[INFO\] Saving PDN database to: $DB_PDN"
write_db $DB_PDN

puts "\[INFO\] PDN generation step completed successfully!"