#aes_openroad.tcl
#!/usr/bin/env openroad

set_thread_count 7

set PDK_ROOT "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af"
set PDK "sky130A"
set LIB "sky130_fd_sc_hd"

set TECH_LEF "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef"
set SC_LEF "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef"
set LIB_FILE "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"

puts "AES-128 Macro Hardening"
puts "Target: 100 MHz (10ns period)"

# Stage 1: Read Design
puts "\n--- Reading AES netlist ---"
read_lef $TECH_LEF
read_lef $SC_LEF
read_liberty $LIB_FILE
read_verilog aes_synth.v
link_design aes

puts "✓ AES netlist loaded"

# Stage 2: Timing Constraints (for AES)
puts "\n--- Setting timing constraints ---"
# AES target: 100 MHz = 10ns period
read_sdc aes_sdc.sdc
puts "✓ Timing constraints set from aes_sdc.sdc"


# Stage 3: Estimate AES Size

puts "\n--- Estimating macro size ---"
set aes_area [expr {169608 * 1.1}]
puts "AES cell area: $aes_area µm²"

set core_area [expr {$aes_area *3.1}]
set core_side [expr {sqrt($core_area)}]

# Round up to nearest 50µm
set core_side [expr {int($core_side + 49)}]
puts "Target core: ${core_side}µm x ${core_side}µm"

# Add 75µm margin for pins and power ring
set die_side [expr {$core_side + 75}]
puts "Target die: ${die_side}µm x ${die_side}µm"

# Stage 4: Floorplan

puts "\n--- Creating floorplan ---"
initialize_floorplan -die_area "0 0 $die_side $die_side" -core_area "75 75 $core_side $core_side" -site unithd

report_design_area
write_db aes_1_floorplan.odb

# Stage 5: Pin Placement (LEFT = Inputs, RIGHT = Outputs)

puts "\n--- Pin placement (Inputs LEFT, Outputs RIGHT) ---"

# Identify input and output ports
#set all_ports [get_ports *]
set input_pins {}
set output_pins {}

lappend input_pins cs we

for {set i 0} {$i < 32} {incr i} {lappend input_pins "write_data\[$i\]"}

for {set i 0} {$i < 32} {incr i} {lappend output_pins "read_data\[$i\]"}

puts "Found [llength $input_pins] input pins"
puts "Found [llength $output_pins] output pins"

# Control pins go on BOTTOM and TOP for easy access
set control_pins {clk reset_n}

# Generate routing tracks
make_tracks

# Set pin constraints
if {[llength $input_pins] > 0} {
    set_io_pin_constraint -pin_names $input_pins -region left:100-[expr {$die_side - 100}]
}

if {[llength $output_pins] > 0} {
    set_io_pin_constraint -pin_names $output_pins -region right:100-[expr {$die_side - 100}]
}

if {[llength $control_pins] > 0} {
    set_io_pin_constraint -pin_names $control_pins -region bottom:100-664
}

# Place pins
place_pins -hor_layers met3 -ver_layers met2

puts "✓ Pin placement complete"
write_db aes_2_pins.odb

# Stage 6: Power Delivery Network

puts "\n--- Power delivery network ---"
add_global_connection -net {VPWR} -inst_pattern {.*} -pin_pattern {^VPB$} -power
add_global_connection -net {VPWR} -inst_pattern {.*} -pin_pattern {^VPWR$} -power
add_global_connection -net {VGND} -inst_pattern {.*} -pin_pattern {^VNB$} -ground
add_global_connection -net {VGND} -inst_pattern {.*} -pin_pattern {^VGND$} -ground

set_voltage_domain -power VPWR -ground VGND
define_pdn_grid -name {grid} -voltage_domains {CORE}

# Standard cell rails
add_pdn_stripe -grid {grid} -layer {met1} -width {0.48} -pitch {2.72} -offset {0} -followpins

# Power straps (tighter pitch for macro)
add_pdn_stripe -grid {grid} -layer {met4} -width {1.6} -pitch {30.0} -offset {13.570}
add_pdn_stripe -grid {grid} -layer {met5} -width {1.6} -pitch {30.0} -offset {13.600}

# Power ring
add_pdn_ring -grid {grid} -layers {met4 met5} -widths {3.0 3.0} -spacings {2.0 2.0} -core_offsets {3.0 3.0}

add_pdn_connect -grid {grid} -layers {met1 met4}
add_pdn_connect -grid {grid} -layers {met4 met5}

pdngen
puts "✓ PDN complete"
write_db aes_3_pdn.odb


# Stage 7: Placement (Timing-Driven)


puts "\n--- Placement (timing-driven) ---"
insert_tiecells sky130_fd_sc_hd__conb_1/HI
# -prefix "TIEHI"
insert_tiecells sky130_fd_sc_hd__conb_1/LO
# -prefix "TIELO"
set_wire_rc -clock -layer met3
set_wire_rc -signal -layer met2

global_placement -density 0.35 -timing_driven
set_placement_padding -global -left 2 -right 2
detailed_placement
check_placement -verbose -report_file_name placement_report_before_cts.rpt
puts "✓ Placement complete"

report_design_area
write_db aes_4_placement.odb

set_dont_use sky130_fd_sc_hd__probe_p_8
set_dont_use sky130_fd_sc_hd__probec_p_8
set_dont_use sky130_fd_sc_hd__lpflow_*

#check if required here or not
repair_design -max_wire_length 3500
report_worst_slack -max
report_tns


# Stage 8: Clock Tree Synthesis


puts "\n--- Clock tree synthesis ---"


clock_tree_synthesis \
    -buf_list {sky130_fd_sc_hd__clkbuf_8 sky130_fd_sc_hd__clkbuf_4 sky130_fd_sc_hd__clkbuf_2} \
    -root_buf sky130_fd_sc_hd__clkbuf_8

set_propagated_clock [all_clocks]

repair_clock_nets -max_wire_length 3500

set_placement_padding -masters {sky130_fd_sc_hd__clkbuf_*} -left 4 -right 4

#check if needed or not
#ignore if not required
#repair_timing -setup -setup_margin 0.15 -max_passes 5
#repair_timing -hold -hold_margin 0.02 -max_buffer_percent 50
detailed_placement


puts "✓ CTS complete"
report_clock_skew
write_db aes_5_cts.odb
puts "\nChecking timing..."
report_worst_slack -max
report_worst_slack -min
report_tns


# Stage 10: Routing

puts "\n--- Global routing ---"

#set_pin_offset 10

global_route 
#-allow_congestion

global_route_debug -rst -saveSttInput stt_input.rpt -net clk

repair_antennas sky130_fd_sc_hd__diode_2

puts "✓ Global routing complete"

puts "\n--- Detailed routing ---"
detailed_route -output_drc aes_route_drc.rpt -bottom_routing_layer met1 -top_routing_layer met5 -verbose 1

puts "\n✓ Routing complete!"
write_db aes_6_routed.odb

# # Stage 11: Final Optimization


# puts "\n--- Post-route optimization ---"
# estimate_parasitics -global_routing

# #check if required or not
# #ignore if not required
# # Light final optimization
# repair_design -max_wire_length 300 
# repair_timing -setup -setup_margin 0.1
# repair_timing -hold -hold_margin 0.02

# detailed_placement
# write_db aes_7_route_opt.odb

# # Stage 12: Filler Cells

# puts "\n--- Filler cells ---"
# filler_placement sky130_fd_sc_hd__fill_*

# puts "✓ Fillers inserted"
# write_db aes_8_final.odb

# # Stage 13: Final Reports

# puts "GENERATING FINAL REPORTS"

# report_checks -path_delay max -format full_clock > aes_timing_setup.txt
# report_checks -path_delay min -format full_clock > aes_timing_hold.txt
# report_tns > aes_tns.txt
# report_wns > aes_wns.txt
# report_worst_slack -max > aes_slack.txt

# check_antennas -report_file aes_antenna.txt

# report_power > aes_power.txt
# report_design_area > aes_area.txt


# # Stage 14: Generate Outputs


# puts "\n--- Writing output files ---"
# write_def aes_macro.def
# write_lef aes_macro.lef

# puts "\n=========================================="
# puts "🎉 AES MACRO COMPLETE!"
# puts "=========================================="
# puts ""
# puts "Pin Configuration:"
# puts "  LEFT:   Input pins"
# puts "  RIGHT:  Output pins"
# puts "  BOTTOM: Control pins (clk, reset)"
# puts ""
# puts "Output Files:"
# puts "  📄 aes_macro.def (layout)"
# puts "  📄 aes_macro.lef (abstract)"
# puts "  📊 aes_timing_setup.txt"
# puts "  📊 aes_timing_hold.txt"
# puts "  📊 aes_wns.txt"
# puts "  📊 aes_power.txt"
# puts ""
# puts "Database Checkpoints:"
# puts "  aes_1_floorplan.odb → aes_8_final.odb"
# puts "=========================================="

# puts "\nFinal Timing:"
# report_worst_slack -max
# report_worst_slack -min
# report_tns

# puts "\nFinal Area:"
# report_design_area
