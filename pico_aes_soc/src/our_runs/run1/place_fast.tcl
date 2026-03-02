#!/usr/bin/env openroad

# STAGE 5: Placement

# Global placement
global_placement -density 0.55 -overflow 0.10

# Insert tie cells between global and detailed placement.
# insert_tiecells stamps them as FIXED at the first available coordinates,
# which causes overlaps since those sites are already occupied.
# We must downgrade their status to PLACED so detailed_placement can
# move them to legal non-overlapping locations.
puts "\n--- Inserting tie cells for constants ---"
insert_tiecells sky130_fd_sc_hd__conb_1/HI 
#-prefix "TIEHI"
insert_tiecells sky130_fd_sc_hd__conb_1/LO 
#-prefix "TIELO"
puts "  ✓ Tie cells inserted"

# Downgrade tie cell status from FIXED -> PLACED so detailed_placement
# can legally relocate them to non-overlapping sites
puts "INFO: Unlocking tie cells for legalization..."
set block [ord::get_db_block]
foreach inst [$block getInsts] {
    set name [$inst getName]
    if {[string match "TIEHI*" $name] || [string match "TIELO*" $name]} {
        $inst setPlacementStatus "PLACED"
        puts "  Unlocked: $name (was FIXED, now PLACED)"
    }
}

# Detailed placement now legalizes all cells including tie cells
set_placement_padding -global -left 0 -right 0
detailed_placement

check_placement -verbose -report_file_name placement_check_faster.rpt