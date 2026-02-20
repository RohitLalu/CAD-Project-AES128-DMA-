#!/usr/bin/env openroad

# STAGE 6: Clock Tree Synthesis

puts "Reading timing constraints..."
if {[file exists "picosoc_aes.sdc"]} {
    read_sdc picosoc_aes.sdc
} else {
    puts "WARNING: SDC file not found, using default constraints"
    create_clock -name clk -period 25.0 [get_ports {clk}]
}

clock_tree_synthesis -buf_list {sky130_fd_sc_hd__clkbuf_8 sky130_fd_sc_hd__clkbuf_4 sky130_fd_sc_hd__clkbuf_2}

report_clock_skew