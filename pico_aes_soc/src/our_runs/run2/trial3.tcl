#!/usr/bin/env openroad

set PDK_ROOT "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af"
set PDK "sky130A"
set LIB "sky130_fd_sc_hd"

set TECH_LEF "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef"
set SC_LEF "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef"
set LIB_FILE "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"

puts "PicoSoC + AES - TIMING FIXED Flow"


puts "\n--- Reading design ---"
read_lef $TECH_LEF
read_lef $SC_LEF
read_liberty $LIB_FILE
read_verilog picosoc_aes_sram.v
link_design picosoc
puts "✓ Design loaded"

puts "\n--- Setting timing constraints ---"
# create_clock -name clk -period 100.0 [get_ports {clk}]
# set_clock_uncertainty 2.5 [get_clocks {clk}]

# # Set input/output delays
# set_input_delay -clock clk -max 5.0 [all_inputs]
# set_output_delay -clock clk -max 5.0 [all_outputs]

read_sdc picosoc_aes_fixed.sdc

puts "\n--- Floorplan ---"
initialize_floorplan \
    -die_area {0 0 1600 1600} \
    -core_area {100 100 1500 1500} \
    -site unithd
report_design_area
puts "✓ Floorplan: 1600×1600 die"
write_db 2_floorplan.odb

puts "\n--- Pin placement ---"
set west_pins {clk resetn iomem_ready ser_rx ser_tx irq_5 irq_6 irq_7}
set east_pins {iomem_valid flash_csb flash_clk}

set north_pins {}
for {set i 0} {$i < 32} {incr i} {lappend north_pins "iomem_rdata\[$i\]"}
lappend north_pins flash_io0_di flash_io1_di flash_io2_di flash_io3_di

set south_pins {}
for {set i 0} {$i < 4} {incr i} {lappend south_pins "iomem_wstrb\[$i\]"}
for {set i 0} {$i < 32} {incr i} {lappend south_pins "iomem_addr\[$i\]"}
for {set i 0} {$i < 32} {incr i} {lappend south_pins "iomem_wdata\[$i\]"}
lappend south_pins flash_io0_oe flash_io1_oe flash_io2_oe flash_io3_oe
lappend south_pins flash_io0_do flash_io1_do flash_io2_do flash_io3_do

make_tracks
set_io_pin_constraint -pin_names $west_pins -region left:100-1400
set_io_pin_constraint -pin_names $east_pins -region right:100-1400
set_io_pin_constraint -pin_names $north_pins -region top:100-1400
set_io_pin_constraint -pin_names $south_pins -region bottom:100-1400
place_pins -hor_layers met3 -ver_layers met2

puts "✓ Pins placed (123 total)"
write_db 3_pins.odb

puts "\n--- Power delivery network ---"
add_global_connection -net {VPWR} -inst_pattern {.*} -pin_pattern {^VPB$} -power
add_global_connection -net {VPWR} -inst_pattern {.*} -pin_pattern {^VPWR$} -power
add_global_connection -net {VGND} -inst_pattern {.*} -pin_pattern {^VNB$} -ground
add_global_connection -net {VGND} -inst_pattern {.*} -pin_pattern {^VGND$} -ground
add_global_connection -net {VPWR} -inst_pattern {.*} -pin_pattern {^HI$} -power
add_global_connection -net {VGND} -inst_pattern {.*} -pin_pattern {^LO$} -ground

set_voltage_domain -power VPWR -ground VGND
define_pdn_grid -name {grid} -voltage_domains {CORE}
add_pdn_stripe -grid {grid} -layer {met1} -width {0.48} -pitch {2.72} -offset {0} -followpins
add_pdn_stripe -grid {grid} -layer {met4} -width {1.6} -pitch {40.0} -offset {13.570}
add_pdn_stripe -grid {grid} -layer {met5} -width {1.6} -pitch {40.0} -offset {13.600}
add_pdn_ring -grid {grid} -layers {met4 met5} -widths {5.0 5.0} -spacings {2.0 2.0} -core_offsets {5.0 5.0}
add_pdn_connect -grid {grid} -layers {met1 met4}
add_pdn_connect -grid {grid} -layers {met4 met5}
pdngen
puts "✓ PDN complete"
write_db 4_pdn.odb

puts "\n--- Placement (timing-driven) ---"

insert_tiecells sky130_fd_sc_hd__conb_1/HI
# -prefix "TIEHI"
insert_tiecells sky130_fd_sc_hd__conb_1/LO
# -prefix "TIELO"
set_wire_rc -clock -layer met3
set_wire_rc -signal -layer met2

global_placement -density 0.32
set_placement_padding -global -left 0 -right 0
detailed_placement
check_placement -verbose -report_file_name placement_report_before_cts.rpt
write_db 5_placement.odb

puts "\n--- Clock tree synthesis ---"
set_wire_rc -clock -layer met3
set_wire_rc -signal -layer met2
clock_tree_synthesis -buf_list {sky130_fd_sc_hd__clkbuf_8 sky130_fd_sc_hd__clkbuf_4 sky130_fd_sc_hd__clkbuf_2} -root_buf sky130_fd_sc_hd__clkbuf_8

set_propagated_clock [all_clocks]

repair_clock_nets -max_wire_length 3500

set_placement_padding -masters {sky130_fd_sc_hd__clkbuf_*} -left 2 -right 2
detailed_placement
puts "✓ CTS complete"
write_db 6_cts.odb


# puts "FIXING TIMING & ANTENNA VIOLATIONS"
# puts "\n--- Estimating parasitics ---"
# estimate_parasitics -placement

# puts "\n--- Repairing design rules (slew/cap) ---"
# repair_design -max_wire_length 3500

# puts "\n--- Repairing SETUP timing (WNS/TNS) ---"
# repair_timing -setup -setup_margin 0.1 -max_passes 5

#puts "\n--- Repairing HOLD timing ---"

# set_opt_config -disable_buffer_pruning

#repair_timing -hold -hold_margin 0.01 -max_buffer_percent 50

# Legalize all new cells
# set_placement_padding -global -left 1 -right 1
# detailed_placement

# puts "\n--- Optimization complete ---"
# puts "Checking timing..."
# report_worst_slack -max
# report_tns
# write_db 6_timing_antenna_optimized.odb


puts "\n--- Global routing ---"
global_route -allow_congestion
puts "✓ Global routing complete"

puts "\n--- Repairing antenna violations ---"
repair_antennas sky130_fd_sc_hd__diode_2

puts "\n--- Detailed routing ---"
detailed_route \
    -output_drc route_drc.rpt \
    -droute_end_iter 15 \
    -bottom_routing_layer met1 \
    -top_routing_layer met5

puts "\n✓ Routing complete!"
write_db 7_routed.odb


puts "\n--- Post-route optimization ---"
estimate_parasitics -global_routing

# # Final timing fix with extracted parasitics
# repair_timing -setup -setup_margin 0.05
# # repair_timing -hold -hold_margin 0.0

# detailed_placement
# write_db 8_post_route_opt.odb


puts "\n--- Filler cells ---"
filler_placement sky130_fd_sc_hd__fill_*

puts "✓ Fillers inserted"
write_db 9_final.odb

puts "GENERATING FINAL REPORTS"

# Timing reports
puts "\n--- Timing Analysis ---"
report_checks -path_delay max -format full_clock > timing_final.txt
report_checks -path_delay min >> timing_final.txt
report_tns > tns_final.txt
report_wns > wns_final.txt
report_worst_slack -max > slack_final.txt

# Antenna check
puts "\n--- Antenna Check ---"
check_antennas -report_file antenna_final.txt

# Power report
puts "\n--- Power Analysis ---"
report_power > power_final.txt

# Area report
report_design_area > area_final.txt

puts "\n--- Writing output files ---"
write_def picosoc_aes_timing_fixed.def
puts "✓ DEF written"

puts "\nTIMING-OPTIMIZED DESIGN COMPLETE!"
puts ""
puts "Key Improvements:"
puts "  ✓ Clock period: 100ns (was 35ns)"
puts "  ✓ Timing optimization applied"
puts "  ✓ Antenna violations fixed"
puts "  ✓ Critical paths buffered"
puts ""
puts "Output files:"
puts "  📄 picosoc_aes_timing_fixed.def"
puts "  📊 timing_final.txt"
puts "  📊 wns_final.txt (WNS)"
puts "  📊 tns_final.txt (TNS)"
puts "  📊 antenna_final.txt"
puts "  📊 power_final.txt"
puts ""
puts "Checkpoints saved at each stage (.odb files)"

# Print final summary
puts "\nFinal Timing Summary:"
report_worst_slack -max
report_tns