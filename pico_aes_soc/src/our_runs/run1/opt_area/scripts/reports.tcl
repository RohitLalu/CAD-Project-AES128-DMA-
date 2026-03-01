# Timing reports
puts "Generating timing reports..."
report_checks -path_delay max -format full_clock > timing_report.txt
report_tns > tns_report.txt  
report_wns > wns_report.txt

# Power report
puts "Generating power report..."
report_power > power_report.txt

# Write outputs
puts "Writing DEF..."
write_def picosoc_aes_final.def

puts "Writing GDS..."
set GDS_FILES "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/gds/sky130_fd_sc_hd.gds"
write_gds -lib_files $GDS_FILES picosoc_aes.gds

# Final statistics
report_design_area


puts " Physical Design Complete!"
