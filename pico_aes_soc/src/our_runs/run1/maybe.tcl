#!/usr/bin/env openroad

# ========================================================================
# ULTRA-FAST Complete Flow - Guaranteed Working Pins
# ========================================================================

set PDK_ROOT "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af"
set PDK "sky130A"
set LIB "sky130_fd_sc_hd"

set TECH_LEF "${PDK_ROOT}/${PDK}/libs.ref/${LIB}/techlef/${LIB}__nom.tlef"
set SC_LEF "${PDK_ROOT}/${PDK}/libs.ref/${LIB}/lef/${LIB}.lef"
set LIB_FILE "${PDK_ROOT}/${PDK}/libs.ref/${LIB}/lib/${LIB}__tt_025C_1v80.lib"

puts "=========================================="
puts "PicoSoC + AES - ULTRA FAST Flow"
puts "Die: 1600×1600 (ensures pins inside)"
puts "Target: <90 minutes completion"
puts "=========================================="

# ========================================================================
# Stage 1: Read Design (1 min)
# ========================================================================

puts "\n--- Reading design ---"
read_lef $TECH_LEF
read_lef $SC_LEF
read_liberty $LIB_FILE
read_verilog picosoc_aes_sram.v
link_design picosoc
puts "✓ Design loaded"

# ========================================================================
# Stage 2: Floorplan (1 min) - LARGER DIE FOR PIN MARGIN
# ========================================================================

puts "\n--- Floorplan ---"
initialize_floorplan \
    -die_area {0 0 1600 1600} \
    -core_area {50 50 1550 1550} \
    -site unithd
report_design_area
puts "✓ Floorplan: 1600×1600 die, 1500×1500 core"

# ========================================================================
# Stage 3: Pin Placement (1 min) - SIMPLE AND WORKING
# ========================================================================

puts "\n--- Pin placement ---"

# Pin lists
set west_pins {clk resetn iomem_ready ser_rx irq_5 irq_6 irq_7}
set east_pins {iomem_valid ser_tx flash_csb flash_clk}

set north_pins {}
for {set i 0} {$i < 32} {incr i} {lappend north_pins "iomem_rdata\[$i\]"}
lappend north_pins flash_io0_di flash_io1_di flash_io2_di flash_io3_di

set south_pins {}
for {set i 0} {$i < 4} {incr i} {lappend south_pins "iomem_wstrb\[$i\]"}
for {set i 0} {$i < 32} {incr i} {lappend south_pins "iomem_addr\[$i\]"}
for {set i 0} {$i < 32} {incr i} {lappend south_pins "iomem_wdata\[$i\]"}
lappend south_pins flash_io0_oe flash_io1_oe flash_io2_oe flash_io3_oe
lappend south_pins flash_io0_do flash_io1_do flash_io2_do flash_io3_do

# Place pins with generous margins
make_tracks
set_io_pin_constraint -pin_names $west_pins -region left:100-1400
set_io_pin_constraint -pin_names $east_pins -region right:100-1400
set_io_pin_constraint -pin_names $north_pins -region top:100-1400
set_io_pin_constraint -pin_names $south_pins -region bottom:100-1400
place_pins -hor_layers met3 -ver_layers met2

puts "✓ Pins placed (123 total)"

# ========================================================================
# Stage 4: PDN (2 min)
# ========================================================================

puts "\n--- Power delivery network ---"
add_global_connection -net {VPWR} -inst_pattern {.*} -pin_pattern {^VPB$} -power
add_global_connection -net {VPWR} -inst_pattern {.*} -pin_pattern {^VPWR$} -power
add_global_connection -net {VGND} -inst_pattern {.*} -pin_pattern {^VNB$} -ground
add_global_connection -net {VGND} -inst_pattern {.*} -pin_pattern {^VGND$} -ground
add_global_connection -net {VPWR} -inst_pattern {.*} -pin_pattern {^HI$} -power
add_global_connection -net {VGND} -inst_pattern {.*} -pin_pattern {^LO$} -ground

set_voltage_domain -power VPWR -ground VGND
define_pdn_grid -name {grid} -voltage_domains {CORE}
add_pdn_stripe -grid {grid} -layer {met1} -width {0.48} -pitch {2.72} -offset {0} -followpins
add_pdn_stripe -grid {grid} -layer {met4} -width {1.6} -pitch {50.0} -offset {13.570}
add_pdn_stripe -grid {grid} -layer {met5} -width {1.6} -pitch {50.0} -offset {13.600}
add_pdn_ring -grid {grid} -layers {met4 met5} -widths {5.0 5.0} -spacings {2.0 2.0} -core_offsets {5.0 5.0}
add_pdn_connect -grid {grid} -layers {met1 met4}
add_pdn_connect -grid {grid} -layers {met4 met5}
pdngen
puts "✓ PDN complete"

# ========================================================================
# Stage 5: Placement (15 min)
# ========================================================================

puts "\n--- Placement ---"

insert_tiecells sky130_fd_sc_hd__conb_1/HI
# -prefix "TIEHI"
insert_tiecells sky130_fd_sc_hd__conb_1/LO
# -prefix "TIELO"

global_placement -density 0.3
set_placement_padding -global -left 0 -right 0
detailed_placement
check_placement -verbose -report_file_name placement_check_faster.rpt
puts "✓ Placement complete"

# ========================================================================
# Stage 6: CTS (7 min)
# ========================================================================

puts "\n--- Clock tree synthesis ---"
create_clock -name clk -period 35.0 [get_ports {clk}]
set_clock_uncertainty 2.5 [get_clocks {clk}]
set_wire_rc -clock -layer met3
set_wire_rc -signal -layer met2
clock_tree_synthesis -buf_list {sky130_fd_sc_hd__clkbuf_8 sky130_fd_sc_hd__clkbuf_4 sky130_fd_sc_hd__clkbuf_2}

set_placement_padding -masters {sky130_fd_sc_hd__clkbuf_*} -left 1 -right 1
detailed_placement

puts "✓ CTS complete"

# ========================================================================
# Stage 7: Routing (30-40 min) - WITH WORKING PINS
# ========================================================================

puts "\n--- Global routing ---"
global_route  -allow_congestion
puts "✓ Global routing complete"

puts "\n--- Detailed routing (this will work now!) ---"
puts "Expected time: 30-40 minutes"
detailed_route \
    -output_drc route_drc.rpt \
    -droute_end_iter 10 \
    -bottom_routing_layer met1 \
    -top_routing_layer met5

puts "\n✓ Routing complete!"

# ========================================================================
# Stage 8: Finishing (2 min)
# ========================================================================

puts "\n--- Filler cells ---"
filler_placement -cells {
    sky130_fd_sc_hd__fill_8
    sky130_fd_sc_hd__fill_4
    sky130_fd_sc_hd__fill_2
    sky130_fd_sc_hd__fill_1
}
puts "✓ Fillers inserted"

# ========================================================================
# Stage 9: Output (2 min)
# ========================================================================

puts "\n--- Generating outputs ---"
write_def picosoc_aes_final.def

set GDS_FILES "${PDK_ROOT}/${PDK}/libs.ref/${LIB}/gds/${LIB}.gds"
write_gds -lib_files $GDS_FILES picosoc_aes_final.gds

puts "\n=========================================="
puts "🎉 COMPLETE!"
puts "=========================================="
puts "Die: 1600µm × 1600µm = 2.56 mm²"
puts "Outputs:"
puts "  📄 picosoc_aes_final.gds"
puts "  📄 picosoc_aes_final.def"
puts "  📄 route_drc.rpt"
puts "=========================================="