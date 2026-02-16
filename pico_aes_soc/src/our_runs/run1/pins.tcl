# #!/usr/bin/env openroad

# # STAGE 3: Pin Placement
# # WEST (left) - Control
# set west_pins {clk resetn iomem_ready ser_rx irq_5 irq_6 irq_7}

# # EAST (right) - Control outputs
# set east_pins {iomem_valid ser_tx flash_csb flash_clk}

# # NORTH (top) - Input data
# set north_pins {}
# for {set i 0} {$i < 32} {incr i} {
#     lappend north_pins "iomem_rdata\[$i\]"
# }
# lappend north_pins "flash_io0_di" "flash_io1_di" "flash_io2_di" "flash_io3_di"

# # SOUTH (bottom) - Output data
# set south_pins {}
# for {set i 0} {$i < 4} {incr i} {
#     lappend south_pins "iomem_wstrb\[$i\]"
# }
# for {set i 0} {$i < 32} {incr i} {
#     lappend south_pins "iomem_addr\[$i\]"
#     lappend south_pins "iomem_wdata\[$i\]"
# }
# for {set i 0} {$i < 4} {incr i} {
#     lappend south_pins "flash_io${i}_oe" "flash_io${i}_do"
# }

# set_io_pin_constraint -direction left   -pin_names $west_pins
# set_io_pin_constraint -direction right  -pin_names $east_pins
# set_io_pin_constraint -direction top    -pin_names $north_pins
# set_io_pin_constraint -direction bottom -pin_names $south_pins

# make_tracks
# place_pins -hor_layers met3 -ver_layers met2

# puts "✓ Pins placed on all 4 edges"






puts "Pin Placement - PicoSoC AES"

# WEST (Left) - Control Signals
set west_pins {
    clk
    resetn
    iomem_ready
    ser_rx
    irq_5
    irq_6
    irq_7
}

# EAST (Right) - Control Outputs
set east_pins {
    iomem_valid
    ser_tx
    flash_csb
    flash_clk
}

# NORTH (Top) - Input Data Buses
set north_pins {}

# Input data bus
for {set i 0} {$i < 32} {incr i} {
    lappend north_pins "iomem_rdata\[$i\]"
}

# Flash input data
lappend north_pins "flash_io0_di"
lappend north_pins "flash_io1_di"
lappend north_pins "flash_io2_di"
lappend north_pins "flash_io3_di"

# SOUTH (Bottom) - Output Data Buses
set south_pins {}

# Write strobe
for {set i 0} {$i < 4} {incr i} {
    lappend south_pins "iomem_wstrb\[$i\]"
}

# Address bus
for {set i 0} {$i < 32} {incr i} {
    lappend south_pins "iomem_addr\[$i\]"
}

# Write data bus
for {set i 0} {$i < 32} {incr i} {
    lappend south_pins "iomem_wdata\[$i\]"
}

# Flash outputs
lappend south_pins "flash_io0_oe"
lappend south_pins "flash_io1_oe"
lappend south_pins "flash_io2_oe"
lappend south_pins "flash_io3_oe"
lappend south_pins "flash_io0_do"
lappend south_pins "flash_io1_do"
lappend south_pins "flash_io2_do"
lappend south_pins "flash_io3_do"

# ========================================================================
# Summary
# ========================================================================
puts "\nPin distribution:"
puts "  WEST (left):   [llength $west_pins] pins"
puts "  EAST (right):  [llength $east_pins] pins"
puts "  NORTH (top):   [llength $north_pins] pins"
puts "  SOUTH (bottom): [llength $south_pins] pins"
set total_pins [expr {[llength $west_pins] + [llength $east_pins] + [llength $north_pins] + [llength $south_pins]}]
puts "  TOTAL:         $total_pins pins"

# Set Pin Constraints


set_io_pin_constraint -direction left   -pin_names $west_pins
set_io_pin_constraint -direction right  -pin_names $east_pins
set_io_pin_constraint -direction top    -pin_names $north_pins
set_io_pin_constraint -direction bottom -pin_names $south_pins

puts "✓ Pin constraints set for all 4 edges"

# Place Pins


# Generate routing tracks
make_tracks

# Place pins using constraints

place_pins -hor_layers met3 -ver_layers met2

puts "✓ Pins placed successfully"

