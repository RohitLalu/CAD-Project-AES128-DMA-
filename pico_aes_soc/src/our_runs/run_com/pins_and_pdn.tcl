# #!/usr/bin/env openroad

# # --- Macro Paths ---
# set SRAM_LEF "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com/sky130_sram_1kbyte_1rw1r_32x256_8.lef"
# set SRAM_LIB "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com/sky130_sram_1kbyte_1rw1r_32x256_8_TT_1p8V_25C.lib"
# set AES_LEF  "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com/aes_abstract.lef"
# set AES_LIB  "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com/aes_macro.lib" 

# set PDK_ROOT "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af"
# set PDK "sky130A"
# set LIB "sky130_fd_sc_hd"

# set TECH_LEF "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef"
# set SC_LEF "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef"
# set LIB_FILE "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"

# puts "PicoSoC + AES macro + SRAM macro Flow"

# puts "\n--- Reading design ---"

# puts "\n--- Reading design ---"
# read_lef $TECH_LEF
# read_lef $SC_LEF
# read_lef $SRAM_LEF
# read_lef $AES_LEF

# read_liberty $LIB_FILE
# read_liberty $SRAM_LIB
# read_liberty $AES_LIB

# read_verilog picosoc_syn.v
# link_design picosoc
# puts "✓ Design loaded with Macros"

# read_lef $TECH_LEF
# read_lef $SC_LEF
# read_liberty $LIB_FILE
# read_verilog picosoc_aes_sram.v
# link_design picosoc
# puts "✓ Design loaded"

# puts "\n--- Setting timing constraints ---"
# read_sdc picosoc_aes.sdc

# read_db 2_floorplan.odb

puts "\n--- Pin placement ---"
set west_pins {clk resetn  irq_5 irq_6 irq_7}
set east_pins {iomem_valid iomem_ready ser_rx ser_tx}

set north_pins {}
for {set i 0} {$i < 32} {incr i} {lappend north_pins "iomem_rdata\[$i\]"}
lappend north_pins flash_csb flash_clk flash_io0_di flash_io1_di flash_io2_di flash_io3_di

set south_pins {}
for {set i 0} {$i < 4} {incr i} {lappend south_pins "iomem_wstrb\[$i\]"}
for {set i 0} {$i < 32} {incr i} {lappend south_pins "iomem_addr\[$i\]"}
for {set i 0} {$i < 32} {incr i} {lappend south_pins "iomem_wdata\[$i\]"}
lappend south_pins flash_io0_oe flash_io1_oe flash_io2_oe flash_io3_oe
lappend south_pins flash_io0_do flash_io1_do flash_io2_do flash_io3_do

make_tracks
set_io_pin_constraint -pin_names $west_pins -region left:100-1400
set_io_pin_constraint -pin_names $east_pins -region right:100-1400
set_io_pin_constraint -pin_names $north_pins -region top:100-1400
set_io_pin_constraint -pin_names $south_pins -region bottom:100-1400
place_pins -hor_layers met3 -ver_layers met2

puts "✓ Pins placed (123 total)"
write_db 3_pins.odb

puts "\n--- Power delivery network ---"
add_global_connection -net {VPWR} -inst_pattern {.*} -pin_pattern {^VPB$} -power
add_global_connection -net {VPWR} -inst_pattern {.*} -pin_pattern {^VPWR$} -power
add_global_connection -net {VGND} -inst_pattern {.*} -pin_pattern {^VNB$} -ground
add_global_connection -net {VGND} -inst_pattern {.*} -pin_pattern {^VGND$} -ground
add_global_connection -net {VPWR} -inst_pattern {.*} -pin_pattern {^HI$} -power
add_global_connection -net {VGND} -inst_pattern {.*} -pin_pattern {^LO$} -ground

# Add connections for macro-specific power pins if they differ
add_global_connection -net {VPWR} -inst_pattern {mem.sram_macro|aes} -pin_pattern {^vdd.*$} -power
add_global_connection -net {VGND} -inst_pattern {mem.sram_macro|aes} -pin_pattern {^vss.*$} -ground

set_voltage_domain -power VPWR -ground VGND
define_pdn_grid -name {grid} -voltage_domains {CORE}
add_pdn_stripe -grid {grid} -layer {met1} -width {0.48} -pitch {2.72} -offset {0} -followpins
add_pdn_stripe -grid {grid} -layer {met4} -width {1.6} -pitch {40.0} -offset {13.570}
add_pdn_stripe -grid {grid} -layer {met5} -width {1.6} -pitch {40.0} -offset {13.600}
add_pdn_ring -grid {grid} -layers {met4 met5} -widths {5.0 5.0} -spacings {2.0 2.0} -core_offsets {5.0 5.0}
add_pdn_connect -grid {grid} -layers {met1 met4}
add_pdn_connect -grid {grid} -layers {met4 met5}
pdngen
puts "✓ PDN complete"
write_db 4_pdn.odb