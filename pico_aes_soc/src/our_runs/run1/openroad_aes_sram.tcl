#!/usr/bin/env openroad

# Design: 55,508 cells, 0.57 mm² (cell area)
# Target: Sky130 @ 40 MHz


# Environment Setup
set PDK_ROOT "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af"
set PDK "sky130A"
set LIB "sky130_fd_sc_hd"

set TECH_LEF "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef"
set SC_LEF "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef"
set LIB_FILE "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"

# STAGE 1: Read Design


read_lef $TECH_LEF
read_lef $SC_LEF
read_liberty $LIB_FILE

read_verilog picosoc_aes_sram.v

link_design picosoc

# STAGE 2: Floorplan

# Die size calculation:
# Cell area: 570,135 µm²
# Target utilization: 65%
# Core area needed: 570,135 / 0.65 = 877,131 µm²
# Core side: √877,131 = 937 µm
# With margins: ~1070 µm × 1070 µm die

initialize_floorplan \
    -die_area {0 0 1070 1070} \
    -core_area {50 50 950 950} \
    -site unithd

report_design_area

puts "✓ Floorplan created"

# STAGE 3: Pin Placement
# WEST (left) - Control
set west_pins {clk resetn iomem_ready ser_rx irq_5 irq_6 irq_7}

# EAST (right) - Control outputs
set east_pins {iomem_valid ser_tx flash_csb flash_clk}

# NORTH (top) - Input data
set north_pins {}
for {set i 0} {$i < 32} {incr i} {
    lappend north_pins "iomem_rdata\[$i\]"
}
lappend north_pins "flash_io0_di" "flash_io1_di" "flash_io2_di" "flash_io3_di"

# SOUTH (bottom) - Output data
set south_pins {}
for {set i 0} {$i < 4} {incr i} {
    lappend south_pins "iomem_wstrb\[$i\]"
}
for {set i 0} {$i < 32} {incr i} {
    lappend south_pins "iomem_addr\[$i\]"
    lappend south_pins "iomem_wdata\[$i\]"
}
for {set i 0} {$i < 4} {incr i} {
    lappend south_pins "flash_io${i}_oe" "flash_io${i}_do"
}

set_io_pin_constraint -direction left   -pin_names $west_pins
set_io_pin_constraint -direction right  -pin_names $east_pins
set_io_pin_constraint -direction top    -pin_names $north_pins
set_io_pin_constraint -direction bottom -pin_names $south_pins

make_tracks
place_pins -hor_layers met3 -ver_layers met2

puts "✓ Pins placed on all 4 edges"

# STAGE 4: Power Delivery Network

add_global_connection -net {VPWR} -inst_pattern {.*} -pin_pattern {^VPB$} -power
add_global_connection -net {VPWR} -inst_pattern {.*} -pin_pattern {^VPWR$} -power
add_global_connection -net {VGND} -inst_pattern {.*} -pin_pattern {^VNB$} -ground
add_global_connection -net {VGND} -inst_pattern {.*} -pin_pattern {^VGND$} -ground
set_voltage_domain -power VPWR -ground VGND

define_pdn_grid -name {grid} -voltage_domains {CORE}

# Standard cell power rails
add_pdn_stripe -grid {grid} -layer {met1} -width {0.48} -pitch {2.72} -offset {0} -followpins

# Power straps
add_pdn_stripe -grid {grid} -layer {met4} -width {1.6} -pitch {40.0} -offset {13.570}
add_pdn_stripe -grid {grid} -layer {met5} -width {1.6} -pitch {40.0} -offset {13.600}

# Power ring
add_pdn_ring -grid {grid} -layers {met4 met5} -widths {5.0 5.0} -spacings {2.0 2.0} -core_offsets {5.0 5.0}

# Connections
add_pdn_connect -grid {grid} -layers {met1 met4}
add_pdn_connect -grid {grid} -layers {met4 met5}

puts "Generating PDN..."
pdngen

puts "✓ PDN complete"

# STAGE 5: Placement

puts "Running global placement..."
global_placement -density 0.65

puts "Running detailed placement..."
detailed_placement

check_placement

puts "✓ Placement complete"

# STAGE 6: Clock Tree Synthesis

puts "Reading timing constraints..."
if {[file exists "picosoc_aes.sdc"]} {
    read_sdc picosoc_aes.sdc
} else {
    puts "WARNING: SDC file not found, using default constraints"
    create_clock -name clk -period 25.0 [get_ports {clk}]
}

set_cts_buf_cell sky130_fd_sc_hd__clkbuf_8
set_cts_buf_cell sky130_fd_sc_hd__clkbuf_4  
set_cts_buf_cell sky130_fd_sc_hd__clkbuf_2

puts "Running CTS..."
clock_tree_synthesis

puts "✓ CTS complete"
report_clock_skew

# STAGE 7: Routing

global_route
detailed_route

puts "✓ Detailed routing complete"

# STAGE 9: Finishing

set fillers {
    sky130_fd_sc_hd__fill_8
    sky130_fd_sc_hd__fill_4
    sky130_fd_sc_hd__fill_2
    sky130_fd_sc_hd__fill_1
}

puts "Inserting filler cells..."
filler_placement -cells $fillers

puts "✓ Fillers inserted"

# STAGE 10: Reports & Outputs


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
set GDS_FILES "${PDK_ROOT}/${PDK}/libs.ref/${LIB}/gds/${LIB}.gds"
write_gds -lib_files $GDS_FILES picosoc_aes.gds

# Final statistics
report_design_area


puts " Physical Design Complete!"
