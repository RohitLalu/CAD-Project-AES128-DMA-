# ========================================================================
# OpenROAD Floorplanning Script — Power Optimized
# ========================================================================
# Target: Sky130 130nm | Step: 1 (Floorplanning)
# Power Strategy:
#   - Lower core utilization (50-55%) → reduced routing congestion →
#     fewer buffers inserted → less dynamic power
#   - Denser tap cells → lower substrate resistance → less latch-up risk
#     and improved Vdd/Vss integrity
#   - Larger core margins → room for robust power rings
# NOTE: PDN is handled entirely in pdn.tcl (after pin placement)
#       Filler/decap placement is handled in place.tcl (after detail placement)
# ========================================================================

# -------------------------------------------------------------------------
# 1. SETUP & PATHS
# -------------------------------------------------------------------------
puts "\[INFO\] Setting up environment (power-optimized)..."

set PDK_ROOT     "$env(HOME)/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af"
set PDK          "sky130A"
set STD_CELL_LIB "sky130_fd_sc_hd"
set PROJECT_ROOT "$env(HOME)/CAD-Project-AES128-DMA-/pico_aes_soc/src"

set TECH_LEF     "${PDK_ROOT}/${PDK}/libs.ref/${STD_CELL_LIB}/techlef/${STD_CELL_LIB}__nom.tlef"
set SC_LEF       "${PDK_ROOT}/${PDK}/libs.ref/${STD_CELL_LIB}/lef/${STD_CELL_LIB}.lef"
set LIB_FILE     "${PDK_ROOT}/${PDK}/libs.ref/${STD_CELL_LIB}/lib/${STD_CELL_LIB}__tt_025C_1v80.lib"

set OUTPUT_DIR   "$PROJECT_ROOT/our_runs/run1/opt_power/outputs"
set REPORT_FILE  "$OUTPUT_DIR/fpn_report.txt"
set DB_FLOORPLAN "$OUTPUT_DIR/01_fp.odb"

file mkdir $OUTPUT_DIR

# -------------------------------------------------------------------------
# 2. READ DESIGN
# -------------------------------------------------------------------------
puts "\[INFO\] Reading design files..."

read_lef $TECH_LEF
read_lef $SC_LEF
read_liberty $LIB_FILE

set NETLIST "$OUTPUT_DIR/netlist.v"
if {[file exists $NETLIST]} {
    read_verilog $NETLIST
} else {
    puts "\[ERROR\] netlist.v not found in $OUTPUT_DIR"
    exit 1
}

link_design picosoc

# -------------------------------------------------------------------------
# 3. FLOORPLANNING — POWER OPTIMIZED
# -------------------------------------------------------------------------
puts "\[INFO\] Stage 1: Floorplanning (power optimized)..."

# Larger die → lower utilization (~50-55%) → placer clusters logic tightly
# → shorter interconnects → less switching capacitance → lower dynamic power.
# 60um margins give the PDN ring generator enough room without crowding rows.
initialize_floorplan \
    -die_area  {0 0 1600 1600} \
    -core_area {60 60 1540 1540} \
    -site      unithd

# -------------------------------------------------------------------------
# 4. ROUTING TRACKS
# -------------------------------------------------------------------------
make_tracks

# -------------------------------------------------------------------------
# 5. TAP CELLS
# -------------------------------------------------------------------------
# Pitch 8um (vs 10um area): shorter distance to Vdd/Vss taps lowers
# substrate resistance → better supply integrity → less leakage variation.
tapcell \
    -distance      8 \
    -tapcell_master  sky130_fd_sc_hd__tapvpwrvgnd_1 \
    -endcap_master   sky130_fd_sc_hd__decap_4

# -------------------------------------------------------------------------
# 6. REPORT
# -------------------------------------------------------------------------
puts "\[INFO\] Floorplan complete. Writing report..."

set rpt [open $REPORT_FILE w]
puts $rpt "===== Floorplan Report — Power Optimized ====="
puts $rpt "Die  Area         : 1600 x 1600 um"
puts $rpt "Core Area         : 1480 x 1480 um"
puts $rpt "Margins           : 60 um (power ring clearance)"
puts $rpt "Target Utilization: 50-55%"
puts $rpt "Tap Cell Pitch    : 8 um"
puts $rpt "Library Corner    : TT 025C 1v80"
puts $rpt "==============================================="
close $rpt

report_design_area
set rpt [open $REPORT_FILE a]
puts $rpt [report_design_area]
close $rpt

# -------------------------------------------------------------------------
# 7. SAVE DATABASE
# -------------------------------------------------------------------------
puts "\[INFO\] Saving floorplan database: $DB_FLOORPLAN"
write_db $DB_FLOORPLAN

puts "\[SUCCESS\] Floorplanning Done!"
puts "\[INFO\]    Database : $DB_FLOORPLAN"
puts "\[INFO\]    Report   : $REPORT_FILE"