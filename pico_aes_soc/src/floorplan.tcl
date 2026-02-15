#!/usr/bin/env openroad

puts "=========================================="
puts "PicoSoC Physical Design with OpenROAD"
puts "Target: Sky130 130nm, 40 MHz"
puts "=========================================="
puts ""

set PDK_ROOT "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af"
set PDK "sky130A"
set STD_CELL_LIB "sky130_fd_sc_hd"

set TECH_LEF "${PDK_ROOT}/${PDK}/libs.ref/${STD_CELL_LIB}/techlef/${STD_CELL_LIB}__nom.tlef"
# or use
#set TECH_LEF "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef"
set SC_LEF "${PDK_ROOT}/${PDK}/libs.ref/${STD_CELL_LIB}/lef/${STD_CELL_LIB}.lef"
#or use
#set SC_LEF "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef"
set LIB_FILE "${PDK_ROOT}/${PDK}/libs.ref/${STD_CELL_LIB}/lib/${STD_CELL_LIB}__tt_025C_1v80.lib"
#or use
#set LIB_FILE "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"


# Design files (in current directory)
set VERILOG_FILE "picosoc_synth.v"
set SDC_FILE "picosoc.sdc"

puts "PDK: ${PDK}"
puts "Library: ${STD_CELL_LIB}"
puts ""

# STAGE 1: Read Design and Libraries

puts "\n--- Reading LEF files (physical technology) ---"
# Technology LEF: metal layers, vias, design rules
read_lef $TECH_LEF

# Standard cell LEF: physical layout of each cell
read_lef $SC_LEF

puts "\n--- Reading Liberty file (timing) ---"
# Liberty: timing, power, area information
read_liberty $LIB_FILE

puts "\n--- Reading Verilog netlist ---"
# Synthesized gate-level netlist
read_verilog $VERILOG_FILE

puts "\n--- Linking design ---"
# Link the design (connect all modules)
link_design picosoc

puts "\nDesign successfully read and linked!"
puts "Cells: [llength [get_cells *]]"
puts "Nets: [llength [get_nets *]]"
puts "Pins: [llength [get_pins *]]"



puts "\n=========================================="
puts "STAGE 2: Floorplanning"
puts "=========================================="

puts "\n--- Initializing floorplan ---"
# Die area: 980µm x 980µm
# Core area: 880µm x 880µm (50µm offset for power ring)
# Core utilization: ~63%

# Initialize floorplan
# Format: die_area x1 y1 x2 y2, core_area x1 y1 x2 y2, site_name
initialize_floorplan -die_area {0 0 980 980} -core_area {50 50 880 880} -site unithd



puts "\n--- Floorplan created ---"
puts "Die area: [ord::get_die_area]"
puts "Core area: [ord::get_core_area]"

# Report design area
report_design_area

puts "\n--- NOTE: At this point you could ---"


##########
#########
#####. PLEASE NOTE THIS: ADD MACRO FOR SRAM

# (base) hello.welcometothisdevice@Rohits-MacBook-Pro libs.ref % cd sky130_sram_macros 
# (base) hello.welcometothisdevice@Rohits-MacBook-Pro sky130_sram_macros % pwd
# /Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_sram_macros
# (base) hello.welcometothisdevice@Rohits-MacBook-Pro sky130_sram_macros % ls
# gds	lef	lib	mag	maglef	spice	verilog

######
########
##########

# puts "  - Place macros (if you had SRAM macros)"
# puts "  - Create pin placement"
# puts "  - Add placement blockages"
# puts "  - We'll do auto pin placement for now"

# STAGE 3: Pin Placement

puts "\n=========================================="
puts "STAGE 3: I/O Pin Placement"
puts "=========================================="

# ## Check pin_cfg.tcl for manual pin assignment based on picosoc.v
# source pin_cfg.tcl

# puts "I/O pins placed!"

# # Optional: View pin report
# report_checks -unconstrained

# # STAGE 4: Power Distribution Network (PDN)

# puts "\n=========================================="
# puts "STAGE 4: Power Delivery Network"
# puts "=========================================="

# puts "\n--- Creating power grid ---"
# # This creates the power straps and rings

# # For now, we'll use a simple PDN
# # In production, you'd source a PDN config file

# # Define power/ground nets
# set ::power_net "VPWR"
# set ::ground_net "VGND"

# # Add power straps (simplified version)
# # met1 rails for standard cells
# # met4/met5 straps for power distribution

# puts "Power grid configuration:"
# puts "  - met1 rails for standard cells"
# puts "  - met4/met5 straps for distribution"
# puts "  - Power ring around core"

# # Note: Full PDN generation requires more detailed config
# # For learning, we'll note this step and continue

# puts "\nPDN creation noted (would be done here in full flow)"

# puts "\n=========================================="
# puts "Ready for STAGE 5: Placement"
# puts "=========================================="
# puts ""
# puts "At this point, we've:"
# puts "  ✓ Read all design files"
# puts "  ✓ Created floorplan (940µm x 940µm)"
# puts "  ✓ Placed I/O pins"
# puts "  ✓ Prepared for power grid"
# puts ""
# puts "Next steps (manual execution recommended):"
# puts "  1. Global placement"
# puts "  2. Detailed placement"
# puts "  3. Clock tree synthesis"
# puts "  4. Routing"
# puts "  5. Finishing"
# puts ""
# puts "To continue interactively, run OpenROAD shell"
# puts "and execute placement commands manually."
# puts "=========================================="
