
set_thread_count 7

read_db aes_6_routed.odb

set PDK_ROOT "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af"
read_lef  ${PDK_ROOT}/sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef
read_lef  ${PDK_ROOT}/sky130A/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef
read_liberty ${PDK_ROOT}/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

set_wire_rc -clock -layer met3
set_wire_rc -signal -layer met2

set_dont_use sky130_fd_sc_hd__probe_p_8
set_dont_use sky130_fd_sc_hd__probec_p_8
set_dont_use sky130_fd_sc_hd__lpflow_*

estimate_parasitics -global_routing
write_timing_model aes_macro.lib

#repair_design -max_wire_length 3500
repair_antennas sky130_fd_sc_hd__diode_2
repair_timing -setup -setup_margin 0.15 -max_passes 5
repair_timing -hold -hold_margin 0.02 -max_buffer_percent 50

detailed_placement

#Re-route any cells inserted by repair_design/repair_timing
global_route
detailed_route -output_drc aes_route_opt_drc.rpt \
    -bottom_routing_layer met1 -top_routing_layer met5 -verbose 1

write_db aes_7_route_opt.odb

# Stage 12: Filler Cells

puts "\n--- Filler cells ---"
filler_placement sky130_fd_sc_hd__fill_*
detailed_placement

puts "✓ Fillers inserted"
write_db aes_8_final.odb

# Stage 13: Final Reports

puts "GENERATING FINAL REPORTS"

report_checks -path_delay max -format full_clock > aes_timing_setup.txt
report_checks -path_delay min -format full_clock > aes_timing_hold.txt
report_tns > aes_tns.txt
report_wns > aes_wns.txt
report_worst_slack -max > aes_slack.txt

check_antennas -report_file aes_antenna.txt

report_power > aes_power.txt
report_design_area > aes_area.txt


# Stage 14: Generate Outputs


puts "\n--- Writing output files ---"
write_def aes_macro.def
write_lef aes_macro.lef

puts "\n=========================================="
puts "🎉 AES MACRO COMPLETE!"
puts "=========================================="
puts ""
puts "Pin Configuration:"
puts "  LEFT:   Input pins"
puts "  RIGHT:  Output pins"
puts "  BOTTOM: Control pins (clk, reset)"
puts ""
puts "Output Files:"
puts "  📄 aes_macro.def (layout)"
puts "  📄 aes_macro.lef (abstract)"
puts "  📊 aes_timing_setup.txt"
puts "  📊 aes_timing_hold.txt"
puts "  📊 aes_wns.txt"
puts "  📊 aes_power.txt"
puts ""
puts "Database Checkpoints:"
puts "  aes_1_floorplan.odb → aes_8_final.odb"
puts "=========================================="

puts "\nFinal Timing:"
report_worst_slack -max
report_worst_slack -min
report_tns

puts "\nFinal Area:"
report_design_area
