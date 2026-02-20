# #!/usr/bin/env openroad

# puts "\n--- Inserting tie cells for constants ---"

# # Insert tie cells for tie-high and tie-low
# # This replaces loose constant nets with proper cells
# insert_tiecells sky130_fd_sc_hd__conb_1

# puts "\n✓ Tie cells inserted"

# # Report what was done
# puts "\n--- Checking for remaining tie nets ---"

# set found_one 0
# set found_zero 0

# if {[catch {get_nets "one_"} result] == 0} {
#     puts "⚠️  Net 'one_' still exists"
#     set found_one 1
# } else {
#     puts "✓ No 'one_' net found"
# }

# if {[catch {get_nets "zero_"} result] == 0} {
#     puts "⚠️  Net 'zero_' still exists"
#     set found_zero 1
# } else {
#     puts "✓ No 'zero_' net found"
# }

# if {$found_one || $found_zero} {
#     puts "⚠️  Warning: Tie nets still present"
# } else {
#     puts "✓ Tie Cell Insertion Complete"
# }

puts "\n--- Inserting tie cells for constants ---"

# 1. Define the specific tie-high and tie-low cells + ports
set tie_high_cell "sky130_fd_sc_hd__conb_1"
set tie_high_port "HI"
set tie_low_cell  "sky130_fd_sc_hd__conb_1"
set tie_low_port  "LO"

# 2. Execute the insertion command
# This tells the tool: "Use this specific port on this specific cell"
insert_tiecells $tie_high_cell/$tie_high_port -prefix "TIEHI"
insert_tiecells $tie_low_cell/$tie_low_port   -prefix "TIELO"

puts "  ✓ Tie cells inserted using $tie_high_cell"
