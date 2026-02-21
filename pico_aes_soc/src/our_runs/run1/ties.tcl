#!/usr/bin/env openroad

# puts "\n--- Inserting tie cells for constants ---"

# # 1. Define the specific tie-high and tie-low cells + ports
# set tie_high_cell "sky130_fd_sc_hd__conb_1"
# set tie_high_port "HI"
# set tie_low_cell  "sky130_fd_sc_hd__conb_1"
# set tie_low_port  "LO"

# # 2. Execute the insertion command
# # This tells the tool: "Use this specific port on this specific cell"
# insert_tiecells $tie_high_cell/$tie_high_port -prefix "TIEHI"
# insert_tiecells $tie_low_cell/$tie_low_port   -prefix "TIELO"

# puts "  ✓ Tie cells inserted using $tie_high_cell"

#!/usr/bin/env openroad

# NOTE: Tie cell insertion has been moved to place.tcl
# It must run BEFORE detailed_placement so the legalizer can assign
# non-overlapping sites. Running insert_tiecells after detailed_placement
# causes cells to land on already-occupied sites, failing check_placement.
puts "INFO: Tie cell insertion is handled in place.tcl (before detailed_placement)"