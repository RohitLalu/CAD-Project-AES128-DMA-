#!/usr/bin/env openroad

set_thread_count 7

set PDK_ROOT "/Users/hello.welcometothisdevice/.ciel/ciel/sky130/versions/0fe599b2afb6708d281543108caf8310912f54af"
set RUNDIR   "/Users/hello.welcometothisdevice/CAD-Project-AES128-DMA-/pico_aes_soc/src/our_runs/run_com2"

set TECH_LEF "$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef"
set SC_LEF   "$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef"
set LIB_FILE "$PDK_ROOT/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"
set SRAM_LEF "$RUNDIR/sky130_sram_1kbyte_1rw1r_32x256_8.lef"
set SRAM_LIB "$RUNDIR/sky130_sram_1kbyte_1rw1r_32x256_8_TT_1p8V_25C.lib"
set AES_LEF  "$RUNDIR/aes_abstract.lef"
set AES_LIB  "$RUNDIR/aes_macro.lib"

puts "================================================================"
puts "  PicoSoC + AES + SRAM  —  Floorplan + Pins + PDN"
puts "================================================================"

# 1. Read LEFs

puts "\n--- 1. Reading LEFs ---"
read_lef $TECH_LEF
read_lef $SC_LEF
read_lef $SRAM_LEF
read_lef $AES_LEF
puts "✓ LEFs loaded"

# 2. Read Liberty and netlist

puts "\n--- 2. Reading Liberty ---"
read_liberty $LIB_FILE
read_liberty $SRAM_LIB
read_liberty $AES_LIB
puts "✓ Liberty loaded"

puts "\n--- 3. Reading netlist ---"
read_verilog $RUNDIR/picosoc_syn.v
link_design picosoc
puts "✓ Design linked"

# 4. SDC

puts "\n--- 4. Reading SDC ---"
read_sdc $RUNDIR/picosoc_aes.sdc
puts "✓ SDC loaded"

# 5. Floorplan initialisation

puts "\n--- 5. Floorplan ---"
initialize_floorplan \
    -die_area  {0 0 1900 1200} \
    -core_area {25 25 1875 1175} \
    -site unithd

report_design_area
puts "✓ Floorplan: 1900×1200 µm die, 1850×1150 µm core"

puts "\n--- 6. Macro placement ---"
set_macro_extension 10

place_macro \
    -macro_name {memory.sram_macro} \
    -location   {150 250} \
    -orient     R180
    #-location {320 400}
puts "✓ SRAM placed "

place_macro -macro_name aes_inst \
    -location {900 100} \
    -orient R0
puts "✓ AES  placed"

set block [ord::get_db_block]

set sram_blk [odb::dbBlockage_create $block \
    [ord::microns_to_dbu 75]  \
    [ord::microns_to_dbu 125]  \
    [ord::microns_to_dbu 740]  \
    [ord::microns_to_dbu 800]]
$sram_blk setSoft

# AES:
set aes_blk [odb::dbBlockage_create $block \
    [ord::microns_to_dbu 750] \
    [ord::microns_to_dbu 20]  \
    [ord::microns_to_dbu 1820] \
    [ord::microns_to_dbu 1020]]
$aes_blk setSoft

# --- 8. Tap cells (AFTER blockages, so halo_width respects blockage edges) ---
puts "\n--- 8. Tap cells ---"
tapcell \
    -tapcell_master  sky130_fd_sc_hd__tapvpwrvgnd_1 \
    -endcap_master   sky130_fd_sc_hd__decap_3 \
    -distance        14 \
    -halo_width_x    15 \
    -halo_width_y    15
puts "✓ Tap cells inserted"

# 9. Routing tracks  ← before place_pins

puts "\n--- 9. Routing tracks ---"
make_tracks
puts "✓ Tracks created"

puts "\n--- 10. Pin placement ---"
set north_pins {irq_5 irq_6 irq_7 flash_csb flash_clk flash_io0_di flash_io1_di flash_io2_di flash_io3_di}
set east_pins  {ser_rx ser_tx}

set west_pins {}
lappend west_pins iomem_valid
lappend west_pins iomem_ready
for {set i 0} {$i < 32} {incr i} { lappend west_pins "iomem_rdata\[$i\]" }
for {set i 0} {$i < 32} {incr i} { lappend west_pins "iomem_addr\[$i\]"  }
for {set i 0} {$i < 32} {incr i} { lappend west_pins "iomem_wdata\[$i\]" }

set south_pins {}
for {set i 0} {$i < 4}  {incr i} { lappend south_pins "iomem_wstrb\[$i\]" }
lappend south_pins flash_io0_oe flash_io1_oe flash_io2_oe flash_io3_oe
lappend south_pins flash_io0_do flash_io1_do flash_io2_do flash_io3_do
lappend south_pins clk resetn

set_io_pin_constraint -pin_names $east_pins  -region right:50-1150
set_io_pin_constraint -pin_names $west_pins  -region left:50-1150
set_io_pin_constraint -pin_names $north_pins -region top:50-1750
set_io_pin_constraint -pin_names $south_pins -region bottom:50-1750

place_pins -hor_layers met5 -ver_layers met4
puts "✓ Pins placed (123 total)"

puts "\n--- 11. Power delivery network ---"

add_global_connection -net {VPWR} -inst_pattern {.*} -pin_pattern {^VPWR$} -power
add_global_connection -net {VPWR} -inst_pattern {.*} -pin_pattern {^VPB$}  -power
add_global_connection -net {VPWR} -inst_pattern {.*} -pin_pattern {^HI$}   -power
add_global_connection -net {VGND} -inst_pattern {.*} -pin_pattern {^VGND$} -ground
add_global_connection -net {VGND} -inst_pattern {.*} -pin_pattern {^VNB$}  -ground
add_global_connection -net {VGND} -inst_pattern {.*} -pin_pattern {^LO$}   -ground

add_global_connection -net {VPWR} \
    -inst_pattern {memory\.sram_macro} -pin_pattern {^vccd1$} -power
add_global_connection -net {VGND} \
    -inst_pattern {memory\.sram_macro} -pin_pattern {^vssd1$} -ground

set_voltage_domain -power VPWR -ground VGND

define_pdn_grid \
    -name            {core_grid} \
    -voltage_domains {CORE}

# met1 followpins — MUST stay: supplies VDD/VSS to every std-cell row
add_pdn_stripe -grid {core_grid} -layer {met1} \
    -width {0.48} -pitch {2.72} -offset {0} -followpins

# met4 vertical stripes — widened pitch to reduce via-stack blockage on met1/met3
add_pdn_stripe -grid {core_grid} -layer {met4} \
    -width {1.6} -pitch {80.0} -offset {2.0}

# met5 horizontal stripes
add_pdn_stripe -grid {core_grid} -layer {met5} \
    -width {1.6} -pitch {80.0} -offset {2.0}

add_pdn_ring -grid {core_grid} \
    -layers         {met4 met5} \
    -widths         {8.0 8.0}   \
    -spacings       {2.0 2.0}   \
    -core_offsets   {5.0 5.0}   \
    -starts_with    POWER

add_pdn_connect -grid {core_grid} -layers {met1 met4}
add_pdn_connect -grid {core_grid} -layers {met4 met5}

pdngen
puts "✓ PDN complete"
 
#write_db $RUNDIR/4_pdn.odb
puts "✓ Checkpoint: 4_pdn.odb"

puts "\nFloorplan + Pins + PDN complete."