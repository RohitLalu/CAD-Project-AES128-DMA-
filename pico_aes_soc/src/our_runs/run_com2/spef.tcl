set PDK_ROOT "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af"
set RUNDIR   "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com"

# Read SDC for timing constraints
read_sdc $RUNDIR/picosoc_aes.sdc

puts "\n--- Setting wire RC models ---"
set_wire_rc -signal -layer met2
set_wire_rc -clock  -layer met3

puts "\n--- Estimating parasitics from placement ---"
estimate_parasitics -placement
puts "✓ Parasitic estimation complete"

puts "\n--- Writing SPEF ---"
write_spef $RUNDIR/picosoc_aes_combined.spef
puts "✓ SPEF written"

puts "\n--- Timing summary ---"
report_worst_slack -max
report_worst_slack -min
report_tns

puts "\n--- Writing timing reports ---"
report_checks -path_delay max -format full_clock_expanded \
    -no_line_split > $RUNDIR/timing_setup_spef.txt
report_checks -path_delay min -format full_clock_expanded \
    -no_line_split >> $RUNDIR/timing_setup_spef.txt
puts "✓ Timing reports → timing_setup_spef.txt"

puts "\n--- Power report ---"
set_propagated_clock [all_clocks]
report_power > $RUNDIR/power_spef.txt
puts "✓ Power report → power_spef.txt"

puts "\n--- Design area ---"
report_design_area > $RUNDIR/area_final.txt
puts "✓ Area report → area_final.txt"

puts "\n--- Writing DEF ---"
write_def $RUNDIR/picosoc_aes_combined.def
puts "✓ DEF written"

write_lib picosoc -output $RUNDIR/picosoc_aes_combined.lib
puts "✓ LIB written"

# Abstract LEF
write_abstract_lef -bloat_occupied_layers picosoc_aes_combined_abstract.lef
puts "✓ Abstract LEF written"

puts "\n=== Done with reports and def, lef and lib ==="

# GDS stream out (if KLayout is available via OpenROAD)
write_gds -merge $RUNDIR/sky130A.gds picosoc_aes_combined.gds