# ========================================================================
# OpenROAD Pin Placement Script for PicoSoC AES
# ========================================================================
# Usage: source pins.tcl
# Pre-req: Floorplan must be initialized (01_floorplan.odb)
# ========================================================================

puts "\[INFO\] Starting Pin Placement..."

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

set DB_FLOORPLAN "${RESULTS_DIR}/01_floorplan.odb"
set DB_PINS "${RESULTS_DIR}/02_pins.odb"

# -------------------------------------------------------------------------
# 2. LOAD PREVIOUS STAGE DATABASE
# -------------------------------------------------------------------------
puts "\[INFO\] Loading floorplan database from: $DB_FLOORPLAN"
if {![file exists $DB_FLOORPLAN]} {
    puts "\[ERROR\] Floorplan database not found: $DB_FLOORPLAN"
    puts "\[ERROR\] Please run floorplanning step first (fp.tcl)"
    exit 1
}
read_db $DB_FLOORPLAN

# -------------------------------------------------------------------------
# 3. Define Pin Lists (Side by Side)
# -------------------------------------------------------------------------

# --- WEST (Left): Control Inputs ---
set west_pins {
    clk
    resetn
    iomem_ready
    ser_rx
    irq_5
    irq_6
    irq_7
}

# --- EAST (Right): Control Outputs ---
set east_pins {
    iomem_valid
    ser_tx
    flash_csb
    flash_clk
}

# --- NORTH (Top): Input Data ---
set north_pins {}

# Add iomem_rdata [0..31]
for {set i 0} {$i < 32} {incr i} {
    lappend north_pins "iomem_rdata\[$i\]"
}

# Add flash_io_di [0..3]
for {set i 0} {$i < 4} {incr i} {
    lappend north_pins "flash_io${i}_di"
}

# --- SOUTH (Bottom): Output Data & Address ---
set south_pins {}

# Add iomem_wstrb [0..3]
for {set i 0} {$i < 4} {incr i} {
    lappend south_pins "iomem_wstrb\[$i\]"
}

# Add iomem_addr [0..31]
for {set i 0} {$i < 32} {incr i} {
    lappend south_pins "iomem_addr\[$i\]"
}

# Add iomem_wdata [0..31]
for {set i 0} {$i < 32} {incr i} {
    lappend south_pins "iomem_wdata\[$i\]"
}

# Add flash outputs (OE and DO) [0..3]
for {set i 0} {$i < 4} {incr i} {
    lappend south_pins "flash_io${i}_oe"
    lappend south_pins "flash_io${i}_do"
}

# -------------------------------------------------------------------------
# 4. Report Pin Counts
# -------------------------------------------------------------------------
set count_w [llength $west_pins]
set count_e [llength $east_pins]
set count_n [llength $north_pins]
set count_s [llength $south_pins]
set total   [expr $count_w + $count_e + $count_n + $count_s]

puts "-------------------------------------"
puts " Pin Distribution Summary:"
puts "  WEST  (Left)   : $count_w"
puts "  EAST  (Right)  : $count_e"
puts "  NORTH (Top)    : $count_n"
puts "  SOUTH (Bottom) : $count_s"
puts "  TOTAL          : $total"
puts "-------------------------------------"

# -------------------------------------------------------------------------
# 5. Apply Constraints & Place
# -------------------------------------------------------------------------

# Assign pins to specific edges
# Note: Ensure the variable lists are not empty before assigning
if {$count_w > 0} { set_io_pin_constraint -direction left   -pin_names $west_pins }
if {$count_e > 0} { set_io_pin_constraint -direction right  -pin_names $east_pins }
if {$count_n > 0} { set_io_pin_constraint -direction top    -pin_names $north_pins }
if {$count_s > 0} { set_io_pin_constraint -direction bottom -pin_names $south_pins }

# Ensure routing tracks exist (Critical for pin snapping)
make_tracks

# Run Placement
# Uses Metal 3 for horizontal pins (Top/Bottom)
# Uses Metal 2 for vertical pins (Left/Right)
place_pins -hor_layers met3 -ver_layers met2

puts "\[SUCCESS\] Pin placement complete."

# -------------------------------------------------------------------------
# 6. SAVE INTERMEDIATE DATABASE
# -------------------------------------------------------------------------
puts "\[INFO\] Saving pin placement database to: $DB_PINS"
write_db $DB_PINS

puts "\[INFO\] Pin placement step completed successfully!"