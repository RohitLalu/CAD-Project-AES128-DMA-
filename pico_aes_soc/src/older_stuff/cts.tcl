
repair_clock_nets


report_checks -path_delay max
report_checks -path_delay min

filler_placement "sky130_fd_sc_hd__fill_*"

puts "CTS and Filler Placement Complete!"
