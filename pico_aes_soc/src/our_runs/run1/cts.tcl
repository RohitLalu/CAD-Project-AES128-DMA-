#!/usr/bin/env openroad

# STAGE 6: Clock Tree Synthesis

puts "Reading timing constraints..."
if {[file exists "picosoc_aes.sdc"]} {
    read_sdc picosoc_aes.sdc
} else {
    puts "WARNING: SDC file not found, using default constraints"
    create_clock -name clk -period 25.0 [get_ports {clk}]
}

set_wire_rc -clock -layer met3
set_wire_rc -signal -layer met2

clock_tree_synthesis -buf_list {sky130_fd_sc_hd__clkbuf_8 sky130_fd_sc_hd__clkbuf_4 sky130_fd_sc_hd__clkbuf_2}

report_clock_skew

# Post-CTS detailed placement to legalize newly inserted CTS buffers.
# Tie cells were already placed and legalized in place.tcl, so no
# unplaced cell handling is needed here.
set_placement_padding -global -left 0 -right 0
detailed_placement

check_placement -verbose -report_file_name cts_place_check.rpt