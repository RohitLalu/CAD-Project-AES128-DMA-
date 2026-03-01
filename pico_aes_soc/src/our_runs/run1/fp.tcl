# ========================================================================
# OpenROAD Floorplanning Script for PicoSoC
# ========================================================================
# Target: Sky130 130nm
# Step: 1 (Floorplanning)
# ========================================================================

# -------------------------------------------------------------------------
# 1. SETUP & PATHS
# -------------------------------------------------------------------------
puts "\[INFO\] Setting up environment..."

# Use environment variable for HOME to make it portable
set PDK_ROOT "$env(HOME)/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af"
set PDK "sky130A"
set STD_CELL_LIB "sky130_fd_sc_hd"

# Define Reference File Paths
set TECH_LEF "${PDK_ROOT}/${PDK}/libs.ref/${STD_CELL_LIB}/techlef/${STD_CELL_LIB}__nom.tlef"
set SC_LEF   "${PDK_ROOT}/${PDK}/libs.ref/${STD_CELL_LIB}/lef/${STD_CELL_LIB}.lef"
set LIB_FILE "${PDK_ROOT}/${PDK}/libs.ref/${STD_CELL_LIB}/lib/${STD_CELL_LIB}__tt_025C_1v80.lib"

# Define Output Paths
set RESULTS_DIR "results"
set LOGS_DIR "logs"

# Create output directories if they don't exist
if {![file exists $RESULTS_DIR]} {
    file mkdir $RESULTS_DIR
}
if {![file exists $LOGS_DIR]} {
    file mkdir $LOGS_DIR
}

set DB_FLOORPLAN "${RESULTS_DIR}/01_floorplan.odb"

# -------------------------------------------------------------------------
# 2. READ DESIGN
# -------------------------------------------------------------------------
puts "\[INFO\] Reading design files..."

# Read Physical Rules (LEF)
read_lef $TECH_LEF
read_lef $SC_LEF

# Read Timing Rules (Liberty)
read_liberty $LIB_FILE

# Read Synthesized Verilog (Output from Yosys)
# Make sure this file exists in your current directory!
if {[file exists picosoc_aes_sram.v]} {
    read_verilog picosoc_aes_sram.v
} else {
    puts "\[ERROR\] picosoc_aes_sram.v not found! Did synthesis finish?"
    exit 1
}

# Link the Design (Top module name matches Yosys script)
link_design picosoc

# -------------------------------------------------------------------------
# 3. FLOORPLANNING
# -------------------------------------------------------------------------
puts "\[INFO\] Stage 1: Floorplanning"

# Die Size Calculation:
# Target: ~1100um x 1100um Die
# Core:   ~1000um x 1000um (Leaving 50um margins for power rings/IO)

initialize_floorplan \
    -die_area {0 0 1100 1100} \
    -core_area {50 50 1050 1050} \
    -site unithd

# CRITICAL: Create Routing Tracks
# The router needs a grid to snap wires to.
make_tracks

# Insert Tap Cells
# Essential for Sky130 to prevent latch-up (connects substrate to power/ground)
tapcell \
  -distance 14 \
  -tapcell_master sky130_fd_sc_hd__tapvpwrvgnd_1 \
  -endcap_master sky130_fd_sc_hd__decap_4

# -------------------------------------------------------------------------
# 4. REPORTING
# -------------------------------------------------------------------------
puts "\[INFO\] Floorplan Complete."
report_design_area

# -------------------------------------------------------------------------
# 5. SAVE INTERMEDIATE DATABASE
# -------------------------------------------------------------------------
puts "\[INFO\] Saving floorplan database to: $DB_FLOORPLAN"
write_db $DB_FLOORPLAN

puts "\[INFO\] Floorplanning step completed successfully!"