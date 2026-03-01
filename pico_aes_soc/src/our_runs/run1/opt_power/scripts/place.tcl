# ========================================================================
# OpenROAD Cell Placement Script — Power Optimized
# ========================================================================
# Target: Sky130 130nm | Step: 4 (Cell Placement)
# ========================================================================

puts "\[INFO\] Stage 4: Cell Placement (power optimized)"

set PROJECT_ROOT "$env(HOME)/CAD-Project-AES128-DMA-/pico_aes_soc/src"
set OUTPUT_DIR   "$PROJECT_ROOT/our_runs/run1/opt_power/outputs"
set REPORT_FILE  "$OUTPUT_DIR/04_placement_report.txt"
set DB_PDN       "$OUTPUT_DIR/03_pdn.odb"
set DB_PLACE     "$OUTPUT_DIR/04_placement.odb"

set PDK_ROOT     "$env(HOME)/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af"
set LIB_FILE     "${PDK_ROOT}/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"

# -------------------------------------------------------------------------
# LOAD PREVIOUS STAGE
# -------------------------------------------------------------------------
puts "\[INFO\] Loading PDN database..."
if {![file exists $DB_PDN]} {
    puts "\[ERROR\] $DB_PDN not found! Run pdn.tcl first."
    exit 1
}
read_db $DB_PDN
read_liberty $LIB_FILE

set_wire_rc -layer met3

# -------------------------------------------------------------------------
# GLOBAL PLACEMENT
# -------------------------------------------------------------------------
puts "\[INFO\] Running Global Placement..."

global_placement \
    -density        0.45 \
    -routability_driven \
    -timing_driven

# -------------------------------------------------------------------------
# DETAILED PLACEMENT
# -------------------------------------------------------------------------
puts "\[INFO\] Running Detailed Placement..."
detailed_placement -max_displacement 50

# -------------------------------------------------------------------------
# POST-PLACEMENT OPTIMIZATION
# -------------------------------------------------------------------------
puts "\[INFO\] Running post-placement optimization..."
optimize_mirroring

# -------------------------------------------------------------------------
# VALIDATION
# -------------------------------------------------------------------------
puts "\[INFO\] Validating placement..."
check_placement -verbose

# -------------------------------------------------------------------------
# FILLER & DECAP
# -------------------------------------------------------------------------
puts "\[INFO\] Inserting filler and decap cells..."
filler_placement {sky130_fd_sc_hd__decap_3 sky130_fd_sc_hd__decap_4 sky130_fd_sc_hd__decap_6 sky130_fd_sc_hd__decap_8 sky130_fd_sc_hd__decap_12 sky130_fd_sc_hd__fill_1 sky130_fd_sc_hd__fill_2}

# -------------------------------------------------------------------------
# REPORT & SAVE
# -------------------------------------------------------------------------
puts "\[INFO\] Writing placement report..."
set rpt [open $REPORT_FILE w]
puts $rpt "===== Placement Report — Power Optimized ====="
puts $rpt "Global Placement Density  : 0.45"
puts $rpt "Routability Driven        : yes"
puts $rpt "Timing Driven             : yes"
puts $rpt "Max Displacement (DPL)    : 50"
puts $rpt "Decap Fill                : yes"
puts $rpt "============================================="
close $rpt

report_design_area

puts "\[INFO\] Saving: $DB_PLACE"
write_db $DB_PLACE

puts "\[SUCCESS\] Cell Placement Done!"
puts "\[INFO\]    Database : $DB_PLACE"
puts "\[INFO\]    Report   : $REPORT_FILE"