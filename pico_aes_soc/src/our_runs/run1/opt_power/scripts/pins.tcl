# ========================================================================
# OpenROAD Pin Placement Script — Power Optimized
# ========================================================================
# Target: Sky130 130nm | Step: 2 (Pin Placement)
# Power Changes vs Area:
#   - Pins placed on met3/met4 instead of met1/met2
#     → frees met1/met2 for local cell routing → router uses shorter
#       paths → less total wire length → lower switching capacitance
#   - Functional grouping preserved: clock/reset isolated on WEST
#     → keeps high-fanout nets short → less dynamic power on clk net
# ========================================================================

puts "\[INFO\] Starting Pin Placement (power optimized)..."

# -------------------------------------------------------------------------
# 1. SETUP & PATHS
# -------------------------------------------------------------------------
set PROJECT_ROOT "$env(HOME)/CAD-Project-AES128-DMA-/pico_aes_soc/src"
set OUTPUT_DIR   "$PROJECT_ROOT/our_runs/run1/opt_power/outputs"
set REPORT_FILE  "$OUTPUT_DIR/pins_report.txt"
set DB_FLOORPLAN "$OUTPUT_DIR/01_fp.odb"
set DB_PINS      "$OUTPUT_DIR/02_pins.odb"

# -------------------------------------------------------------------------
# 2. LOAD PREVIOUS STAGE
# -------------------------------------------------------------------------
puts "\[INFO\] Loading floorplan database..."
if {![file exists $DB_FLOORPLAN]} {
    puts "\[ERROR\] $DB_FLOORPLAN not found! Run floorplan step first."
    exit 1
}
read_db $DB_FLOORPLAN

# -------------------------------------------------------------------------
# 3. PIN ASSIGNMENT
# -------------------------------------------------------------------------

# --- WEST: Clock & Control Inputs ---
# Clock and reset isolated here — keeps high-fanout clock net entry point
# on one side, minimising H-tree wire length across the die → less clk power
set west_pins {
    clk
    resetn
    iomem_ready
    ser_rx
    irq_5
    irq_6
    irq_7
}

# --- EAST: Control Outputs ---
set east_pins {
    iomem_valid
    ser_tx
    flash_csb
    flash_clk
}

# --- NORTH: Input Data (iomem_rdata + flash_io_di) ---
set north_pins {}
for {set i 0} {$i < 32} {incr i} { lappend north_pins "iomem_rdata\[$i\]" }
for {set i 0} {$i < 4}  {incr i} { lappend north_pins "flash_io${i}_di"   }

# --- SOUTH: Output Data, Address, Flash (iomem_wstrb/addr/wdata + flash oe/do) ---
set south_pins {}
for {set i 0} {$i < 4}  {incr i} { lappend south_pins "iomem_wstrb\[$i\]"  }
for {set i 0} {$i < 32} {incr i} { lappend south_pins "iomem_addr\[$i\]"   }
for {set i 0} {$i < 32} {incr i} { lappend south_pins "iomem_wdata\[$i\]"  }
for {set i 0} {$i < 4}  {incr i} {
    lappend south_pins "flash_io${i}_oe"
    lappend south_pins "flash_io${i}_do"
}

# -------------------------------------------------------------------------
# 4. PIN COUNTS
# -------------------------------------------------------------------------
set count_w [llength $west_pins]
set count_e [llength $east_pins]
set count_n [llength $north_pins]
set count_s [llength $south_pins]
set total   [expr $count_w + $count_e + $count_n + $count_s]

puts "-------------------------------------"
puts " Pin Distribution:"
puts "  WEST  : $count_w"
puts "  EAST  : $count_e"
puts "  NORTH : $count_n"
puts "  SOUTH : $count_s"
puts "  TOTAL : $total"
puts "-------------------------------------"

# -------------------------------------------------------------------------
# 5. APPLY CONSTRAINTS & PLACE
# -------------------------------------------------------------------------
if {$count_w > 0} { set_io_pin_constraint -direction left   -pin_names $west_pins  }
if {$count_e > 0} { set_io_pin_constraint -direction right  -pin_names $east_pins  }
if {$count_n > 0} { set_io_pin_constraint -direction top    -pin_names $north_pins }
if {$count_s > 0} { set_io_pin_constraint -direction bottom -pin_names $south_pins }

# Power optimization: use met3/met4 for pins instead of met1/met2.
# Frees the lower metals for cell-local routing, allowing the global
# router to use shorter horizontal/vertical segments → less total wire
# capacitance → less dynamic power per switching event.
place_pins \
    -hor_layers met3 \
    -ver_layers met4

# -------------------------------------------------------------------------
# 6. REPORT
# -------------------------------------------------------------------------
puts "\[INFO\] Writing pin report..."
set rpt [open $REPORT_FILE w]
puts $rpt "===== Pin Placement Report — Power Optimized ====="
puts $rpt "WEST  : $count_w pins  (clk/reset isolated for short H-tree)"
puts $rpt "EAST  : $count_e pins"
puts $rpt "NORTH : $count_n pins"
puts $rpt "SOUTH : $count_s pins"
puts $rpt "TOTAL : $total pins"
puts $rpt "Pin Layers: hor=met3, ver=met4 (frees met1/2 for cell routing)"
puts $rpt "==================================================="
close $rpt

# -------------------------------------------------------------------------
# 7. SAVE DATABASE
# -------------------------------------------------------------------------
puts "\[INFO\] Saving: $DB_PINS"
write_db $DB_PINS

puts "\[SUCCESS\] Pin Placement Done!"
puts "\[INFO\]    Database : $DB_PINS"
puts "\[INFO\]    Report   : $REPORT_FILE"