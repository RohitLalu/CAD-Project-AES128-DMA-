#!/usr/bin/env openroad
# ========================================================================
# OpenROAD Interactive Learning Script for PicoSoC
# ========================================================================
# This script takes you through each step of physical design
# Run sections interactively to understand each phase
# ========================================================================

puts "=========================================="
puts "PicoSoC Physical Design with OpenROAD"
puts "Target: Sky130 130nm, 40 MHz"
puts "=========================================="
puts ""

# ========================================================================
# Setup and Configuration
# ========================================================================
puts "Setting up design paths..."

# PDK configuration
set PDK_ROOT "$env(HOME)/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af"
set PDK "sky130A"
set STD_CELL_LIB "sky130_fd_sc_hd"

# File paths
set TECH_LEF "${PDK_ROOT}/${PDK}/libs.ref/${STD_CELL_LIB}/techlef/${STD_CELL_LIB}__nom.tlef"
set SC_LEF "${PDK_ROOT}/${PDK}/libs.ref/${STD_CELL_LIB}/lef/${STD_CELL_LIB}.lef"
set LIB_FILE "${PDK_ROOT}/${PDK}/libs.ref/${STD_CELL_LIB}/lib/${STD_CELL_LIB}__tt_025C_1v80.lib"

# Design files (in current directory)
set VERILOG_FILE "picosoc_synth.v"
set SDC_FILE "picosoc.sdc"

puts "PDK: ${PDK}"
puts "Library: ${STD_CELL_LIB}"
puts ""

# ========================================================================
# STAGE 1: Read Design and Libraries
# ========================================================================
puts "=========================================="
puts "STAGE 1: Reading Design Files"
puts "=========================================="

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

# ========================================================================
# STAGE 2: Floorplanning
# ========================================================================
puts "\n=========================================="
puts "STAGE 2: Floorplanning"
puts "=========================================="

puts "\n--- Initializing floorplan ---"
# Die area: 800µm x 800µm
# Core area: 780µm x 780µm (20µm offset for power ring)
# Core utilization: ~65%

# Initialize floorplan
# Format: die_area x1 y1 x2 y2, core_area x1 y1 x2 y2, site_name
initialize_floorplan \
    -die_area {0 0 800 800} \
    -core_area {20 20 780 780} \
    -site unithd

puts "\n--- Floorplan created ---"
puts "Die area: [ord::get_die_area]"
puts "Core area: [ord::get_core_area]"

# Report design area
report_design_area

puts "\n--- NOTE: At this point you could ---"
puts "  - Place macros (if you had SRAM macros)"
puts "  - Create pin placement"
puts "  - Add placement blockages"
puts "  - We'll do auto pin placement for now"

# ========================================================================
# STAGE 3: Pin Placement
# ========================================================================
puts "\n=========================================="
puts "STAGE 3: I/O Pin Placement"
puts "=========================================="

puts "\n--- Auto-placing I/O pins ---"
# Automatically place I/O pins around the die perimeter
# You can also manually place specific pins if needed

# Auto pin placement
auto_place_pins \
    -layer met3 \
    -width 0.5 \
    -height 0.5

puts "I/O pins placed!"

# Optional: View pin report
# report_checks -unconstrained

# ========================================================================
# STAGE 4: Power Distribution Network (PDN)
# ========================================================================
puts "\n=========================================="
puts "STAGE 4: Power Delivery Network"
puts "=========================================="

puts "\n--- Creating power grid ---"
# This creates the power straps and rings

# For now, we'll use a simple PDN
# In production, you'd source a PDN config file

# Define power/ground nets
set ::power_net "VPWR"
set ::ground_net "VGND"

# Add power straps (simplified version)
# met1 rails for standard cells
# met4/met5 straps for power distribution

puts "Power grid configuration:"
puts "  - met1 rails for standard cells"
puts "  - met4/met5 straps for distribution"
puts "  - Power ring around core"

# Note: Full PDN generation requires more detailed config
# For learning, we'll note this step and continue

puts "\nPDN creation noted (would be done here in full flow)"

# ========================================
puts "\n=========================================="
puts "Ready for STAGE 5: Placement"
puts "=========================================="
puts ""
puts "At this point, we've:"
puts "  ✓ Read all design files"
puts "  ✓ Created floorplan (800µm x 800µm)"
puts "  ✓ Placed I/O pins"
puts "  ✓ Prepared for power grid"
puts ""
puts "Next steps (manual execution recommended):"
puts "  1. Global placement"
puts "  2. Detailed placement"
puts "  3. Clock tree synthesis"
puts "  4. Routing"
puts "  5. Finishing"
puts ""
puts "To continue interactively, run OpenROAD shell"
puts "and execute placement commands manually."
puts "=========================================="
