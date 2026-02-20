# # #!/usr/bin/env openroad

# # # STAGE 7: Routing

global_route

detailed_route




# #!/usr/bin/env openroad

# # ========================================================================
# # STAGE 7 & 8: Routing (with tie net handling)
# # ========================================================================

# puts "\n--- Identifying tie nets ---"

# # Get list of all nets
# set all_nets [get_nets *]
# set tie_nets {}

# # Look for nets with "one" or "zero" in the name
# # These are typically tie-high/tie-low nets
# foreach net [get_nets *] {
#     set net_name [get_property $net name]
#     if {[string match "*one*" $net_name] || [string match "*zero*" $net_name]} {
#         lappend tie_nets $net_name
#         puts "Found potential tie net: $net_name"
#     }
# }

# if {[llength $tie_nets] > 0} {
#     puts "\nFound [llength $tie_nets] tie net(s)"
#     puts "Router will be configured to handle these"
# } else {
#     puts "No tie nets found"
# }

# # Run global routing with verbose output
# global_route -verbose 1

# puts "\n✓ Global routing complete!"

# # The key fix: Use -db_process_node to handle tie nets properly
# # Also use -disable_via_gen to avoid issues with tie nets

# detailed_route \
#     -output_drc route_drc.rpt \
#     -output_maze route_maze.log \
#     -verbose 1 \
#     -bottom_routing_layer met1 \
#     -top_routing_layer met5

# puts "\n✓ Detailed routing complete!"

# # Check for DRC violations
# if {[file exists "route_drc.rpt"]} {
#     set drc_file [open "route_drc.rpt" r]
#     set drc_content [read $drc_file]
#     close $drc_file
    
#     set drc_lines [split $drc_content "\n"]
#     set violation_count [llength $drc_lines]
    
#     if {$violation_count > 1} {
#         puts "⚠️  DRC violations: $violation_count (see route_drc.rpt)"
#     } else {
#         puts "✓ No DRC violations!"
#     }
# }

# # Timing report
# report_checks -path_delay max > timing_post_route.txt
# puts "Timing report: timing_post_route.txt"