set PDK_ROOT "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af"
set RUNDIR   "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com2"

read_sdc $RUNDIR/picosoc_aes.sdc

puts "\n--- Setting wire RC models ---"
set_wire_rc -signal -layer met2
set_wire_rc -clock  -layer met3
estimate_parasitics -placement
puts "✓ Parasitics estimated"

puts "\n--- Timing summary ---"
set_propagated_clock [all_clocks]
report_worst_slack -max
report_worst_slack -min
report_tns

report_checks -path_delay max -format full_clock_expanded \
    -no_line_split > $RUNDIR/timing_setup_final.txt
report_checks -path_delay min -format full_clock_expanded \
    -no_line_split >> $RUNDIR/timing_setup_final.txt
report_check_types -max_slew -max_capacitance -max_fanout \
    -violators >> $RUNDIR/timing_setup_final.txt
puts "✓ Timing → timing_setup_final.txt"

puts "\n--- Power ---"
report_power > $RUNDIR/power_final.txt
puts "✓ Power → power_final.txt"

puts "\n--- Area ---"
report_design_area > $RUNDIR/area_final.txt
puts "✓ Area → area_final.txt"

puts "\n--- DEF ---"
write_def $RUNDIR/picosoc_aes_combined.def
puts "✓ DEF → picosoc_aes_combined.def"

puts "\n=== Complete ==="
